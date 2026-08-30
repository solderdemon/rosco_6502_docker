# rosco_6502 Docker image

A Docker development image containing the toolchain used by the
[rosco_6502](https://github.com/rosco-m68k/rosco_6502): the cc65 suite
(`ca65`, `ld65`, `da65`), vasm with the 6502 backend, vlink and srecord. It
provides the same Linux build environment for local development and CI without
installing the 6502 toolchain on the host.

The published image currently targets `linux/amd64`. Docker Desktop can run it
through emulation on ARM hosts by passing `--platform linux/amd64`.

## Included tools

- `ca65`, `ld65`, `da65`, `cc65`, `cl65`, `ar65`, `od65`, `sp65`, `sim65`: the
  cc65 6502 toolchain, with the 6502 target libraries and `asminc` macro
  packages (`generic`, `longbranch`, …)
- `vasm6502_oldstyle` and `vasm6502_std`: vasm with the 6502 backend, plus
  `vobjdump`
- `vlink`
- `srecord` (`srec_cat`)
- Python 3, Git, Make and the standard C/C++ build tools

The firmware and the `*_ca65` software directories are built with cc65; the
`firstboot` firmware and the older software directories are built with
vasm/vlink. Both paths are present in the image.

`minipro` is not included: burning a ROM needs USB access to the programmer,
so run `make burn8`/`make burn32` on the host.

## Pull the published image

```shell
docker pull solderdemon/rosco_6502:latest
```

For reproducible builds, use a versioned tag or image digest instead of
`latest`:

```shell
docker pull solderdemon/rosco_6502@sha256:<digest>
```

## Build a project

Run the following command from the directory of a project that uses the
toolchain, for example `code/firmware/rosco_6502`:

```shell
docker run --rm \
  --user "$(id -u):$(id -g)" \
  --env HOME=/tmp \
  --volume "$PWD:/workspace" \
  --workdir /workspace \
  solderdemon/rosco_6502:latest \
  make
```

Using the host UID and GID keeps generated files owned by the current user.

Several project Makefiles reference paths outside their own directory (for
example `../../firmware/rosco_6502/inc`), so mount the repository root and
select the directory with `--workdir`:

```shell
docker run --rm \
  --user "$(id -u):$(id -g)" \
  --env HOME=/tmp \
  --volume "$PWD:/workspace" \
  --workdir /workspace/code/firmware/rosco_6502 \
  solderdemon/rosco_6502:latest \
  make
```

On an ARM host, add this option:

```shell
--platform linux/amd64
```

## Open an interactive shell

```shell
docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  --env HOME=/tmp \
  --volume "$PWD:/workspace" \
  --workdir /workspace \
  solderdemon/rosco_6502:latest
```

The image defaults to zsh with startup files disabled. Override the command
with `/bin/bash` if preferred.

## Build and test the image locally

This repository includes convenience Make targets:

```shell
make image
make smoke
make test
make shell
```

`make test` assembles and links `test/`, a small source that uses the ca65 and
vasm features the rosco_6502 sources depend on. `make shell` opens a shell in
this repository; point it at a checkout of the rosco_6502 sources with:

```shell
make shell PROJECT=/path/to/rosco_6502
```

Override the local image name or target platform when necessary:

```shell
make image IMAGE=my-toolchain:dev PLATFORM=linux/amd64
```

## Toolchain versions

cc65 is built from a pinned commit,
`75d43ef88e3780696158545bb0baf25bbec16147`, which is the last one before
"C style character translation in ca65". That change makes ca65 reject the
`lda #'\'` character constants in the firmware sources when
`--feature string_escapes` is enabled, and cc65 2.19 is too old for those same
sources (its `generic` macro package predates other features they use). Update
the pin only after checking that the firmware still assembles.

vasm and vlink are only published upstream as rolling tarballs and are
therefore not pinned; likewise, packages from the Ubuntu archive are resolved
when the image is built. Use a published image digest when byte-for-byte
repeatability is required. Dependency updates are verified by the smoke-test
job.

## CI and publishing

GitHub Actions builds and smoke-tests every pull request. Pushes to `main` and
tags matching `v*` are published after the test job succeeds.

Publishing requires these repository secrets:

- `DOCKER_USERNAME`
- `DOCKER_TOKEN` (a Docker Hub access token with read and write permissions)

Set the optional repository variable `DOCKER_IMAGE` to publish to a different
Docker Hub repository. Its default is `solderdemon/rosco_6502`.

The workflow publishes:

- `latest` from the default branch
- the Git tag for tagged releases, for example `v1.0.0`
- a commit tag in the form `sha-<short-sha>`

Published images include BuildKit provenance and an SBOM.

## License

The Dockerfile and build configuration are licensed under the MIT License.
Software installed in the image remains covered by its respective licenses.
