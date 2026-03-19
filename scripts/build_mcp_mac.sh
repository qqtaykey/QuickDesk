#!/bin/bash

echo
echo
echo "---------------------------------------------------------------"
echo "build quickdesk-mcp (Rust MCP Bridge)"
echo "---------------------------------------------------------------"

{
    cd "$(dirname "$0")"
    script_path=$(pwd)
    cd - > /dev/null
} &> /dev/null

old_cd=$(pwd)
cd "$(dirname "$0")"

build_mode=release

echo
echo
echo "---------------------------------------------------------------"
echo "parse arguments"
echo "---------------------------------------------------------------"

while [ $# -gt 0 ]; do
    case "$(echo "$1" | tr '[:upper:]' '[:lower:]')" in
        debug)   build_mode=debug ;;
        release) build_mode=release ;;
    esac
    shift
done

echo "[*] build mode: $build_mode"
echo

mcp_dir="$script_path/../quickdesk-mcp"
output_path="$script_path/../output/arm64"

echo "[*] mcp dir: $mcp_dir"
echo "[*] output path: $output_path"

if ! command -v cargo &> /dev/null; then
    echo "[!] error: cargo not found. Please install Rust: https://rustup.rs"
    cd "$old_cd"
    exit 1
fi

cd "$mcp_dir"
echo "[*] building quickdesk-mcp..."

if [ "$build_mode" = "debug" ]; then
    cargo build
    if [ $? -ne 0 ]; then
        echo "[!] cargo build failed"
        cd "$old_cd"
        exit 1
    fi
    cargo_out="$mcp_dir/target/debug"
    dest_dir="$output_path/Debug"
else
    cargo build --release
    if [ $? -ne 0 ]; then
        echo "[!] cargo build failed"
        cd "$old_cd"
        exit 1
    fi
    cargo_out="$mcp_dir/target/release"
    dest_dir="$output_path/Release"
fi

mkdir -p "$dest_dir"
cp "$cargo_out/quickdesk-mcp" "$dest_dir/"
echo "[*] copied quickdesk-mcp to $dest_dir"

echo
echo
echo "---------------------------------------------------------------"
echo "[*] quickdesk-mcp build finished!"
echo "---------------------------------------------------------------"

cd "$old_cd"
exit 0
