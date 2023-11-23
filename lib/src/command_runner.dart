import 'dart:io';

import 'package:ai_commit/src/commands/commands.dart';
import 'package:ai_commit/src/utils/utils.dart';
import 'package:ai_commit/src/version.dart';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:hive/hive.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

const executableName = 'ai_commit';
const packageName = 'ai_commit';
const description = 'Dart CLI for generated commit messages with OpenAI.';

/// {@template ai_commit_command_runner}
/// A [CommandRunner] for the CLI.
///
/// ```
/// $ ai_commit --version
/// ```
/// {@endtemplate}
class AiCommitCommandRunner extends CompletionCommandRunner<int> {
  /// {@macro ai_commit_command_runner}
  AiCommitCommandRunner({
    Logger? logger,
    PubUpdater? pubUpdater,
  })  : _logger = logger ?? Logger(),
        _pubUpdater = pubUpdater ?? PubUpdater(),
        super(executableName, description) {
    // Add root options and flags
    argParser
      ..addFlag(
        'all',
        abbr: 'a',
        negatable: false,
        help: 'Automatically stage changes in tracked files for the commit',
      )
      ..addOption(
        'count',
        abbr: 'c',
        help: '''
Count of messages to generate (Warning: generating multiple costs more)''',
      )
      ..addOption(
        'model',
        abbr: 'm',
        help: 'Locale language for commit message.',
      )
      ..addOption(
        'exclude',
        abbr: 'x',
        help: 'Files to exclude from AI analysis',
      )
      ..addOption(
        'max-length',
        abbr: 'l',
        help: 'Set max length of commit message.',
      )
      ..addOption(
        'locale',
        help: 'Locale language for commit message.',
      )
      ..addFlag(
        'conventional',
        help: '''
Format the commit message according to the Conventional Commits specification.''',
      )
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: 'Print the current version.',
      )
      ..addFlag(
        'verbose',
        help: 'Noisy logging, including all shell commands executed.',
      );

