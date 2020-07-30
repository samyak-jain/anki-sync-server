#!/bin/bash
# file: init.sh
# description: Download dependencies based on environment.

git submodule update --init --recursive

case "${ENV}" in
	ci) pip install -r src/requirements-dev.txt ;;
	local) poetry install ;;
	*) echo "Unknown environment: ${ENV}" ;;
esac