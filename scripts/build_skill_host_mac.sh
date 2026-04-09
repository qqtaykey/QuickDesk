#!/bin/bash

echo
echo
echo "---------------------------------------------------------------"
echo "build quickdesk-skill-host + built-in skills (Rust workspace)"
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

skill_host_dir="$script_path/../quickdesk-skill-host"
output_path="$script_path/../output/arm64"

echo "[*] skill-host workspace dir: $skill_host_dir"
echo "[*] output path: $output_path"

if ! command -v cargo &> /dev/null; then
    echo "[!] error: cargo not found. Please install Rust: https://rustup.rs"
    cd "$old_cd"
    exit 1
fi

cd "$skill_host_dir"
echo "[*] building quickdesk-skill-host workspace..."

if [ "$build_mode" = "debug" ]; then
    cargo build
    if [ $? -ne 0 ]; then
        echo "[!] cargo build failed"
        cd "$old_cd"
        exit 1
    fi
    cargo_out="$skill_host_dir/target/debug"
    dest_dir="$output_path/Debug"
else
    cargo build --release
    if [ $? -ne 0 ]; then
        echo "[!] cargo build failed"
        cd "$old_cd"
        exit 1
    fi
    cargo_out="$skill_host_dir/target/release"
    dest_dir="$output_path/Release"
fi

# copy skill-host binary
mkdir -p "$dest_dir"
cp "$cargo_out/quickdesk-skill-host" "$dest_dir/"
echo "[*] copied quickdesk-skill-host to $dest_dir"

# copy skill binaries and SKILL.md into per-skill subdirectories
skills_src="$skill_host_dir/skills"
for skill in sys-info file-ops shell-runner; do
    mkdir -p "$dest_dir/skills/$skill"
    cp "$cargo_out/$skill" "$dest_dir/skills/$skill/"
    cp "$skills_src/$skill/SKILL.md" "$dest_dir/skills/$skill/"
    echo "[*] copied $skill/$skill + SKILL.md"
done

echo
echo
echo "---------------------------------------------------------------"
echo "[*] quickdesk-skill-host build finished!"
echo "---------------------------------------------------------------"

cd "$old_cd"
exit 0
