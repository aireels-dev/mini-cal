#!/usr/bin/env python3
"""
提取 Swift 代码中的硬编码字符串，生成本地化配置
"""

import re
import json
import os
from pathlib import Path
from collections import defaultdict

def extract_strings_from_swift(file_path):
    """从 Swift 文件中提取字符串"""
    strings = []

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 匹配 Text("...") 格式
    text_pattern = r'Text\("([^"\\]*(\\.[^"\\]*)*)"\)'
    for match in re.finditer(text_pattern, content):
        string_value = match.group(1)
        # 跳过变量插值和特殊字符
        if '\\(' not in string_value and len(string_value.strip()) > 0:
            strings.append({
                'value': string_value,
                'file': file_path,
                'type': 'Text'
            })

    # 匹配 Label("...", ...) 格式
    label_pattern = r'Label\("([^"\\]*(\\.[^"\\]*)*)"\s*,'
    for match in re.finditer(label_pattern, content):
        string_value = match.group(1)
        if '\\(' not in string_value and len(string_value.strip()) > 0:
            strings.append({
                'value': string_value,
                'file': file_path,
                'type': 'Label'
            })

    # 匹配 Section("...") 格式
    section_pattern = r'Section\("([^"\\]*(\\.[^"\\]*)*)"\)'
    for match in re.finditer(section_pattern, content):
        string_value = match.group(1)
        if '\\(' not in string_value and len(string_value.strip()) > 0:
            strings.append({
                'value': string_value,
                'file': file_path,
                'type': 'Section'
            })

    return strings

def scan_directory(directory):
    """扫描目录中的所有 Swift 文件"""
    all_strings = []
    swift_files = Path(directory).rglob('*.swift')

    for swift_file in swift_files:
        # 跳过测试文件和一些特殊文件
        if 'Test' in str(swift_file) or 'Preview' in str(swift_file):
            continue

        try:
            strings = extract_strings_from_swift(str(swift_file))
            all_strings.extend(strings)
        except Exception as e:
            print(f"Error processing {swift_file}: {e}")

    return all_strings

def generate_localization_keys(strings):
    """为字符串生成本地化键"""
    key_map = {}
    key_counts = defaultdict(int)

    for item in strings:
        value = item['value']

        # 生成一个基础 key（使用拼音或简化的英文）
        # 对于这个例子，我们使用简化的方式
        if is_chinese(value):
            # 中文字符串：使用前缀 + 数字
            base_key = f"ui_{len(key_counts)}"
        else:
            # 英文字符串：使用小写 + 下划线
            base_key = value.lower().replace(' ', '_').replace('-', '_')
            base_key = re.sub(r'[^a-z0-9_]', '', base_key)
            base_key = base_key[:50]  # 限制长度

        # 确保唯一性
        if base_key in key_counts:
            key_counts[base_key] += 1
            key = f"{base_key}_{key_counts[base_key]}"
        else:
            key = base_key
            key_counts[base_key] = 0

        if value not in key_map:
            key_map[value] = {
                'key': key,
                'occurrences': []
            }

        key_map[value]['occurrences'].append({
            'file': item['file'],
            'type': item['type']
        })

    return key_map

def is_chinese(text):
    """检查文本是否包含中文字符"""
    return bool(re.search(r'[\u4e00-\u9fff]', text))

def generate_xcstrings_format(key_map, supported_locales):
    """生成 .xcstrings 格式的 JSON"""
    strings_dict = {}

    for value, data in key_map.items():
        key = data['key']

        # 检测源语言
        if is_chinese(value):
            source_lang = 'zh-Hans'
        else:
            source_lang = 'en'

        strings_dict[key] = {
            'comment': f'Used in {len(data["occurrences"])} place(s)',
            'extractionState': 'manual',
            'localizations': {}
        }

        # 添加所有支持的语言
        for locale in supported_locales:
            if locale == source_lang:
                strings_dict[key]['localizations'][locale] = {
                    'stringUnit': {
                        'state': 'translated',
                        'value': value
                    }
                }
            else:
                strings_dict[key]['localizations'][locale] = {
                    'stringUnit': {
                        'state': 'needs_translation',
                        'value': value  # 暂时使用源文本
                    }
                }

    return {
        'sourceLanguage': 'zh-Hans',
        'strings': strings_dict,
        'version': '1.0'
    }

def main():
    # 配置
    project_dir = Path(__file__).parent.parent / 'MiniCal'
    views_dir = project_dir / 'Views'
    output_dir = Path(__file__).parent.parent / 'localization_data'
    output_dir.mkdir(exist_ok=True)

    supported_locales = [
        'zh-Hans', 'zh-Hant', 'en', 'ar', 'he',
        'ja', 'ko', 'vi', 'fa', 'th', 'tr', 'ur'
    ]

    print("🔍 扫描 Swift 文件...")
    all_strings = scan_directory(views_dir)
    print(f"✅ 找到 {len(all_strings)} 个字符串实例")

    print("\n🔑 生成本地化键...")
    key_map = generate_localization_keys(all_strings)
    print(f"✅ 生成 {len(key_map)} 个唯一字符串")

    # 保存字符串映射
    mapping_file = output_dir / 'string_mapping.json'
    with open(mapping_file, 'w', encoding='utf-8') as f:
        json.dump(key_map, f, ensure_ascii=False, indent=2)
    print(f"\n📄 字符串映射已保存到: {mapping_file}")

    # 生成 xcstrings 格式（部分）
    xcstrings_data = generate_xcstrings_format(key_map, supported_locales)
    xcstrings_file = output_dir / 'extracted_strings.json'
    with open(xcstrings_file, 'w', encoding='utf-8') as f:
        json.dump(xcstrings_data, f, ensure_ascii=False, indent=2)
    print(f"📄 xcstrings 数据已保存到: {xcstrings_file}")

    # 生成替换脚本
    print("\n📝 生成替换建议...")
    replacement_suggestions = []
    for value, data in key_map.items():
        key = data['key']
        for occ in data['occurrences']:
            suggestion = {
                'file': occ['file'],
                'original': f'{occ["type"]}("{value}")',
                'replacement': f'{occ["type"]}(L("{key}"))',
                'key': key,
                'value': value
            }
            replacement_suggestions.append(suggestion)

    suggestions_file = output_dir / 'replacement_suggestions.json'
    with open(suggestions_file, 'w', encoding='utf-8') as f:
        json.dump(replacement_suggestions, f, ensure_ascii=False, indent=2)
    print(f"📄 替换建议已保存到: {suggestions_file}")

    # 统计报告
    print("\n" + "="*50)
    print("📊 统计报告")
    print("="*50)
    print(f"总字符串数: {len(all_strings)}")
    print(f"唯一字符串数: {len(key_map)}")
    print(f"需要本地化的文件数: {len(set(s['file'] for s in all_strings))}")
    print("\n前10个最常用的字符串:")
    sorted_strings = sorted(key_map.items(),
                           key=lambda x: len(x[1]['occurrences']),
                           reverse=True)
    for i, (value, data) in enumerate(sorted_strings[:10], 1):
        print(f"{i}. \"{value}\" - 使用 {len(data['occurrences'])} 次")

if __name__ == '__main__':
    main()
