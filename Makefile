ENGINE ?= podman

SUPPORTED_ENVS := \
	debian10-glibc228-x64 \
	debian12-glibc236-arm64

ENV :=

ifeq ($(findstring arm64,$(ENV)),arm64)
PLATFORM := linux/arm64
else
PLATFORM := linux/amd64
endif

ifeq ($(ENV),)
$(error ENV is required. Supported ENV: $(SUPPORTED_ENVS))
endif

ifeq ($(filter $(ENV),$(SUPPORTED_ENVS)),)
$(error Unsupported ENV '$(ENV)'. Supported ENV: $(SUPPORTED_ENVS))
endif

IMAGE_NAME := localhost/$(ENV):latest
CONTAINER_NAME := $(ENV)

USERNAME ?= builder

UID := $(shell id -u)
GID := $(shell id -g)

CONTAINER_HOME := /home/$(USERNAME)

CODE_DIR ?=
QT_DIR ?=

.PHONY: build run start stop clean purge

build:
	$(ENGINE) build \
		--platform $(PLATFORM) \
		--build-arg USERNAME=$(USERNAME) \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		-t $(IMAGE_NAME) \
		-f $(ENV)/Containerfile \
		$(ENV)

run:
	@test -n "$(CODE_DIR)" || (echo "ERROR: CODE_DIR is required"; exit 1)
	@test -n "$(QT_DIR)" || (echo "ERROR: QT_DIR is required"; exit 1)
	$(ENGINE) run -it \
		--name $(CONTAINER_NAME) \
		--userns=keep-id \
		--user $(UID):$(GID) \
		--env HOME=$(CONTAINER_HOME) \
		--env TERM=xterm-256color \
		--env CLICOLOR_FORCE=1 \
		--env FORCE_COLOR=1 \
		-v $(CODE_DIR):$(CONTAINER_HOME)/code:Z \
		-v $(QT_DIR):$(CONTAINER_HOME)/Qt:ro,Z \
		-w $(CONTAINER_HOME)/code \
		$(IMAGE_NAME) \
		bash

root:
	$(ENGINE) exec -it \
		--user root \
		--env TERM=xterm-256color \
		--env CLICOLOR_FORCE=1 \
		--env FORCE_COLOR=1 \
		-w $(CONTAINER_HOME)/code \
		$(CONTAINER_NAME) \
		bash

start:
	$(ENGINE) start -ai $(CONTAINER_NAME)

stop:
	$(ENGINE) stop $(CONTAINER_NAME)

clean:
	-$(ENGINE) rm -f $(CONTAINER_NAME)

purge:
	-$(ENGINE) rmi -f $(IMAGE_NAME)
