#!/bin/bash -eux
# Simple script for packing Helium macOS build artifacts on GitHub Actions

_target_cpu="${1:-x86_64}"

_root_dir="$(dirname "$(greadlink -f "$0")")"
_main_repo="$_root_dir/helium-chromium"
_src_dir="$_root_dir/build/src"

# If build finished successfully
if [[ -f "$_root_dir/build_finished_$_target_cpu.log" ]] ; then
  # For packaging
  _helium_version=$(python3 "$_main_repo/utils/helium_version.py" --tree "$_main_repo" --platform-tree "$_root_dir" --print)

  _file_name="helium_${_helium_version}_${_target_cpu}-macos.dmg"
  _hash_name="${_file_name}.hashes.md"

  cd "$_src_dir"

  xattr -cs out/Default/Helium.app

  export OUT_DMG_PATH="$_root_dir/$_file_name"
  export NEEDS_APPDMG=1
  export SKIP_SIGNING=1
  "$_root_dir/sign_and_package_app.sh"

  cd "$_root_dir"
  echo -e "md5: \nsha1: \nsha256: " | tee ./hash_types.txt
  { md5sum "$_file_name" ; sha1sum "$_file_name" ; sha256sum "$_file_name" ; } | tee ./sums.txt

  _hash_md=$(paste ./hash_types.txt ./sums.txt | awk '{print $1 " " $2}')

  echo "file_name=$_file_name" >> $GITHUB_OUTPUT

  _gh_run_href="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

  printf '[Hashes](https://en.wikipedia.org/wiki/Cryptographic_hash_function) for the disk image `%s`: \n' "$_file_name" | tee -a ./${_hash_name}
  printf '\n```\n%s\n```\n' "$_hash_md" | tee -a ./${_hash_name}

  # Use separate folder for build product, so that it can be used as individual asset in case the release action fails
  mkdir -p release_asset
  mv -vn ./*.dmg release_asset/ || true

  if [ "$_target_cpu" = "x86_64" ]; then
    DELTA_ARG="--x86"
  else
    DELTA_ARG="--arm"
  fi

  ./github_prep_sparkle_deltas.sh \
    $DELTA_ARG "./release_asset/$_file_name" \
    --out ./release_asset

  ls -kahl release_asset/
  du -hs release_asset/
fi

gsync --file-system "$_src_dir"

# Needs to be compressed to stay below GitHub's upload limit 2 GB (?!) 2020-11-24; used to be  5-8GB (?)
tar -C build -c -f - src | zstd -vv -11 -T0 -o build_src.tar.zst

sha256sum ./build_src.tar.zst | tee ./sums.txt

mkdir -p upload_part_build
mv -vn ./*.zst ./sums.txt upload_part_build/ || true
cp -va ./*.log upload_part_build/

ls -kahl upload_part_build/
du -hs upload_part_build/

mkdir upload_logs
mv -vn ./*.log upload_logs/

ls -kahl upload_logs/
du -hs upload_logs/

echo "ready for upload action"
