# https://tech.davis-hansson.com/p/make/
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# ANSI color codes
GREEN=$(shell tput -Txterm setaf 2)
YELLOW=$(shell tput -Txterm setaf 3)
RED=$(shell tput -Txterm setaf 1)
BLUE=$(shell tput -Txterm setaf 6)
RESET=$(shell tput -Txterm sgr0)

.DEFAULT_GOAL := help

check_script := scripts/check.bash

.PHONY: help
help:
	@printf '%s\n' 'targets:'
	@awk '/^\.PHONY: / {print "  " $$2}' $(MAKEFILE_LIST)

.PHONY: format
format: format/shell format/caddy format/yaml format/markdown

.PHONY: format/shell
format/shell:
	$(check_script) format/shell

.PHONY: format/caddy
format/caddy:
	$(check_script) format/caddy

.PHONY: format/yaml
format/yaml:
	$(check_script) format/yaml

.PHONY: format/markdown
format/markdown:
	$(check_script) format/markdown

.PHONY: format/check
format/check: format/check/shell format/check/caddy format/check/yaml format/check/markdown format/check/whitespace

.PHONY: format/check/shell
format/check/shell:
	$(check_script) format/check/shell

.PHONY: format/check/caddy
format/check/caddy:
	$(check_script) format/check/caddy

.PHONY: format/check/yaml
format/check/yaml:
	$(check_script) format/check/yaml

.PHONY: format/check/markdown
format/check/markdown:
	$(check_script) format/check/markdown

.PHONY: format/check/whitespace
format/check/whitespace:
	$(check_script) format/check/whitespace

.PHONY: lint
lint: lint/shell lint/yaml lint/markdown

.PHONY: lint/shell
lint/shell:
	$(check_script) lint/shell

.PHONY: lint/yaml
lint/yaml:
	$(check_script) lint/yaml

.PHONY: lint/markdown
lint/markdown:
	$(check_script) lint/markdown

.PHONY: validate
validate: validate/stow validate/compose validate/caddy

.PHONY: validate/stow
validate/stow:
	$(check_script) validate/stow

.PHONY: validate/compose
validate/compose:
	$(check_script) validate/compose

.PHONY: validate/caddy
validate/caddy:
	$(check_script) validate/caddy

.PHONY: check
check: format/check lint validate
