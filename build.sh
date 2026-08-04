#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

source env/bin/activate

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH="$JAVA_HOME/bin:$PATH"

buildozer android debug
