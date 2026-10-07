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

# ESP32 / pioarduino compatibility workaround
if [[ "$MT_PLATFORM" == "esp32" ]]; then
    echo "Preparing nested pioarduino environment..."

    pio pkg install --environment "$MT_ENV"

    if [[ ! -x "$PLATFORMIO_CORE_DIR/penv/bin/python" ]]; then
        echo "ERROR: nested PlatformIO Python not found:"
        echo "  $PLATFORMIO_CORE_DIR/penv/bin/python"
        exit 1
    fi

    echo "Pinning nested pioarduino core to 6.1.19..."

    "$PLATFORMIO_CORE_DIR/penv/bin/python" -m pip install \
        --force-reinstall \
        "pioarduino==6.1.19"

    "$PLATFORMIO_CORE_DIR/penv/bin/pio" --version

    echo "Locating platform-espressif32..."

    PLATFORM_PY="$(find \
        "$PLATFORMIO_CORE_DIR/platforms" \
        -type f \
        -path '*/espressif32/platform.py' \
        -print \
        -quit
    )"

    if [[ -z "$PLATFORM_PY" || ! -f "$PLATFORM_PY" ]]; then
        echo "ERROR: platform-espressif32/platform.py not found"
        exit 1
    fi

    echo "Using platform file:"
    echo "  $PLATFORM_PY"

    echo "Patching COMMON_IDF_PACKAGES..."

    "$PLATFORMIO_CORE_DIR/penv/bin/python" - "$PLATFORM_PY" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()

old_block = '''COMMON_IDF_PACKAGES = [
    "tool-cmake",
    "tool-ninja",
    "tool-scons",
    "tool-esp-rom-elfs"
]'''

new_block = '''COMMON_IDF_PACKAGES = [
    "tool-cmake",
    "tool-ninja",
    "tool-esp-rom-elfs"
]'''

if old_block in text:
    text = text.replace(old_block, new_block, 1)
    path.write_text(text)
    print("Patched COMMON_IDF_PACKAGES: removed tool-scons")
elif new_block in text:
    print("COMMON_IDF_PACKAGES already patched")
else:
    raise SystemExit(
        f"ERROR: expected COMMON_IDF_PACKAGES block not found in {path}"
    )
PY

    echo "Verifying COMMON_IDF_PACKAGES patch..."

    if "$PLATFORMIO_CORE_DIR/penv/bin/python" - "$PLATFORM_PY" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()

start = text.find("COMMON_IDF_PACKAGES = [")
if start < 0:
    raise SystemExit(1)

end = text.find("]", start)
if end < 0:
    raise SystemExit(1)

block = text[start:end + 1]

if '"tool-scons"' in block:
    raise SystemExit(1)

print("COMMON_IDF_PACKAGES verified: tool-scons is absent")
PY
    then
        :
    else
        echo "ERROR: tool-scons is still present in COMMON_IDF_PACKAGES"
        exit 1
    fi

    echo "ESP32 / pioarduino compatibility patch completed."
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
