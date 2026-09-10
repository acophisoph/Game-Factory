#!/usr/bin/env bash
# Runs a Godot project's built-in autopilot (triggered by --verify) under
# Xvfb with software OpenGL, so the game's own render output can be
# captured to real PNG screenshots instead of just trusting a description.
#
# Usage: tools/run_headless_verify.sh <project_dir> [outdir]
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-/opt/godot/Godot_v4.3-stable_linux.x86_64}"
# Resolve to absolute paths: Godot resolves a relative --outdir against the
# project root (res://), not the caller's cwd, so a relative PROJECT_DIR
# here silently doubles up into <project>/<project>/verification_output.
PROJECT_DIR="$(cd "$1" && pwd)"
OUTDIR="${2:-${PROJECT_DIR}/verification_output}"
case "${OUTDIR}" in
	/*) ;;
	*) OUTDIR="$(pwd)/${OUTDIR}" ;;
esac
DISPLAY_NUM=":99"

if [ ! -x "${GODOT_BIN}" ]; then
	echo "Godot binary not found at ${GODOT_BIN}. Run tools/setup_env.sh first." >&2
	exit 1
fi

Xvfb "${DISPLAY_NUM}" -screen 0 1280x800x24 &
XVFB_PID=$!
trap 'kill "${XVFB_PID}" 2>/dev/null || true' EXIT
sleep 1

DISPLAY="${DISPLAY_NUM}" LIBGL_ALWAYS_SOFTWARE=1 "${GODOT_BIN}" \
	--path "${PROJECT_DIR}" \
	--rendering-driver opengl3 \
	--display-driver x11 \
	-- --verify "--outdir=${OUTDIR}"