    // Add sub commands
    addCommand(ConfigCommand(logger: _logger));
    addCommand(UpdateCommand(logger: _logger, pubUpdater: _pubUpdater));
  }

  @override
  void printUsage() => _logger.info(usage);

  final Logger _logger;
  final PubUpdater _pubUpdater;

  @override
  Future<int> run(Iterable<String> args) async {
    final gitRepoPath = assetGitRepo();
    if (gitRepoPath.isEmpty) {
      _logger.info('The current directory must be a git repository.');
      return ExitCode.software.code;
    }

    String? home;

    final envVars = Platform.environment;
    if (Platform.isWindows) {
      home = envVars['UserProfile'];
    } else {
      home = envVars['HOME'];
    }

    final path = [home ?? '', '.ai_commit'].join(Platform.pathSeparator);

    Hive.init(path);

    try {
      final topLevelResults = parse(args);
      if (topLevelResults['verbose'] == true) {
        _logger.level = Level.verbose;
      }
      return await runCommand(topLevelResults) ?? ExitCode.success.code;
    } on FormatException catch (e, stackTrace) {
      // On format errors, show the commands error message, root usage and
      // exit with an error code
      _logger
        ..err(e.message)
        ..err('$stackTrace')
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      // On usage errors, show the commands usage message and
      // exit with an error code
      _logger
        ..err(e.message)
        ..info('')
        ..info(e.usage);
      return ExitCode.usage.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    // Fast track completion command
    if (topLevelResults.command?.name == 'completion') {
      await super.runCommand(topLevelResults);
      return ExitCode.success.code;
    }

    // Verbose logs
    _logger
      ..detail('Argument information:')
      ..detail('  Top level options:');
    for (final option in topLevelResults.options) {
      if (topLevelResults.wasParsed(option)) {
        _logger.detail('  - $option: ${topLevelResults[option]}');
      }
    }
    if (topLevelResults.command != null) {
      final commandResult = topLevelResults.command!;
      _logger
        ..detail('  Command: ${commandResult.name}')
        ..detail('    Command options:');
      for (final option in commandResult.options) {
        if (commandResult.wasParsed(option)) {
          _logger.detail('    - $option: ${commandResult[option]}');
        }
      }

      if (commandResult.command != null) {
        final subCommandResult = commandResult.command!;
        _logger.detail('    Command sub command: ${subCommandResult.name}');
      }
    }

    // Run the command or show version
    final int? exitCode;
    if (topLevelResults['version'] == true) {
      _logger.info(packageVersion);
      exitCode = ExitCode.success.code;
    } else if (topLevelResults.command?.name == ConfigCommand.commandName ||
        topLevelResults['help'] == true) {
      exitCode = await super.runCommand(topLevelResults);
    } else {
      exitCode = await _startWork(
        all: topLevelResults.wasParsed('all') ? topLevelResults['all'] : null,
        count: topLevelResults['count'],
        model: topLevelResults['model'],
        locale: topLevelResults['locale'],
        exclude: topLevelResults['exclude'],
        maxLength: topLevelResults['max-length'],
        conventional: topLevelResults.wasParsed('conventional')
            ? topLevelResults['conventional']
            : null,
      );
    }

    // Check for updates
    if (topLevelResults.command?.name != UpdateCommand.commandName) {
      await _checkForUpdates();
    }

    return exitCode;
  }

  /// Checks if the current version (set by the build runner on the
  /// version.dart file) is the most recent one. If not, show a prompt to the
  /// user.
  Future<void> _checkForUpdates() async {
    try {
      final latestVersion = await _pubUpdater.getLatestVersion(packageName);
      final isUpToDate = packageVersion == latestVersion;
      if (!isUpToDate) {
        _logger
          ..info('')
          ..info(
            '''
${lightYellow.wrap('Update available!')} ${lightCyan.wrap(packageVersion)} \u2192 ${lightCyan.wrap(latestVersion)}
Run ${lightCyan.wrap('$executableName update')} to update''',
          );
      }
    } catch (_) {}
  }

  Future<int> _startWork({
    required dynamic all,
    required dynamic count,
    required dynamic exclude,
    required dynamic conventional,
    required dynamic model,
    required dynamic locale,
    required dynamic maxLength,
  }) async {
    final apiKey = await getKey();
    if (apiKey == null) {
      _logger.info(
        '''No API key found. To generate one, run ${lightCyan.wrap('$executableName config')}''',
      );
      return ExitCode.software.code;
    }

    if (all == true) await Process.run('git', ['add', '--update']);

    int? msgCount;

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

      msgCount = value;
    }

    var excludeFiles = <String>[];

    if (exclude != null) {
      excludeFiles = [for (final e in exclude.toString().split(',')) e.trim()];
    }

    final detectingFiles = _logger.progress('Detecting staged files');

    final staged = await getStagedDiff(excludeFiles: excludeFiles);

    if (staged.isEmpty) {
      detectingFiles.complete('Detecting staged files');
      _logger.info(
        '''
No staged changes found. Stage your changes manually, or automatically stage all changes with the `--all` options.''',
      );
      return ExitCode.success.code;
    }

    final files = staged['files'] as List<String>? ?? [];

    var message = getDetectedMessage(files: files);

    detectingFiles.complete(message);
    _logger.info(files.map((e) => '     $e').join('\n'));

    final s = _logger.progress('The AI is analyzing your changes');

    var messages = <String>[];

    try {

      var completions = 1;

      if (msgCount != null) {
        completions = msgCount;
      } else {
        completions = await getCount();
      }

      var isConventional = false;

      if (conventional != null) {
        isConventional = conventional as bool;
      } else {
        isConventional = await getConventional();
      }

      String? aiModel;

      if (model != null) {
        aiModel = model as String;
      } else {
        aiModel = await getModel();
      }

      int maxLength0;

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

        maxLength0 = value;
      } else {
        maxLength0 = await getMaxLength();
      }

      String? locale0;

      if (locale != null) {
        locale0 = locale as String;
      } else {
        locale0 = await getLocale();
      }

      messages = await generateCommitMessage(
        apiKey: apiKey,
        locale: locale0,
        model: aiModel,
        logger: _logger,
        maxLength: maxLength0,
        completions: completions,
        diff: staged['diff'] as String,
        isConventional: isConventional,
      );
    } finally {
      s.complete('Changes analyzed');
    }

    if (messages.isEmpty) {
      _logger.info('No commit messages were generated. Try again.');
      return ExitCode.success.code;
    }

    if (messages.length == 1) {
      message = messages.first;

      final confirmed =
          _logger.confirm('\nUse this commit message?\n\n   $message\n\n');

      if (!confirmed) {
        s.fail('Commit message canceled.');
        return ExitCode.software.code;
      }
    } else {
      final selected = _logger.chooseOne(
        'Pick a commit message to use: ',
        choices: messages,
      );

      message = selected;
    }

    await Process.run('git', ['commit', '-m', message]);

    s.complete('Successfully committed');

    return ExitCode.success.code;
  }
}
