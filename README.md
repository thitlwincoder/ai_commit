## ai_commit

[![pub package](https://img.shields.io/pub/v/ai_commit.svg?logo=dart&logoColor=00b9fc)](https://pub.dev/packages/ai_commit)
[![Last Commits](https://img.shields.io/github/last-commit/thitlwincoder/ai_commit?logo=git&logoColor=white)](https://github.com/thitlwincoder/ai_commit/commits/main)
[![GitHub repo size](https://img.shields.io/github/repo-size/thitlwincoder/ai_commit)](https://github.com/thitlwincoder/ai_commit)
[![License](https://img.shields.io/github/license/thitlwincoder/ai_commit?logo=open-source-initiative&logoColor=green)](https://github.com/thitlwincoder/ai_commit/blob/main/LICENSE)
<br>
[![Uploaded By](https://img.shields.io/badge/uploaded%20by-thitlwincoder-blue)](https://github.com/thitlwincoder)

Dart CLI for generated git commit messages with OpenAI.

---

## Quick Started 🚀

Installing

```sh
dart pub global activate ai_commit
```

Or install a [specific version](https://pub.dev/packages/ai_commit/versions) using:

```sh
dart pub global activate ai_commit <version>
```

## Commands

### `ai_commit -h`

See the complete list of commands and usage information.

```sh
Dart CLI for generated commit messages with OpenAI.

Usage: ai_commit <command> [arguments]

Global options:
-h, --help                 Print this usage information.
-a, --all                  Automatically stage changes in tracked files for the commit
-c, --count                Count of messages to generate (Warning: generating multiple costs more)
-m, --model                Locale language for commit message.
-x, --exclude              Files to exclude from AI analysis
-l, --max-length           Set max length of commit message.
    --locale               Locale language for commit message.
    --[no-]conventional    Format the commit message according to the Conventional Commits specification.
-v, --version              Print the current version.
    --[no-]verbose         Noisy logging, including all shell commands executed.

Available commands:
  config   ai_commit configuration
  update   Update the CLI.

Run "ai_commit help <command>" for more information about a command.
```

### `ai_commit config`

Save data configuration and use later.

```sh
ai_commit configuration

Usage: ai_commit config [arguments]
-h, --help                 Print this usage information.
    --key                  OpenAI API key.
    --locale               Set locale language.
    --count                Generate commit message count.
    --[no-]conventional    Format the commit message according to the Conventional Commits specification.
    --model                Set model name for OpenAI API.
    --max-length           Set max length of commit message.

Run "ai_commit help" to see global options.
```

## Usage

Before using you need to set OpenAI API key
```sh
ai_commit config --key sk-xxx
```

Generate commit message
```sh
ai_commit
```

Add all files and generate a commit message
```sh
ai_commit -a
```

Count of messages to generate **(Warning: generating multiple costs more)**
```sh
# one time use
ai_commit -c 2

# save data to config
ai_commit config -c 2
```

[OpenAI model](https://platform.openai.com/docs/models/overview) to use for generation
```sh
# one time use
ai_commit -m gpt-3.5-turbo-1106

# save data to config
ai_commit config -m gpt-3.5-turbo-1106
```

Files to exclude from AI analysis
```sh
# single
ai_commit -x test.dart

# multiple
ai_commit -x one.dart, two.dart
```

Max length of commit message
```sh
# one time use
ai_commit -l 200

# save data to config
ai_commit config -l 200
```

Locale language for commit message
```sh
# one time use
ai_commit --locale en

# save data to config
ai_commit config --locale en
```

Format the commit message according to the [Conventional Commits](https://www.conventionalcommits.org/en) specification.
```sh
# one time use
ai_commit --conventional

# save data to config
ai_commit config --conventional
```

Disable Conventional Commits Format
```sh
ai_commit --no-conventional

# save data to config
ai_commit config --no-conventional
```