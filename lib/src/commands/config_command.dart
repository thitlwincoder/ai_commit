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
      )
      ..addOption(
        'model',
        help: 'Set model name for OpenAI API.',
      )
      ..addOption(
        'max-length',
        help: 'Set max length of commit message.',
      );
  }

  @override
  String get description => 'ai_commit configuration';

  static const String commandName = 'config';

  @override
  String get name => 'config';

  final Logger _logger;

  @override
  Future<int> run() async {
    final arguments = argResults?.arguments ?? [];

    // check `arguments` is empty
    // show `usage` and return

    if (arguments.isEmpty) {
      _logger.info(usage);
      return ExitCode.software.code;
    }

    // get `key` value from args
    // check value is start with "sk-" and store

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

    // get `locale` value from args
    // check valid language code and store

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

    // get `count` value from args
    // check value is greater than 0 and less than or equal to 5 and store

    final count = argResults?['count'];

    if (count != null) {
      final value = int.tryParse('$count');

      if (value == null) {
        _logger.err('Count must be an integer.');
        return ExitCode.software.code;
      }

      if (value < 0) {
        _logger.err('Count must be an greater than 0.');
        return ExitCode.software.code;
      }

      if (value > 5) {
        _logger.err('Count must be less than or equal to 5.');
        return ExitCode.software.code;
      }

      _logger.success('Setting "count" to "$count".');
      await setCount(value);
    }

    // get `conventional` value from args and store

    if (argResults?.wasParsed('conventional') ?? false) {
      final conventional = argResults?['conventional'];

      if (conventional != null) {
        await setConventional(value: conventional as bool);
        _logger.success('Setting "conventional" to "$conventional".');
        return ExitCode.software.code;
      }
    }

    // get `model` value from args
    // check isNotEmpty and store

    final model = argResults?['model'];

    if (model != null) {
      if ('$model'.isEmpty) {
        _logger.err('Model must be a string.');
        return ExitCode.software.code;
      }

      _logger.success('Setting "model" to "$model".');
      await setModel('$model');
    }

    // get `max-length` value from args
    // check greater than 20 and store

    final maxLength = argResults?['max-length'];

    if (maxLength != null) {
      final value = int.tryParse('$maxLength');

      if (value == null) {
        _logger.err('Max length must be an integer.');
        return ExitCode.software.code;
      }

      if (value < 20) {
        _logger.err('Max length must be an greater than 20.');
        return ExitCode.software.code;
      }

      _logger.success('Setting "max-length" to "$value".');
      await setMaxLength(value);
    }

    return ExitCode.software.code;
  }
}
