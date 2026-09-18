#!/usr/bin/env bash
# Run inside the matching Ylarod DDK container (or a configured DDK host).
set -euo pipefail

: "${DDK_TARGET:?Set DDK_TARGET to the Android kernel target}"
case "$DDK_TARGET" in
    android12-5.10|android13-5.10|android13-5.15|android14-6.1|android15-6.6|android16-6.12) ;;
    *) echo "Unsupported DDK target: $DDK_TARGET" >&2; exit 2 ;;
esac

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export KDIR="${KDIR:-/opt/ddk/kdir/$DDK_TARGET}"
test -f "$KDIR/Makefile"
output_dir="$project_dir/artifacts/$DDK_TARGET"
mkdir -p "$output_dir"
# Never package the prebuilt .ko files already tracked in the repository.
rm -f -- "$output_dir/gongchuang.ko" "$output_dir/SHA256SUMS"
build_dir="$(mktemp -d -t gongchuang-ddk.XXXXXXXX)"
trap 'rm -rf -- "$build_dir"' EXIT
cp -a "$project_dir/src/." "$build_dir/"

{
    printf 'Target: %s\nImage: %s\nCommit: %s\n' \
        "$DDK_TARGET" "${DDK_IMAGE:-local}" "${GITHUB_SHA:-local}"
    clang --version
    make -C "$project_dir" DRIVER_DIR="$build_dir" clean
    make -C "$project_dir" DRIVER_DIR="$build_dir" -j"${JOBS:-$(nproc)}"
    test -s "$build_dir/gongchuang.ko"
    llvm-readelf -h "$build_dir/gongchuang.ko"
    llvm-readelf -h "$build_dir/gongchuang.ko" | grep -q 'Machine:.*AArch64'
    # Preserve debug symbols and the DDK's symbol version information.
    cp "$build_dir/gongchuang.ko" "$output_dir/gongchuang.ko"
    llvm-readelf --string-dump=.modinfo "$output_dir/gongchuang.ko" > "$output_dir/modinfo.txt"
    printf 'target=%s\nimage=%s\ncommit=%s\n' \
        "$DDK_TARGET" "${DDK_IMAGE:-local}" "${GITHUB_SHA:-local}" > "$output_dir/build-info.txt"
    (cd "$output_dir" && sha256sum gongchuang.ko > SHA256SUMS)
} 2>&1 | tee "$output_dir/build.log"
