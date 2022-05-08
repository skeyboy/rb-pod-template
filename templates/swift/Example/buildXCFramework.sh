TARGETNAME=$1
WORK_TYPE="project" # 有效值 project / workspace (cocoapods项目)
SCHEME_NAME=$1

SCRIPT_PATH=$(cd `dirname $0`; pwd)
SRCROOT=${SCRIPT_PATH}/Pods

WORK_PATH=${SRCROOT}/${TARGETNAME}

rm -rf ${SCRIPT_PATH}/build

BUILD_ROOT=${SCRIPT_PATH}/build
CONFIGURATION="Debug" # Debug Release

mkdir ${SCRIPT_PATH}/build


#echo ${SRCROOT}
#echo ${TARGETNAME}

echo "🚀 开始创建${TARGETNAME}.xcframework"
INSTALL_DIR=${SRCROOT}/Products/${TARGETNAME}.framework
DEVICE_DIR=${BUILD_ROOT}/${CONFIGURATION}-iphoneos/${TARGETNAME}/${TARGETNAME}.framework
DEVICE_SWIFTMODULE_DIR=${DEVICE_DIR}/"Modules"/${TARGETNAME}".swiftmodule"

SIMULATOR_DIR=${BUILD_ROOT}/${CONFIGURATION}-iphonesimulator/${TARGETNAME}/${TARGETNAME}.framework
SIMULATOR_SWIFTMODULE_DIR=${SIMULATOR_DIR}/"Modules"/${TARGETNAME}".swiftmodule"

echo "🚀 开始编译真机设备"
xcodebuild archive -project "${SRCROOT}/Pods.xcodeproj" -scheme $SCHEME_NAME -configuration ${CONFIGURATION} -destination 'generic/platform=iOS' -archivePath "../archives/$SCHEME_NAME.framework-iphoneos.xcarchive" SKIP_INSTALL=NO | xcpretty
if [ "$?" != 0 ]
then
    echo "❎❎ 真机设备编译失败..."
    exit 0
fi

echo "🚀 开始编译模拟器设备"
xcodebuild archive -project "${SRCROOT}/Pods.xcodeproj" -scheme $SCHEME_NAME -configuration ${CONFIGURATION} -destination 'generic/platform=iOS Simulator' -archivePath "../archives/${SCHEME_NAME}.framework-iphonesimulator.xcarchive" SKIP_INSTALL=NO | xcpretty

if [ "$?" != 0 ]
then
    echo "❎❎ 模拟器设备编译失败..."
    exit 0
fi

# 如果合并包已经存在，则替换
if [ -d "../${SCHEME_NAME}.xcframework" ]
then
rm -rf "../${SCHEME_NAME}.xcframework"
fi

xcodebuild -create-xcframework \
-archive "../archives/${SCHEME_NAME}.framework-iphonesimulator.xcarchive" \
-framework "${SCHEME_NAME}.framework" \
-archive "../archives/${SCHEME_NAME}.framework-iphoneos.xcarchive" \
-framework "${SCHEME_NAME}.framework" \
-output "../${SCHEME_NAME}.xcframework"

if [ "$?" != 0 ]
then
    echo "❎❎ xcframework 生成失败..."
    exit 0
fi

echo "🚀  ✌️ ✌️ ✌️  ${TARGETNAME}.xcframework 制作成功"

echo "clean ……"
rm -rf ${SCRIPT_PATH}/build


        
        
        
    
