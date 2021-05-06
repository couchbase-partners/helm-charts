#!/bin/bash
set -eux
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
docker run --rm --volume "${SCRIPT_DIR}:/helm-docs" -u "$(id -u)" jnorwood/helm-docs:v1.5.0 --dry-run
