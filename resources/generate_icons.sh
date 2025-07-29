#!/usr/bin/env bash
icon_sizes=(16 32 64 128 256 512)

generate_iconset() {
    # $1 - in; $2 - output icns path; $3 - cropped icon

    # temporary output directory
    out="${2}.iconset"

    if [ ! -d "$out" ]; then
        mkdir "$out"
    fi

    # s - size
    for s in ${icon_sizes[@]}; do
        # d - double size (used for retina versions, @2x)
        d=$(($s * 2))
        input_file="$1"

        # 16x16 and 32x32 icons use a cropped version
        if [ "$s" = 16 ] || [ "$s" = 32 ] || [ "$d" = 16 ] || [ "$d" = 32 ]; then
            if [ -n "$3" ] && [ -f "$3" ]; then
                input_file="$3"
            fi
        fi

        sips -z $s $s "$input_file" --out "$out/icon_${s}x${s}.png"
        sips -z $d $d "$input_file" --out "$out/icon_${s}x${s}@2x.png"
    done

    iconutil -c icns "$out" -o "$2"

    # delete the iconset folder cuz we don't need it anymore
    rm -rf "$out"
}

_root_dir="$(dirname "$(dirname "$(greadlink -f "$0")")")"
_main_repo="$_root_dir/helium-chromium"
_resources_dir="$_main_repo/resources"
_platform_resources="$_root_dir/resources"

if [ ! -d "${_platform_resources}/generated" ]; then
    mkdir "${_platform_resources}/generated"
fi

generate_iconset "${_resources_dir}/branding/app_icon/shadow.png" \
    "${_platform_resources}/generated/app.icns" \
    "${_resources_dir}/branding/app_icon/shadow_cropped.png"

generate_iconset "${_resources_dir}/branding/app_icon/file.png" \
    "${_platform_resources}/generated/document.icns"
