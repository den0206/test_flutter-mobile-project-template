#!/usr/bin/env dart
/// GitHub Actions Matrix Strategy用のJSON生成スクリプト
///
/// .github/initialization ディレクトリ内のマークダウンファイルを読み取り、
/// peter-evans/create-issue-from-file で使用するMatrix JSONを生成します。

library;

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

/// マークダウンファイルのYAML Front Matterで期待される型
class FileMetadata { // String または List<String>

  FileMetadata({required this.title, required this.labels});

  factory FileMetadata.fromYaml(YamlMap yaml) {
    return FileMetadata(
      title: yaml['title'] as String,
      labels: yaml['labels'],
    );
  }
  final String title;
  final dynamic labels;
}

/// Matrix Strategy用のデータ
class MatrixItem {

  MatrixItem({
    required this.title,
    required this.contentFilepath,
    required this.labels,
  });
  final String title;
  final String contentFilepath;
  final dynamic labels;

  Map<String, dynamic> toJson() {
    // labelsが配列の場合は改行区切りの文字列に変換
    String labelsString;
    if (labels is List) {
      labelsString = (labels as List).join('\n');
    } else {
      labelsString = labels.toString();
    }

    return {
      'title': title,
      'content-filepath': contentFilepath,
      'labels': labelsString,
    };
  }
}

/// YAML Front Matterを解析してメタデータを抽出
FileMetadata? parseYamlFrontMatter(String content) {
  // YAML Front Matterの境界を検索
  final lines = content.split('\n');
  if (lines.isEmpty || lines[0] != '---') {
    return null;
  }

  var endIndex = -1;
  for (var i = 1; i < lines.length; i++) {
    if (lines[i] == '---') {
      endIndex = i;
      break;
    }
  }

  if (endIndex == -1) {
    return null;
  }

  // YAML部分を抽出
  final yamlContent = lines.sublist(1, endIndex).join('\n');

  try {
    final yamlMap = loadYaml(yamlContent) as YamlMap;
    return FileMetadata.fromYaml(yamlMap);
  } on YamlException catch (e) {
    stderr.writeln('Error parsing YAML: $e');
    return null;
  }
}

/// 初期化マークダウンファイルを読み取り、Matrix用データを生成
List<MatrixItem> readInitializationFiles(String initDir) {
  final items = <MatrixItem>[];
  final directory = Directory(initDir);

  if (!directory.existsSync()) {
    stderr.writeln('Error: Initialization directory not found: $initDir');
    exit(1);
  }

  // .mdファイルを取得（README.mdは除外）
  final files = directory
      .listSync()
      .whereType<File>()
      .where((file) =>
          file.path.endsWith('.md') &&
          !file.path.endsWith('README.md'),)
      .toList();

  for (final file in files) {
    try {
      final content = file.readAsStringSync();
      final metadata = parseYamlFrontMatter(content);

      if (metadata == null) {
        stderr.writeln('Warning: ${file.path} has no valid YAML front matter');
        continue;
      }

      // title と labels が必須
      if (metadata.title.isEmpty || metadata.labels == null) {
        stderr.writeln('''Warning: ${file.path} is missing required metadata (title or labels)''');
        continue;
      }

      final fileName = file.path.split('/').last;
      final relativePath = '.github/initialization/$fileName';

      items.add(MatrixItem(
        title: metadata.title,
        contentFilepath: relativePath,
        labels: metadata.labels,
      ),);
    } on FileSystemException catch (e) {
      stderr.writeln('Error processing ${file.path}: $e');
      continue;
    }
  }

  return items;
}

/// Matrix JSONを生成
Map<String, dynamic> generateMatrix(List<MatrixItem> items) {
  return {
    'include': items.map((item) => item.toJson()).toList(),
  };
}

void main() {
  const initDir = '.github/initialization';

  // 初期化ファイルを読み取り
  final items = readInitializationFiles(initDir);

  if (items.isEmpty) {
    stderr.writeln('No valid initialization files found');
    exit(1);
  }

  // Matrix JSONを生成
  final matrix = generateMatrix(items);

  // DOC: 確認用
  // ignore: avoid_print
  print(jsonEncode(matrix));
}
