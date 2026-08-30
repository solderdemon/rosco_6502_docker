# syntax=docker/dockerfile:1

ARG UBUNTU_IMAGE=ubuntu:24.04@sha256:4fbb8e6a8395de5a7550b33509421a2bafbc0aab6c06ba2cef9ebffbc7092d90

FROM ${UBUNTU_IMAGE} AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# cc65 is pinned to the last commit before "C style character translation in
# ca65" (1b85ab698).  That change rejects the `lda #'\'` character constants
# used by the rosco_6502 firmware when `--feature string_escapes` is active,
# while releases older than this commit lack features the firmware needs.
#
# vasm and vlink are only published upstream as rolling tarballs, so they
# cannot be pinned to a revision here.  Use a published image digest when
# byte-for-byte repeatability is required.
ENV CC65_REPO=https://github.com/cc65/cc65.git \
    CC65_REF=75d43ef88e3780696158545bb0baf25bbec16147 \
    VASM_URL=http://sun.hasenbraten.de/vasm/release/vasm.tar.gz \
    VLINK_URL=http://sun.hasenbraten.de/vlink/release/vlink.tar.gz \
    STAGE=/opt/stage

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
    && rm -rf /var/lib/apt/lists/*

# cc65: ca65, ld65, da65, cl65, cc65 and the 6502 target libraries.
# The tools build in parallel; libsrc is built serially because concurrent
# ar65 invocations race over their temporary library files.
RUN git clone "${CC65_REPO}" /tmp/cc65 \
    && git -C /tmp/cc65 checkout --detach "${CC65_REF}" \
    && make -C /tmp/cc65/src -j "$(nproc)" \
    && make -C /tmp/cc65/libsrc \
    && make -C /tmp/cc65 install PREFIX=/usr/local DESTDIR="${STAGE}" \
    && rm -rf /tmp/cc65

# vasm: the 6502 backend in both oldstyle and std syntax, plus vobjdump.
RUN mkdir -p /tmp/vasm \
    && curl -fsSL "${VASM_URL}" | tar -xz -C /tmp/vasm --strip-components=1 \
    && make -C /tmp/vasm CPU=6502 SYNTAX=oldstyle \
    && make -C /tmp/vasm CPU=6502 SYNTAX=std \
    && install -D -m 0755 /tmp/vasm/vasm6502_oldstyle "${STAGE}/usr/local/bin/vasm6502_oldstyle" \
    && install -D -m 0755 /tmp/vasm/vasm6502_std "${STAGE}/usr/local/bin/vasm6502_std" \
    && install -D -m 0755 /tmp/vasm/vobjdump "${STAGE}/usr/local/bin/vobjdump" \
    && rm -rf /tmp/vasm

# vlink: the linker used by the vasm-based firmware and software builds.
RUN mkdir -p /tmp/vlink \
    && curl -fsSL "${VLINK_URL}" | tar -xz -C /tmp/vlink --strip-components=1 \
    && make -C /tmp/vlink \
    && install -D -m 0755 /tmp/vlink/vlink "${STAGE}/usr/local/bin/vlink" \
    && rm -rf /tmp/vlink


FROM ${UBUNTU_IMAGE}

LABEL org.opencontainers.image.source="https://github.com/solderdemon/rosco_6502_docker" \
      org.opencontainers.image.description="Development image for the rosco_6502 toolchain" \
      org.opencontainers.image.licenses="MIT"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        python3 \
        srecord \
        xxd \
        zsh \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python3 /usr/local/bin/python

COPY --from=builder /opt/stage/usr/local /usr/local

# The cc65 tools find their include, asminc and lib directories relative to
# this prefix, so the build has to install to the same place it runs from.
ENV CC65_HOME=/usr/local/share/cc65

RUN command -v ca65 \
    && command -v ld65 \
    && command -v da65 \
    && command -v cl65 \
    && command -v cc65 \
    && command -v vasm6502_oldstyle \
    && command -v vlink \
    && command -v srec_cat \
    && ca65 --version \
    && vlink -v | head -1 \
    && (vasm6502_oldstyle -h 2>&1 || true) | grep -m1 '^vasm '

WORKDIR /workspace

CMD ["/bin/zsh", "-f"]
