#!/bin/bash

export ROOTPATH="$PWD"
export GOPATH="$ROOTPATH/stemcell-builder"
export PATH="$PATH:$GOPATH/bin"

if [ -z "$GOPATH" ]; then
	echo "GOPATH not set"
	exit 1
fi

# Install ginkgo if it does not exist
if ! which ginkgo 2>&1 > /dev/null; then
	pushd "$PWD/vendor/github.com/onsi/ginkgo/ginkgo"
	if [ ! -d "$GOPATH/bin"]; then
		mkdir "$GOPATH/bin"
	fi
	go build -o "$GOPATH/bin/ginkgo"
	popd
fi

if ! which ginkgo 2>&1 > /dev/null; then
	echo "Install failed to find ginkgo on PATH"
	exit 1
fi

ginkgo -r -v "$GOPATH/src/github.com/cloudfoundry-incubator/windows-utilities-tests"
GINKGO_EXIT=$?

# Kill any ssh tunnels left by our IAAS specific setup
TUNNEL_PID=$(ps -C ssh -o pid=)
if [ -n "$TUNNEL_PID" ]; then
	kill -2 $TUNNEL_PID
fi

exit $GINKGO_EXIT
