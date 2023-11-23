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
        'proxy',
        help: 'Set proxy server for OpenAI API.',
      )
      ..addOption(
        'model',
        help: 'Set model name for OpenAI API.',
      )
      ..addOption(
        'timeout',
        help: 'Set timeout in milliseconds.',
      )
      ..addOption(
        'max-length',
        help: 'Set max length of commit message.',
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

    // get `conventional` value from args and store

    if (argResults?.wasParsed('conventional') ?? false) {
      final conventional = argResults?['conventional'];

      if (conventional != null) {
        await setConventional(value: conventional as bool);
        _logger.success('Setting "conventional" to "$conventional".');
        return ExitCode.software.code;
      }
    }

    // get `proxy` value from args
    // check valid URL and store

    final proxy = argResults?['proxy'];

    if (proxy != null) {
      if (Uri.tryParse('$proxy')?.isAbsolute ?? false) {
        _logger.success('Setting "proxy" to "$proxy".');
        await setProxy('$proxy');
      } else {
        _logger.err('Proxy must be valid URL.');
        return ExitCode.software.code;
      }
    }

    // get `model` value from args
    // check isNotEmpty and store

    final model = argResults?['model'];

    if (model != null) {
      if (model is String && model.isNotEmpty) {
        _logger.success('Setting "model" to "$model".');
        await setModel(model);
      } else {
        _logger.err('Model must be a string.');
        return ExitCode.software.code;
      }
    }

    // get `timeout` value from args
    // check greater than 500ms and store

    final timeout = argResults?['timeout'];

    if (timeout != null) {
      if (int.tryParse('$timeout') != null) {
        final value = int.parse('$timeout');
        if (value > 500) {
          _logger.success('Setting "timeout" to "$value".');
          await setProxy('$value');
        } else {
          _logger.err('Timeout must be an greater than 500ms.');
          return ExitCode.software.code;
        }
      }
    }

    // get `max-length` value from args
    // check greater than 20 and store

    final maxLength = argResults?['max-length'];

    if (maxLength != null) {
      if (int.tryParse('$maxLength') != null) {
        final value = int.parse('$maxLength');
        if (value > 20) {
          _logger.success('Setting "max-length" to "$value".');
          await setProxy('$value');
        } else {
          _logger.err('Max length must be an greater than 20.');
          return ExitCode.software.code;
        }
      } else {
        _logger.err('Max length must be an integer.');
        return ExitCode.software.code;
      }
    }

    return ExitCode.software.code;
  }
}
