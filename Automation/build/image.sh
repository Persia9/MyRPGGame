#!/bin/bash

PROJECT_DIR="$(dirname "$(realpath "$0")")"
source_file="$PROJECT_DIR/Images.xcassets/AppIcon.appiconset/icon-1024.png"
target_dir="$PROJECT_DIR/Images.xcassets/AppIcon.appiconset"

#echo ${target_dir}

if [ ! -f ${source_file} ];then
    echo "source image not exists."
    exit 0
fi

if [ ! -d ${target_dir} ];then
    echo "target dir not exists."
    exit 0
fi
# mkdir ${target_dir}

sips -z 20 20 ${source_file} -o ${target_dir}/icon-20.png
sips -z 29 29 ${source_file} -o ${target_dir}/icon-29.png
sips -z 40 40 ${source_file} -o ${target_dir}/icon-40.png
sips -z 58 58 ${source_file} -o ${target_dir}/icon-58.png
sips -z 60 60 ${source_file} -o ${target_dir}/icon-60.png
sips -z 76 76 ${source_file} -o ${target_dir}/icon-76.png
sips -z 80 80 ${source_file} -o ${target_dir}/icon-80.png
sips -z 87 87 ${source_file} -o ${target_dir}/icon-87.png
sips -z 120 120 ${source_file} -o ${target_dir}/icon-120.png
sips -z 152 152 ${source_file} -o ${target_dir}/icon-152.png
sips -z 167 167 ${source_file} -o ${target_dir}/icon-167.png
sips -z 180 180 ${source_file} -o ${target_dir}/icon-180.png
sips -z 1024 1024 ${source_file} -o ${target_dir}/icon-1024.png

echo "导出icon完成"