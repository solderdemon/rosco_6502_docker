IMAGE ?= rosco-6502-toolchain:local
PLATFORM ?= linux/amd64
PROJECT ?= $(CURDIR)

.PHONY: image shell smoke test

image:
	docker build --platform "$(PLATFORM)" --tag "$(IMAGE)" .

shell: image
	docker run --rm --interactive --tty \
		--env HOME=/tmp \
		--user "$$(id -u):$$(id -g)" \
		--volume "$(PROJECT):/workspace" \
		--workdir /workspace \
		"$(IMAGE)"

smoke: image
	docker run --rm "$(IMAGE)" sh -c \
		'command -v ca65 && command -v ld65 && command -v da65 && \
		 command -v cl65 && command -v cc65 && command -v ar65 && \
		 command -v vasm6502_oldstyle && command -v vasm6502_std && \
		 command -v vlink && command -v srec_cat && command -v make'

# Assembles and links a small source that uses the ca65 and vasm features the
# rosco_6502 sources depend on.
test: image
	docker run --rm \
		--env HOME=/tmp \
		--user "$$(id -u):$$(id -g)" \
		--volume "$(CURDIR)/test:/workspace" \
		--workdir /workspace \
		"$(IMAGE)" make clean all
