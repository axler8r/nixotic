#!/usr/bin/env bash
#
# Shared preflight checks for nixotic scripts.
# Source this file; call individual check functions as needed.
#
# Requires bash 4+ (set -euo pipefail in the caller).
#

_preflight_check_nix() {
    if ! command -v nix >/dev/null 2>&1; then
        echo "error: nix is not available on PATH" >&2
        echo "  This script requires a system with nix installed." >&2
        return 1
    fi
}

_preflight_enable_flakes() {
    if [[ -z "${NIX_CONFIG:-}" ]] || ! echo "${NIX_CONFIG}" | grep -q "nix-command"; then
        export NIX_CONFIG="experimental-features = nix-command flakes"
    fi
}

_preflight_check_network() {
    if ! curl -fsSI https://github.com >/dev/null 2>&1; then
        echo "error: cannot reach https://github.com" >&2
        echo "" >&2
        echo "  Bring up the network first, then re-run this script:" >&2
        echo "    Ethernet:  sudo dhcpcd <iface>" >&2
        echo "    Wi-Fi:     sudo wpa_supplicant -B -i <iface> -c <(wpa_passphrase SSID PASS)" >&2
        echo "    Verify:    curl -fsSI https://github.com" >&2
        return 1
    fi
}

nixotic_preflight() {
    _preflight_check_nix || return 1
    _preflight_enable_flakes
    _preflight_check_network || return 1
}
