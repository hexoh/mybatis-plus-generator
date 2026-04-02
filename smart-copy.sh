#!/bin/bash

# 检查参数
if [ $# -lt 2 ]; then
    echo "用法: $0 <源Java目录> <目标项目根目录>"
    echo "示例: $0 ./src/main/java/com/yourcompany ../your-project"
    exit 1
fi

SOURCE_JAVA_DIR="$1"  # 源Java目录，如: ./src/main/java/com/rhzt
TARGET_PROJECT="$2"   # 目标项目根目录，如: ../your-project

echo "源Java目录: $SOURCE_JAVA_DIR"
echo "目标项目: $TARGET_PROJECT"
echo "开始智能同步文件..."

# 计数器
new_count=0
skip_count=0

# 获取父包名（如com.rhzt）
PARENT_PACKAGE=$(basename "$(dirname "$SOURCE_JAVA_DIR")").$(basename "$SOURCE_JAVA_DIR")
echo "检测到父包: $PARENT_PACKAGE"

# 1. 先处理Java文件
find "$SOURCE_JAVA_DIR" -type f -name "*.java" | while read -r source_file; do
    # 获取相对于SOURCE_JAVA_DIR的路径
    relative_path="${source_file#$SOURCE_JAVA_DIR/}"

    # 构建目标路径
    target_file="$TARGET_PROJECT/src/main/java/$PARENT_PACKAGE/$relative_path"

    # 如果目标文件不存在，则复制
    if [ ! -f "$target_file" ]; then
        target_dir=$(dirname "$target_file")
        mkdir -p "$target_dir"
        cp "$source_file" "$target_file"
        echo "✅ 新增Java: $relative_path"
        new_count=$((new_count + 1))
    else
        echo "⏭️  已存在Java: $relative_path"
        skip_count=$((skip_count + 1))
    fi
done

# 2. 处理XML文件 - 通用方法
# 查找所有XML文件
find "$SOURCE_JAVA_DIR" -type f -name "*.xml" | while read -r source_file; do
    # 获取相对于SOURCE_JAVA_DIR的完整路径
    full_relative_path="${source_file#$SOURCE_JAVA_DIR/}"

    # 分析XML文件的路径结构
    if [[ "$full_relative_path" == */xml/* ]]; then
        # XML文件在xml目录下
        # 提取xml/之后的部分
        xml_relative_path="${full_relative_path#*/xml/}"

        if [[ "$xml_relative_path" == */* ]]; then
            # 有子目录，如meet/SomeMapper.xml
            sub_dir=$(dirname "$xml_relative_path")
            filename=$(basename "$xml_relative_path")
            target_file="$TARGET_PROJECT/src/main/resources/mapper/$sub_dir/$filename"
        else
            # 没有子目录，直接放在mapper下
            filename="$xml_relative_path"
            target_file="$TARGET_PROJECT/src/main/resources/mapper/$filename"
        fi
    elif [[ "$full_relative_path" == */mapper/* ]]; then
        # XML文件在mapper目录下
        # 提取mapper/之后的部分
        mapper_relative_path="${full_relative_path#*/mapper/}"

        if [[ "$mapper_relative_path" == */* ]]; then
            # 有子目录
            sub_dir=$(dirname "$mapper_relative_path")
            filename=$(basename "$mapper_relative_path")
            target_file="$TARGET_PROJECT/src/main/resources/mapper/$sub_dir/$filename"
        else
            # 没有子目录
            filename="$mapper_relative_path"
            target_file="$TARGET_PROJECT/src/main/resources/mapper/$filename"
        fi
    else
        # XML在其他位置，直接复制到resources对应位置
        target_file="$TARGET_PROJECT/src/main/resources/$full_relative_path"
    fi

    # 如果目标文件不存在，则复制
    if [ ! -f "$target_file" ]; then
        target_dir=$(dirname "$target_file")
        mkdir -p "$target_dir"
        cp "$source_file" "$target_file"
        echo "✅ 新增XML: $full_relative_path -> ${target_file#$TARGET_PROJECT/}"
        new_count=$((new_count + 1))
    else
        echo "⏭️  已存在XML: $full_relative_path -> ${target_file#$TARGET_PROJECT/}"
        skip_count=$((skip_count + 1))
    fi
done

# 3. 处理其他类型的文件（可选）
find "$SOURCE_JAVA_DIR" -type f -name "*.yml" -o -name "*.yaml" -o -name "*.properties" | while read -r source_file; do
    full_relative_path="${source_file#$SOURCE_JAVA_DIR/}"
    target_file="$TARGET_PROJECT/src/main/resources/$full_relative_path"

    if [ ! -f "$target_file" ]; then
        target_dir=$(dirname "$target_file")
        mkdir -p "$target_dir"
        cp "$source_file" "$target_file"
        echo "✅ 新增配置文件: $full_relative_path -> ${target_file#$TARGET_PROJECT/}"
        new_count=$((new_count + 1))
    else
        echo "⏭️  已存在配置文件: $full_relative_path -> ${target_file#$TARGET_PROJECT/}"
        skip_count=$((skip_count + 1))
    fi
done

echo ""
echo "同步完成！"