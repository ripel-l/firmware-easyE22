#!/usr/bin/env bash
set -euo pipefail

# Define vars
GITHUB_ACTIONS=${GITHUB_ACTIONS:-false}
XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}

# Inputs
MT_TARGET=${MT_TARGET:-"build"}
MT_ENV=${MT_ENV}
MT_PLATFORM=${MT_PLATFORM}
MT_VERBOSE=${MT_VERBOSE:-0}
PIO_TOKEN=${PIO_TOKEN:-}

# PlatformIO settings
export PLATFORMIO_SETTING_ENABLE_TELEMETRY=0
export PLATFORMIO_SETTING_CHECK_PLATFORMIO_INTERVAL=3650
export PLATFORMIO_SETTING_CHECK_PRUNE_SYSTEM_THRESHOLD=10240

# Use PlatformIO Token if provided.
if [[ -n "${PIO_TOKEN}" ]]; then
    export PLATFORMIO_AUTH_TOKEN="${PIO_TOKEN}"
fi
# Conditionally enable verbose output.
if [[ "${MT_VERBOSE}" == "1" ]]; then
    export PLATFORMIO_SETTING_FORCE_VERBOSE=1
fi

# Massage platform values to build_script names
if [[ "$MT_PLATFORM" == esp32* ]]; then
    MT_PLATFORM="esp32"
elif [[ "$MT_PLATFORM" == nrf52* ]]; then
    MT_PLATFORM="nrf52"
elif [[ "$MT_PLATFORM" == rp2040 ]] || [[ "$MT_PLATFORM" == rp2350 ]]; then
    MT_PLATFORM="rp2xx0"
elif [[ "$MT_PLATFORM" == stm32 ]]; then
    # Remove when stm32 has been fully renamed to stm32wl
    MT_PLATFORM="stm32wl"
fi

# ESP32 / pioarduino compatibility workaround:
# platform-espressif32 creates a nested PlatformIO environment in
# $PLATFORMIO_CORE_DIR/penv. Pin that nested core to 6.1.19 so it
# stays compatible with tool-scons 4.8.1 used by platform 55.03.311.
if [[ "$MT_PLATFORM" == "esp32" ]]; then
    echo "Preparing nested pioarduino environment..."

    pio pkg install --environment "$MT_ENV"

    if [[ -x "$PLATFORMIO_CORE_DIR/penv/bin/python" ]]; then
        uv pip install \
            --python "$PLATFORMIO_CORE_DIR/penv/bin/python" \
            "pioarduino==6.1.19"

        "$PLATFORMIO_CORE_DIR/penv/bin/pio" --version
    else
        echo "ERROR: nested PlatformIO Python not found:"
        echo "  $PLATFORMIO_CORE_DIR/penv/bin/python"
        exit 1
    fi
fi

# Build
if [ "$MT_TARGET" = "build" ]; then
    echo "Building PlatformIO environment: $MT_ENV"
    /workspace/bin/build-"${MT_PLATFORM}".sh "$MT_ENV"
    echo "Build artifacts are located at: $PLATFORMIO_BUILD_DIR"
# Check
elif [ "$MT_TARGET" = "check" ]; then
    /workspace/bin/check-all.sh "$MT_ENV"
fi
