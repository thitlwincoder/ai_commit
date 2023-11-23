import 'dart:io';

String assetGitRepo() {
  final result = Process.runSync('git', ['rev-parse', '--show-toplevel']);
  return result.stdout.toString();
}

String excludeFromDiff(String path) => ':(exclude)$path';

Future<Map<String, dynamic>> getStagedDiff({
  List<String>? excludeFiles,
}) async {
  // read .gitignore file from project path
  // remove comments and empty lines

  final gitignoreFiles = <String>[];

  final gitignore = File('.gitignore');
  if (gitignore.existsSync()) {
    gitignore.readAsLinesSync().forEach((line) {
      if (!line.startsWith('#') && line.isNotEmpty) {
        gitignoreFiles.add(excludeFromDiff(line));
      }
    });
  }

  final diffCached = ['diff', '--cached', '--diff-algorithm=minimal'];

  var result = await Process.run(
    'git',
    [
      ...diffCached,
      '--name-only',
      ...gitignoreFiles,
      if (excludeFiles != null) ...excludeFiles.map(excludeFromDiff),
    ],
  );

  final files = result.stdout.toString();

  if (files.isEmpty) return {};

  result = await Process.run(
    'git',
    [
      ...diffCached,
      ...gitignoreFiles,
      if (excludeFiles != null) ...excludeFiles.map(excludeFromDiff),
    ],
  );

  final diff = result.stdout.toString();

  return {'files': files.split('\n'), 'diff': diff};
}

String getDetectedMessage({List<String>? files}) {
  files ??= [];

  return 'Detected ${files.length} staged file${files.length == 1 ? '' : 's'}';
}
