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
const description = 'Dart CLI for generate commit messages with OpenAI.';

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
        'exclude',
        abbr: 'x',
        help: 'Files to exclude from AI analysis',
      )
      ..addOption(
        'count',
        abbr: 'c',
        help: '''
Count of messages to generate (Warning: generating multiple costs more)''',
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
        ..err(e.message)..err('$stackTrace')
        ..info('')..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      // On usage errors, show the commands usage message and
      // exit with an error code
      _logger
        ..err(e.message)
        ..info('')..info(e.usage);
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
    _logger..detail('Argument information:')..detail('  Top level options:');
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
        exclude: topLevelResults['exclude'],
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
  }) async {
    try {
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
        excludeFiles = [
          for (final e in exclude.toString().split(',')) e.trim()
        ];
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

      detectingFiles.complete(
        '$message:\n${files.map((e) => '     $e').join('\n')}',
      );

      final s = _logger.progress('The AI is analyzing your changes');

      var messages = <String>[];

      final locale = await getLocale();
      final maxLength = await getMaxLength();

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

      messages = await generateCommitMessage(
        apiKey: apiKey,
        locale: locale,
        logger: _logger,
        maxLength: maxLength,
        completions: completions,
        diff: staged['diff'] as String,
        isConventional: isConventional,
      );

      s.fail('Changes analyzed');

      if (messages.isEmpty) {
        _logger.info('No commit messages were generated. Try again.');
        return ExitCode.success.code;
      }

      if (messages.length == 1) {
        message = messages.first;

        final confirmed =
            _logger.confirm('Use this commit message?\n\n   $message\n');

        if (!confirmed) {
          _logger.info('Commit message canceled.');
          return ExitCode.software.code;
        }
      } else {
        final selected = _logger.chooseOne(
          'Pick a commit message to use: ',
          choices: messages,
        );

        if (selected.isEmpty) {
          _logger.info('Commit message canceled.');
          return ExitCode.software.code;
        }

        message = selected;
      }

      await Process.run('git', ['commit', '-m', message]);

      s.complete('Successfully committed');

      return ExitCode.success.code;
    } catch (e) {
      print(e.runtimeType);
      print(e);
      exit(0);
    }
  }
}
