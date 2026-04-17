#!/bin/bash

# 检查参数
if [ $# -lt 2 ]; then
    echo "用法: $0 <源Java目录> <目标项目根目录>"
    echo "示例: $0 ./src/main/java/com/yourcompany ../your-project"
    exit 1
fi

SOURCE_JAVA_DIR="$1"  # 源Java目录，如: ./src/main/java/com/rhzt/modules/meet
TARGET_PROJECT="$2"   # 目标项目根目录，如: ../your-project

echo "源Java目录: $SOURCE_JAVA_DIR"
echo "目标项目: $TARGET_PROJECT"
echo "开始智能同步文件..."

# 计数器
new_count=0
skip_count=0

# 获取父包名（如com.rhzt）
PARENT_PACKAGE=$(echo "$SOURCE_JAVA_DIR" | sed -E 's|.*/java/||')
echo "检测到父包: $PARENT_PACKAGE"

# 自动识别 modules 下的模块名
# 默认：取最后一层目录
MODULE_NAME=$(basename "$SOURCE_JAVA_DIR")
# 如果路径中包含 modules/，则优先取 modules 后的模块名
if [[ "$SOURCE_JAVA_DIR" == *"/modules/"* ]]; then
    MODULE_NAME=$(echo "$SOURCE_JAVA_DIR" | sed -E 's|.*/modules/([^/]+).*|\1|')
fi

echo "检测到模块名: $MODULE_NAME"

# 1. 先处理Java文件
while IFS= read -r source_file; do
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
done < <(find "$SOURCE_JAVA_DIR" -type f -name "*.java")

# 2. 处理XML文件 - 通用方法
while IFS= read -r source_file; do
    # 获取相对于SOURCE_JAVA_DIR的完整路径
    full_relative_path="${source_file#$SOURCE_JAVA_DIR/}"
    filename=$(basename "$source_file")

    # 默认 mapper 目录
    base_mapper_dir="$TARGET_PROJECT/src/main/resources/mapper"
    module_mapper_dir="$base_mapper_dir/$MODULE_NAME"

    # ✅ 判断目标项目是否已存在模块目录
    if [ -d "$module_mapper_dir" ]; then
        target_dir="$module_mapper_dir"
        target_display="mapper/$MODULE_NAME/$filename"
    else
        target_dir="$base_mapper_dir"
        target_display="mapper/$filename"
    fi

    target_file="$target_dir/$filename"

    # 如果目标文件不存在，则复制
    if [ ! -f "$target_file" ]; then
        mkdir -p "$target_dir"
        cp "$source_file" "$target_file"
        echo "✅ 新增XML: $full_relative_path -> $target_display"
        new_count=$((new_count + 1))
    else
        echo "⏭️  已存在XML: $full_relative_path -> $target_display"
        skip_count=$((skip_count + 1))
    fi
done < <(find "$SOURCE_JAVA_DIR" -type f -name "*.xml")

# 3. 处理其他类型的文件（可选）
while IFS= read -r source_file; do
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
done < <(find "$SOURCE_JAVA_DIR" -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.properties" \))

echo ""
echo "同步完成！"
echo "新增文件: $new_count 个"
echo "跳过文件: $skip_count 个"