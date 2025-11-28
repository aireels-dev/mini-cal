#!/usr/bin/env python3
"""
合并提取的字符串到 Localizable.xcstrings
"""

import json
from pathlib import Path

def load_json(file_path):
    """加载 JSON 文件"""
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data, file_path):
    """保存 JSON 文件"""
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def merge_localizations():
    """合并本地化字符串"""
    project_root = Path(__file__).parent.parent
    localizable_path = project_root / 'MiniCal/Resources/Localizations/Localizable.xcstrings'
    extracted_path = project_root / 'localization_data/extracted_strings.json'
    string_mapping_path = project_root / 'localization_data/string_mapping.json'

    # 加载现有的 Localizable.xcstrings
    print("📖 读取 Localizable.xcstrings...")
    localizable_data = load_json(localizable_path)

    # 加载提取的字符串
    print("📖 读取提取的字符串...")
    extracted_data = load_json(extracted_path)
    string_mapping = load_json(string_mapping_path)

    # 合并
    print("🔀 合并字符串...")
    existing_strings = localizable_data.get('strings', {})
    new_strings = extracted_data.get('strings', {})

    added_count = 0
    updated_count = 0

    for key, value_data in new_strings.items():
        if key not in existing_strings:
            existing_strings[key] = value_data
            added_count += 1
        else:
            # 字符串已存在，更新 comment
            if 'comment' in value_data:
                existing_strings[key]['comment'] = value_data['comment']
            updated_count += 1

    localizable_data['strings'] = existing_strings

    # 保存备份
    backup_path = localizable_path.with_suffix('.xcstrings.backup')
    print(f"💾 创建备份: {backup_path}")
    save_json(localizable_data, backup_path)

    # 保存更新后的文件
    print(f"💾 保存到: {localizable_path}")
    save_json(localizable_data, localizable_path)

    print("\n" + "="*50)
    print("✅ 合并完成!")
    print("="*50)
    print(f"新增字符串: {added_count}")
    print(f"更新字符串: {updated_count}")
    print(f"总字符串数: {len(existing_strings)}")

    # 生成简化的中英文对照表
    print("\n生成中英文对照表...")
    reference_file = project_root / 'localization_data/translation_reference.txt'
    with open(reference_file, 'w', encoding='utf-8') as f:
        f.write("# MiniCal 本地化参考\n\n")
        f.write("## 需要翻译的字符串（按键排序）\n\n")

        for orig_text, mapping in sorted(string_mapping.items()):
            key = mapping['key']
            f.write(f"### {key}\n")
            f.write(f"**原文（中文）:** {orig_text}\n")
            f.write(f"**英文翻译:** _TODO_\n")
            f.write(f"**使用次数:** {len(mapping['occurrences'])}\n")
            f.write("\n---\n\n")

    print(f"📄 翻译参考已保存到: {reference_file}")

if __name__ == '__main__':
    merge_localizations()
