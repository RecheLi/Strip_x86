# Strip_x86

### 为解决iOS打包上传时要手动移除动态库的i386及x86_64支持的问题，同时增加带薪划水的时间，特意写了2个脚本来实现这一功能：

#### 1.移除动态库模拟器支持，在此之前需要将全指令集支持的文件复制一份到TMP文件夹：
```
APP_PATH="${SRCROOT}" # 工程的根目录
TMP_FRAMEWORKS_PATH="${APP_PATH}/TMP" #临时存储完整指令集文件的文件夹

# ****************************************************************************************
# ！！！Warning NEED_STRIP_EXEC_FILE_NAMES与NEED_STRIP_FRAMEWORK_PATHS 一定要一一对应
# ****************************************************************************************

NEED_STRIP_FRAMEWORK_PATHS=("Pods/SomeSDK1/SDK" "Pods/SomeSDK2/SDK") #需要移除模拟器架构的库的相对路径
NEED_STRIP_EXEC_FILE_NAMES=("sdk1" "sdk2") #可执行文件的名称

# warning 以下CONFIGURATION字段在Xcode中有定义，放在build phase中时可注释(此处为测试)
# CONFIGURATION="Release"
SUPPORT_ARCHS="armv7s arm64e arm64 armv7" #支持的指令集

# 移除不支持的指令集
strip_invalid_archs() {
    binary="$1"
    echo "****> 当前framework二进制的路径：${binary}"
    archs="$(lipo -info "$binary" | rev | cut -d ':' -f1 | rev)"
    echo "****> 所有支持的指令集：$archs"
    stripped=""
    for arch in $archs; do
        if ! [[ "${SUPPORT_ARCHS}" = *"$arch"* ]]; then
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
    echo "****> pod中可执行文件的相对路径：$pod_executable_file_path 文件名称：$file_name"
    all_archs_executable_file_path="$TMP_FRAMEWORKS_PATH/$file_name" # 全指令可执行文件在TMP下的路径
    if [ ! -f "$all_archs_executable_file_path" ]; #全指令集的可执行文件不存在
    then
        echo "****> 将文件复制到TMP路径：$all_archs_executable_file_path"
        absolute_path=${APP_PATH}/${pod_executable_file_path}
        echo "****> pod中文件绝对路径：$absolute_path"
        find "$absolute_path" -name '*.framework' -type d | while read -r framework
        do
            framework_executable_path="${framework}/${file_name}"
            echo "****> 可执行文件路径：$framework_executable_path"
            cp $framework_executable_path $TMP_FRAMEWORKS_PATH
        done
    else
        echo "****> 可执行文件已经存在"
    fi
    absolute_path=${APP_PATH}/${pod_executable_file_path}
    find "$absolute_path" -name '*.framework' -type d | while read -r framework
    do
        framework_executable_path="$framework/${file_name}"
        echo "****> 可执行文件路径：$framework_executable_path"
        strip_invalid_archs "$framework_executable_path"
    done
}

if [[ "$CONFIGURATION" == "Release" ]]; then #仅在release下执行
    echo "Release"
    for (( i = 0 ; i < ${#NEED_STRIP_FRAMEWORK_PATHS[@]} ; i++ ))
    do
    echo ${NEED_STRIP_FRAMEWORK_PATHS[$i]}
    handle_release_exec_file "${NEED_STRIP_FRAMEWORK_PATHS[$i]}" "${NEED_STRIP_EXEC_FILE_NAMES[$i]}"
    done
fi

```

#### 2.将temp中的全指令集可执行文件替换pod路径下的真机版可执行文件

```
# ****************************************************************************************
# ！！！Warning NEED_STRIP_EXEC_FILE_NAMES与NEED_STRIP_FRAMEWORK_PATHS 一定要一一对应
# ****************************************************************************************

APP_PATH="${SRCROOT}" # 工程的根目录
TMP_FRAMEWORKS_PATH="${APP_PATH}/TMP" #临时存储完整指令集的文件夹
# ARCHS="armv7s arm64e arm64 armv7" #支持的指令集
NEED_STRIP_FRAMEWORK_PATHS=("Pods/NIMSDK_LITE/NIMSDK" "Pods/QY_iOS_SDK/SDK") #需要移除模拟器架构的库的相对路径
NEED_STRIP_EXEC_FILE_NAMES=("NIMSDK" "QYSDK") #可执行文件的名称 

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

```

#### 3.Xcode Build Phases中添加脚本


  > 1.在 [CP] Check Pods Manifest.lock 下添加第一个移除脚本；

  > 2.在 Embed Frameworks 后面添加第二个恢复脚本。
