#!/usr/bin/env bash
# Captures a real rendered 1179x2556 (no device frame) screenshot of actual
# Sporewick gameplay for the store listing, the same way
# run_headless_verify.sh captures verification screenshots — genuine
# rendered output under software OpenGL, not a mockup.
#
# Usage: tools/capture_store_screenshot.sh <project_dir> [outdir]
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-/opt/godot/Godot_v4.3-stable_linux.x86_64}"
PROJECT_DIR="$(cd "$1" && pwd)"
OUTDIR="${2:-${PROJECT_DIR}/store_listing}"
case "${OUTDIR}" in
	/*) ;;
	*) OUTDIR="$(pwd)/${OUTDIR}" ;;
esac
DISPLAY_NUM=":98"

if [ ! -x "${GODOT_BIN}" ]; then
	echo "Godot binary not found at ${GODOT_BIN}. Run tools/setup_env.sh first." >&2
	exit 1
fi

# Same reimport step run_headless_verify.sh needs, and for the same reason:
# the imported-texture cache is gitignored and absent on a fresh checkout.
"${GODOT_BIN}" --headless --path "${PROJECT_DIR}" --import >/dev/null 2>&1 || true

# Screen must be at least as large as the capture resolution.
Xvfb "${DISPLAY_NUM}" -screen 0 1179x2556x24 &
XVFB_PID=$!
trap 'kill "${XVFB_PID}" 2>/dev/null || true' EXIT
sleep 1

DISPLAY="${DISPLAY_NUM}" LIBGL_ALWAYS_SOFTWARE=1 "${GODOT_BIN}" \
	--path "${PROJECT_DIR}" \
	--rendering-driver opengl3 \
	--display-driver x11 \
	-- --store-screenshot "--outdir=${OUTDIR}"
