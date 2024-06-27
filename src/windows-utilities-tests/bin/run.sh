#!/bin/bash
set -eu -o pipefail

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

function cleanup_ssh_tunnels() {
  echo "Killing any ssh tunnels left by our IAAS specific setup..."
  set -x
  TUNNEL_PID=$(ps -C ssh -o pid=)
  if [ -n "${TUNNEL_PID}" ]; then
    kill -2 "${TUNNEL_PID}"
  fi
}
trap cleanup_ssh_tunnels RETURN

(
  set -eu -o pipefail
  cd "${ROOT_DIR}"

  go run -mod=mod github.com/onsi/ginkgo/ginkgo run -r -v .
)
