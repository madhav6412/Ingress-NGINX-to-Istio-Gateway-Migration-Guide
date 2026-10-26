SHELL := /bin/bash
.DEFAULT_GOAL := up

.PHONY: up validate down

up:
	@bash scripts/setup-kind.sh
	@bash scripts/install-ingress-nginx.sh
	@bash scripts/install-istio.sh
	@bash scripts/deploy-workloads.sh
	@echo "Migration environment provisioned successfully."

validate:
	@bash tests/validate.sh

down:
	@bash scripts/cleanup.sh
