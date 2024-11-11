.PHONY: all clean lint generate buf-update check help format build init install-buf breaking

all: install-buf format lint generate

PROTO_DIR := proto
GEN_DIR := gen
BUF := $(shell command -v buf 2> /dev/null)
BUF_VERSION := v1.46.0
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)
BUF_GEN_FILE := buf.gen.yaml

ifeq ($(UNAME_S),Linux)
    OS := linux
else ifeq ($(UNAME_S),Darwin)
    OS := darwin
else
    OS := windows
endif

ifeq ($(UNAME_M),x86_64)
    ARCH := x86_64
else ifeq ($(UNAME_M),amd64)
    ARCH := x86_64
else ifeq ($(UNAME_M),arm64)
    ARCH := arm64
else
    ARCH := x86_64
endif

$(shell mkdir -p $(GEN_DIR))

install-buf:
ifndef BUF
	@echo "Installing buf $(BUF_VERSION)..."
	@curl -sSL \
		"https://github.com/bufbuild/buf/releases/download/$(BUF_VERSION)/buf-$(OS)-$(ARCH)" \
		-o "/usr/local/bin/buf"
	@chmod +x "/usr/local/bin/buf"
	@echo "buf installed successfully"
else
	@echo "buf is already installed at $(BUF)"
endif

generate: install-buf
	@if [ -f "$(BUF_GEN_FILE)" ]; then \
		echo "Generating code from protos..."; \
		$(BUF) generate; \
	else \
		echo "Skipping generate: $(BUF_GEN_FILE) not found"; \
	fi

lint: install-buf
	$(BUF) lint

breaking: install-buf
	$(BUF) breaking --against '.git#branch=main'

buf-update: install-buf
	$(BUF) dep update

clean:
	rm -rf $(GEN_DIR)

format: install-buf
	$(BUF) format -w

build: install-buf
	$(BUF) build

init: install-buf
	$(BUF) config init

check: build format lint breaking

help:
	@echo "Available targets:"
	@echo "  generate    : Generate code from proto files"
	@echo "  lint        : Lint proto files and check breaking changes"
	@echo "  breaking    : Check breaking changes"
	@echo "  buf-update  : Update buf dependencies"
	@echo "  clean       : Remove generated files"
	@echo "  format      : Format proto files"
	@echo "  build       : Build proto files"
	@echo "  init        : Initialize a new buf project"
	@echo "  check       : Run all checks (lint, format, build)"
	@echo "  install-buf : Install buf if not already installed"
	@echo "  help        : Show this help message"
