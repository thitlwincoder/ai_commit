import 'dart:convert';

String get conventionalPrompt {
  final map = {
    'docs': 'Documentation only changes',
    'style': '''
Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)''',
    'refactor': 'A code change that neither fixes a bug nor adds a feature',
    'perf': 'A code change that improves performance',
    'test': 'Adding missing tests or correcting existing tests',
    'build': 'Changes that affect the build system or external dependencies',
    'ci': 'Changes to our CI configuration files and scripts',
    'chore': "Other changes that don't modify src or test files",
    'revert': 'Reverts a previous commit',
    'feat': 'A new feature',
    'fix': 'A bug fix',
  };

  return '''
Select a type from the JSON below that best matches the git diff:
${jsonEncode(map)}''';
}

String specifyCommitFormat =
    'The output response must be in format:\n $conventionalPrompt';

String generatePrompt({
  required String? locale,
  required int maxLength,
  required bool isConventional,
  required bool isBreaking,
}) {
  final msgs = [
    '''
Generate a concise Git commit message in present tense for the following code diff, adhering to the specifications below:''',
    if (locale != null) 'Message language: $locale',
    'Commit message: Maximum $maxLength characters',
    if (isBreaking)
      '''prepend BREAKING CHANGE: to the message and append ! to the type (e.g., feat!, fix!).''',
    '''Exclude unnecessary details, ensuring the message is directly usable in a git commit.''',
    if (isConventional) ...[conventionalPrompt, specifyCommitFormat],
  ];

  return msgs.join('\n');
}
