import 'package:ai_commit/src/command_runner.dart';
import 'package:ai_commit/src/version.dart';
import 'package:mason_logger/mason_logger.dart';

class KnownError extends Error {
  final Object? message;

  KnownError([this.message]);

  @override
  String toString() {
    Logger()
      ..err(message.toString())
      ..err('\n$packageName v$packageVersion')
      ..err('\nPlease open a Bug report with the information above:')
      ..err('https://github.com/thitlwincoder/ai_commit/issues/new/choose');

    return '';
  }
}
