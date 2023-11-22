import 'package:ai_commit/src/utils/utils.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

class ConfigCommand extends Command<int> {
  ConfigCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addOption(
        'key',
        help: 'OpenAI API key.',
      )
      ..addOption(
        'locale',
        help: 'Set locale language.',
      )
      ..addOption(
        'count',
        help: 'Generate commit message count.',
      )
      ..addFlag(
        'conventional',
        help: '''
Format the commit message according to the Conventional Commits specification.''',
      );
  }

  @override
  String get description => 'ai_commit configuration';

  @override
  String get name => 'config';

  final Logger _logger;

  @override
  Future<int> run() async {
    final arguments = argResults?.arguments ?? [];

    if (arguments.isEmpty) {
      usageException('Missing argument for "config".');
    }

    final key = argResults?['key'];

    if (key != null) {
      if (key is String && key.startsWith('sk-')) {
        _logger.success('Add "key" successfully.');
        await setKey(key);
      } else {
        _logger.err('Key must start with "sk-".');
        return ExitCode.software.code;
      }
    }

    final locale = argResults?['locale'];

    if (locale != null) {
      if (locale is String && RegExp('^[a-z-]+').hasMatch(locale)) {
        _logger.success('Setting "locale" to "$locale".');
        await setLocale(locale);
      } else {
        _logger.err(
          'Locale must be a valid language code (letters and dashes/underscores).',
        );
        return ExitCode.software.code;
      }
    }

    final count = argResults?['count'];

    if (count != null) {
      if (int.tryParse('$count') != null) {
        final value = int.parse('$count');
        if (value < 0) {
          _logger.err('Count must be an greater than 0.');
          return ExitCode.software.code;
        }

        if (value > 5) {
          _logger.err('Count must be less than or equal to 5.');
          return ExitCode.software.code;
        }

        _logger.success('Setting "count" to "$value".');
        await setCount(value);
      } else {
        _logger.err('Count must be an integer.');
        return ExitCode.software.code;
      }
    }

    if (argResults?.wasParsed('conventional') ?? false) {
      final conventional = argResults?['conventional'];

      if (conventional != null) {
        await setConventional(value: conventional as bool);
        _logger.success('Setting "conventional" to "$conventional".');
        return ExitCode.software.code;
      }
    }

    return ExitCode.software.code;
  }
}
