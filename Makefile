ENGINE ?= podman

ENV ?= test-debian10-glibc228

IMAGE_NAME := localhost/$(ENV):latest
CONTAINER_NAME := $(ENV)

USERNAME ?= builder

UID := $(shell id -u)
GID := $(shell id -g)

CONTAINER_HOME := /home/$(USERNAME)

CODE_DIR ?=
QT_DIR ?=
CCACHE_DIR ?= $(HOME)/.ccache

.PHONY: build run start stop clean

build:
	$(ENGINE) build \
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
		--env CCACHE_DIR=$(CONTAINER_HOME)/.ccache \
		-v $(CODE_DIR):$(CONTAINER_HOME)/code:Z \
		-v $(QT_DIR):$(CONTAINER_HOME)/Qt:ro,Z \
		-v $(CCACHE_DIR):$(CONTAINER_HOME)/.ccache:Z \
		-w $(CONTAINER_HOME)/code \
		$(IMAGE_NAME) \
		bash

start:
	$(ENGINE) start -ai $(CONTAINER_NAME)

stop:
	$(ENGINE) stop $(CONTAINER_NAME)

clean:
	-$(ENGINE) rm -f $(CONTAINER_NAME)
