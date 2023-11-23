import 'dart:convert';

String get conventionalPrompt {
  var map = {
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
Choose a type from the type-to-description JSON below that best describes the git diff:
${jsonEncode(map)}''';
}

String specifyCommitFormat =
    'The output response must be in format:\n $conventionalPrompt';

String generatePrompt({
  required String? locale,
  required int maxLength,
  required bool isConventional,
}) {
  final msgs = [
    '''
Generate a concise git commit message written in present tense for the following code diff with the given specifications below:''',
    if (locale != null) 'Message language: $locale',
    'Commit message must be a maximum of $maxLength characters.',
    '''
Exclude anything unnecessary such as translation. Your entire response will be passed directly into git commit.''',
    if (isConventional) ...[conventionalPrompt, specifyCommitFormat],
  ];

  return msgs.join('\n');
}
