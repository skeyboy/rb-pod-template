# 获取到的文件路径
binary_specs="https://gitee.com/liyulong/Specs-Binary.git"
source_specs="https://gitee.com/liyulong/Specs.git"
pod repo add myrepo ${source_specs}
pod repo add myrepo-binary ${binary_specs}
host="http://localhost:8082"
file_path=""
file_name=""
# 文件后缀名
file_extension="podspec"
# 文件夹路径，pwd表示当前文件夹
directory="$(pwd)"

# 参数1: 路径；参数2: 文件后缀名
function getFileAtDirectory(){
    for element in `ls $1`
    do
    dir_or_file=$1"/"$element
    # echo "$dir_or_file"
    if [ -d $dir_or_file ]
    then
    getFileAtDirectory $dir_or_file
    else
    file_extension=${dir_or_file##*.}
    if [[ $file_extension == $2 ]]; then
    echo "$dir_or_file 是 $2 文件"
    file_path=$dir_or_file
    file_name=$element
    fi
    fi
    done
}
getFileAtDirectory $directory $file_extension

echo "\n file_path: ${file_path}"
echo "\n file_name: ${file_name}"


echo "\n ---- 读取podspec文件内容 begin ---- \n"

# 定义pod文件名称
pod_file_name=${file_name}
# 查找 podspec 的版本
search_str="s.version"

# 读取podspec的版本
podspec_version=""
pod_spec_version_new=""
podspec_commit=""
podspec_commit_new=""


#定义了要读取文件的路径
my_file="${pod_file_name}"
while read my_line
do
#输出读到的每一行的结果
# echo $my_line

# 查找到包含的内容，正则表达式获取以 ${search_str} 开头的内容
result=$(echo ${my_line} | grep "^${search_str}")
if [[ "$result" != "" ]]
then
echo "\n ${my_line} 包含 ${search_str}"

# 分割字符串，是变量名称，不是变量的值; 前面的空格表示分割的字符，后面的空格不可省略
array=(${result// / })
# 数组长度
count=${#array[@]}
# 获取最后一个元素内容
version=${array[count - 1]}
# 去掉 '
version=${version//\'/}

podspec_version=$version
#else
# echo "\n ${my_line} 不包含 ${search_str}"
fi

done < $my_file
echo "\n podspec_version: ${podspec_version}"


pod_spec_name=${file_name}
pod_spec_version=${podspec_version}

echo "\n ---- 版本号自增 ---- \n"
increment_version ()
{
    declare -a part=( ${1//\./ } )
    declare    new
    declare -i carry=1
    CNTR=${#part[@]}-1
    len=${#part[CNTR]}
    new=$((part[CNTR]+carry))
    part[CNTR]=${new}
    new="${part[*]}"
    pod_spec_version_new=${new// /.}
}
increment_version $pod_spec_version
echo "\n podspec_version_new: ${pod_spec_version_new}"

LineNumber=`grep -nE 's.version.*=' ${pod_spec_name} | cut -d : -f1`
sed -i "" "${LineNumber}s/${podspec_version}/${pod_spec_version_new}/g" ${pod_spec_name}

project_path=$(cd `dirname $0`; pwd)
project_name="${project_path##*/}"
echo ${project_name}

current_git_branch_latest_id=`git rev-parse HEAD`

# 检测还原为 :git方式 即 源码
swift build.swift $file_path $project_name $current_git_branch_latest_id $pod_spec_version_new "1" $host

rm -rf ./.git/hooks
git add "${project_name}/*"
git commit -m"${pod_spec_version_new}_${current_git_branch_latest_id}"
git tag "${pod_spec_version_new}"
git push --tags
git push

pod repo push myrepo ${pod_spec_name} --verbose --allow-warnings --sources="${source_specs}"



sh Example/buildFramework.sh "${project_name}"
#sh Example/buildXCFramework.sh "${project_name}"
# 切换为 :http 下载 framework方式
swift build.swift $file_path $project_name $current_git_branch_latest_id $pod_spec_version_new "0" $host
zip_file_path="${project_name}"
mkdir -p "binary/${project_name}"
mv "${project_name}.framework" "${zip_file_path}"
cp "${project_name}.podspec" "Example"  "${zip_file_path}"
zip_filename="${project_name}.zip"
zip -r "${project_name}.zip" "${project_name}.framework" "${project_name}.podspec" "${project_name}/**/*"
curl -X POST "${host}/module_build" \
-F "file=@${zip_filename}" \
-F "moduleName=${project_name}" \
-F "commitId=${current_git_branch_latest_id}" \
-F "version=${pod_spec_version_new}" \
-H "Content-Type: multipart/form-data"


rm -rf  -f -r "$(pwd)/${project_name}.framework"
rm -rf -f -r "$(pwd)/archives"
rm -rf "$(pwd)/${zip_filename}"
rm -rf  -f -r "$(pwd)/${project_name}.xcframework"
rm -rf  -f -r "$(pwd)/${project_name}.framework"

pod repo push myrepo-binary ${pod_spec_name} --verbose --allow-warnings  --skip-import-validation
swift build.swift $file_path $project_name $current_git_branch_latest_id $pod_spec_version_new "1" $host
