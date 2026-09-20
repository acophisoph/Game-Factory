#!/usr/bin/env bash
# Provisions the sandbox for Godot 4 headless verification.
# The container is ephemeral, so every run must re-provision before
# building/testing a Godot game. Safe to re-run (idempotent).
set -euo pipefail

GODOT_VERSION="4.3-stable"
GODOT_DIR="/opt/godot"
GODOT_BIN="${GODOT_DIR}/Godot_v${GODOT_VERSION}_linux.x86_64"

if [ ! -f "${GODOT_BIN}" ]; then
	echo "Downloading Godot ${GODOT_VERSION}..."
	mkdir -p "${GODOT_DIR}"
	curl -sSL -o /tmp/godot.zip \
		"https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
	unzip -o -q /tmp/godot.zip -d "${GODOT_DIR}"
	chmod +x "${GODOT_BIN}"
	rm -f /tmp/godot.zip
fi

if ! command -v Xvfb >/dev/null 2>&1; then
	echo "Installing Xvfb + Mesa software rendering..."
	apt-get update -qq
	apt-get install -y -qq xvfb libgl1-mesa-dri libglx-mesa0 >/dev/null
fi

if ! command -v rsvg-convert >/dev/null 2>&1; then
	echo "Installing librsvg2-bin (SVG rasterization for asset generation)..."
	apt-get update -qq
	apt-get install -y -qq librsvg2-bin >/dev/null
fi

echo "Godot ready: ${GODOT_BIN}"
echo "export GODOT_BIN=${GODOT_BIN}"
