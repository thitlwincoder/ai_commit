## ai_commit

![coverage][coverage_badge]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

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
-x, --exclude              Files to exclude from AI analysis
-c, --count                Count of messages to generate (Warning: generating multiple costs more)
    --[no-]conventional    Format the commit message according to the Conventional Commits specification.
-v, --version              Print the current version.
    --[no-]verbose         Noisy logging, including all shell commands executed.

Available commands:
  config   ai_commit configuration
  update   Update the CLI.

Run "ai_commit help <command>" for more information about a command.
```
## Usage

Generate commit message
```sh
ai_commit
```

Add all files and generate a commit message
```sh
ai_commit -a
```

Files to exclude from AI analysis
```sh
# single
ai_commit -x test.dart

# multiple
ai_commit -x one.dart, two.dart
```

Count of messages to generate **(Warning: generating multiple costs more)**
```sh
ai_commit -c 2
```

Format the commit message according to the [Conventional Commits](https://www.conventionalcommits.org/) specification.
```sh
ai_commit --conventional
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

Set OpenAI API key
```sh
ai_commit config --key sk-xxx
```

Set locale language
```sh
ai_commit config --locale en-US
```


Generate commit message count
```sh
ai_commit config --count 1
```

Format the commit message according to the [Conventional Commits](https://www.conventionalcommits.org/) specification.
```sh
ai_commit config --conventional
```

 Set [model name](https://platform.openai.com/docs/models/overview) for OpenAI API
```sh
ai_commit config --model gpt-3.5-turbo-1106
```

Set max length of commit message
```sh
ai_commit config --max-length 200
```