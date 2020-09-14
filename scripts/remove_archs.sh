#!/bin/sh

APP_PATH="/Users/user/Desktop/testSh" # 工程的根目录
TMP_FRAMEWORKS_PATH="${APP_PATH}/TMP" #临时存储完整指令集的文件夹
NEED_STRIP_FRAMEWORK_PATHS=("Pods/NIMSDK_LITE/NIMSDK" "Pods/QY_iOS_SDK/SDK") #需要移除模拟器架构的库的相对路径
NEED_STRIP_EXEC_FILE_NAMES=("NIMSDK" "QYSDK") #可执行文件的名称 与NEED_STRIP_FRAMEWORK_PATHS 一一对应

# warning 以下2个字段在Xcode中有，此处为测试
CONFIGURATION="Release"
ARCHS="armv7s arm64e arm64 armv7" #支持的指令集

# 移除不支持的指令集
strip_invalid_archs() {
    binary="$1"
    echo "当前framework二进制的路径：${binary}"
    archs="$(lipo -info "$binary" | rev | cut -d ':' -f1 | rev)"
    echo "所有支持的指令集：$archs"
    stripped=""
    for arch in $archs; do
        if ! [[ "${ARCHS}" == *"$arch"* ]]; then
            lipo -remove "$arch" -output "$binary" "$binary"
            stripped="$stripped $arch"
        fi
        done
    if [[ "$stripped" ]]; then
        echo "移除 $binary of architectures:$stripped 成功"
    fi
}

handle_release_exec_file() {
    if [ ! -d "$TMP_FRAMEWORKS_PATH" ]; then #是否存在目录
        mkdir $TMP_FRAMEWORKS_PATH
    fi
    pod_executable_file_path="$1"
    file_name="$2"
    # file_name=$(echo "$pod_executable_file_path" |awk -F '[/]' '{print $NF}')
    echo "pod中可执行文件的相对路径：$pod_executable_file_path 文件名称：$file_name"
    all_archs_executable_file_path="$TMP_FRAMEWORKS_PATH/$file_name" # 全指令可执行文件在TMP下的路径
    if [ ! -f "$all_archs_executable_file_path" ]; #全指令集的可执行文件不存在
    then
        echo "将文件复制到TMP路径：$all_archs_executable_file_path"
        absolute_path=${APP_PATH}/${pod_executable_file_path}
        echo "pod中文件绝对路径：$absolute_path"
        find "$absolute_path" -name '*.framework' -type d | while read -r framework
        do
            framework_executable_path="${framework}/${file_name}"
            echo "可执行文件路径：$framework_executable_path"
            cp $framework_executable_path $TMP_FRAMEWORKS_PATH
        done
    else
        echo "可执行文件已经存在"
    fi
    absolute_path=${APP_PATH}/${pod_executable_file_path}
    find "$absolute_path" -name '*.framework' -type d | while read -r framework
    do
        framework_executable_path="$framework/${file_name}"
        echo "可执行文件路径：$framework_executable_path"
        strip_invalid_archs "$framework_executable_path"
    done
}

if [[ "$CONFIGURATION" == "Release" ]]; then
    echo "Release"
    for (( i = 0 ; i < ${#NEED_STRIP_FRAMEWORK_PATHS[@]} ; i++ ))
    do
    echo ${NEED_STRIP_FRAMEWORK_PATHS[$i]}
    handle_release_exec_file "${NEED_STRIP_FRAMEWORK_PATHS[$i]}" "${NEED_STRIP_EXEC_FILE_NAMES[$i]}"
    done
fi

