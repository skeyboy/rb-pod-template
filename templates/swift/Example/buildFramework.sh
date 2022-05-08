TARGETNAME=$1
WORK_TYPE="project" # 有效值 project / workspace (cocoapods项目)
SCHEME_NAME=$1

SCRIPT_PATH=$(cd `dirname $0`; pwd)
SRCROOT=${SCRIPT_PATH}/Pods

WORK_PATH=${SRCROOT}/${TARGETNAME}

rm -rf ${SCRIPT_PATH}/build

BUILD_ROOT=${SCRIPT_PATH}/build
CONFIGURATION="Release"

mkdir ${SCRIPT_PATH}/build


#echo ${SRCROOT}
#echo ${TARGETNAME}

echo "🚀 开始创建${TARGETNAME}.framework"
INSTALL_DIR=${SRCROOT}/Products/${TARGETNAME}.framework
DEVICE_DIR=${BUILD_ROOT}/${CONFIGURATION}-iphoneos/${TARGETNAME}/${TARGETNAME}.framework
DEVICE_SWIFTMODULE_DIR=${DEVICE_DIR}/"Modules"/${TARGETNAME}".swiftmodule"

SIMULATOR_DIR=${BUILD_ROOT}/${CONFIGURATION}-iphonesimulator/${TARGETNAME}/${TARGETNAME}.framework
SIMULATOR_SWIFTMODULE_DIR=${SIMULATOR_DIR}/"Modules"/${TARGETNAME}".swiftmodule"

#echo ${INSTALL_DIR}
#echo ${DEVICE_DIR}
#echo ${DEVICE_SWIFTMODULE_DIR}

echo "🚀 开始编译真机设备"
xcodebuild -${WORK_TYPE} "${SRCROOT}/Pods.xcodeproj" -scheme $SCHEME_NAME -configuration ${CONFIGURATION} -sdk iphoneos | xcpretty
if [ "$?" != 0 ]
then
    echo "❎❎ 真机设备编译失败..."
    exit 0
fi

xcodebuild -${WORK_TYPE} "${SRCROOT}/Pods.xcodeproj" -scheme $SCHEME_NAME -configuration ${CONFIGURATION} -sdk iphonesimulator -arch x86_64 | xcpretty

if [ "$?" != 0 ]
then
    echo "❎❎ 模拟器设备编译失败..."
    exit 0
fi

# 如果合并包已经存在，则替换
if [ -d "${INSTALL_DIR}" ]
then
rm -rf "${INSTALL_DIR}"
fi

mkdir -p "${INSTALL_DIR}"

cp -R "${DEVICE_DIR}/" "${INSTALL_DIR}/"

# 使用lipo命令将其合并成一个通用framework
# 最后将生成的通用framework放置在工程根目录下新建的Products目录下
lipo -create "${DEVICE_DIR}/${TARGETNAME}" "${SIMULATOR_DIR}/${TARGETNAME}" -output "${INSTALL_DIR}/${TARGETNAME}"
# 拷贝 simulator 的swiftmodule
cp -r ${SIMULATOR_SWIFTMODULE_DIR}/* "${INSTALL_DIR}/Modules/${TARGETNAME}.swiftmodule"

if [ "$?" != 0 ]
then
    echo "❎❎ 拷贝失败..."
    exit 0
fi


# 拷贝 真机 的swiftmodule
cp -r ${DEVICE_SWIFTMODULE_DIR}/* "${INSTALL_DIR}/Modules/${TARGETNAME}.swiftmodule"

FINAL_FRAMEWORK_PATH=${SRCROOT}/../../

cp -R "${INSTALL_DIR}" "${FINAL_FRAMEWORK_PATH}"

echo "🚀  ✌️ ✌️ ✌️  ${TARGETNAME}.framework 制作成功"

echo "${TARGETNAME}.framework 路径：${FINAL_FRAMEWORK_PATH}"
