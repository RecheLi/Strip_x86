#!/bin/sh

APP_PATH="/Users/user/Desktop/testSh" # 工程的根目录
TMP_FRAMEWORKS_PATH="${APP_PATH}/TMP" #临时存储完整指令集的文件夹
ARCHS="armv7s arm64e arm64 armv7" #支持的指令集
NEED_STRIP_FRAMEWORK_PATHS=("Pods/NIMSDK_LITE/NIMSDK" "Pods/QY_iOS_SDK/SDK") #需要移除模拟器架构的库的相对路径
NEED_STRIP_EXEC_FILE_NAMES=("NIMSDK" "QYSDK") #可执行文件的名称 

# ****************************************************************************************
# ！！！Warning NEED_STRIP_EXEC_FILE_NAMES与NEED_STRIP_FRAMEWORK_PATHS 一定要一一对应
# ****************************************************************************************
recover_exec_file() {

    pod_executable_file_path="$1"
    file_name="$2"
    echo "****> pod中可执行文件的相对路径：$pod_executable_file_path 文件名称：$file_name"
    all_archs_executable_file_path="$TMP_FRAMEWORKS_PATH/$file_name" # 全指令可执行文件在TMP下的路径
    echo "****> 全指令可执行文件在TMP下的路径：$all_archs_executable_file_path"
    if [ ! -f "$all_archs_executable_file_path" ]; then #全指令集的可执行文件不存在
        echo "****> 全指令集可执行文件不存在"
    else
        echo "****> 全指令集可执行文件已经存在"
        absolute_path=${APP_PATH}/${pod_executable_file_path}
        find "$absolute_path" -name '*.framework' -type d | while read -r framework
        do 
        framework_executable_path="${framework}/${file_name}" #pod中执行文件的路径
        support_archs="$(lipo -info "$framework_executable_path" | rev | cut -d ':' -f1 | rev)" 
        echo "****> pod中framework支持的指令集：$support_archs"
        i386=$(echo $support_archs | grep "i386")
        x86_64=$(echo $support_archs | grep "x86_64")
        if [[ "$i386" != "" ]] || [[ "$x86_64" != "" ]];then
            echo "****> 带模拟器版本,而且TMP目录存在完整指令集的可执行文件，进行删除操作"
        else
            echo "****> 存在全指令集的可执行文件，替换"
            cp -f $all_archs_executable_file_path $framework_executable_path
            fi
        done
    fi
}

if [ ! -d "$TMP_FRAMEWORKS_PATH" ]; then #是否存在目录
    echo "****> TMP目录不存在"
else
    for (( i = 0 ; i < ${#NEED_STRIP_FRAMEWORK_PATHS[@]} ; i++ ))
    do
        echo ${NEED_STRIP_FRAMEWORK_PATHS[$i]}
        recover_exec_file "${NEED_STRIP_FRAMEWORK_PATHS[$i]}" "${NEED_STRIP_EXEC_FILE_NAMES[$i]}"
    done
    rm -r $TMP_FRAMEWORKS_PATH
fi

