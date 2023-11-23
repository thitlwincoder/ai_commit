import 'package:ai_commit/src/utils/utils.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';

Future<String> createChatCompletion({
  required Logger logger,
  required String apiKey,
  required Map<String, dynamic> data,
}) async {
  final uri = Uri.https(
    'api.openai.com',
    '/v1/chat/completions',
    {'authorization': 'Bearer $apiKey'},
  );

  final r = await http.post(uri, body: data);

  final statusCode = r.statusCode;

  if (statusCode < 200 || statusCode > 299) {
    var errorMessage = 'OpenAI API Error: $statusCode\n\n${r.body}';

    if (statusCode == 500) {
      errorMessage += '\n\nCheck the API status: https://status.openai.com';
    }

    logger.info(errorMessage);
    return '';
  }

  return r.body;
}

String sanitizeMessage(String message) {
  return message.trim().replaceAll('[\n\r]', '').replaceAll(r'(\w)\.$', r'\$1');
}

List<String> deduplicateMessages(List<String> messages) {
  return List.from(messages.toSet());
}

Future<List<String>> generateCommitMessage({
  required String apiKey,
  required String? locale,
  required String diff,
  required int completions,
  required int maxLength,
  required bool isConventional,
  required Logger logger,
  required String? model,
}) async {
  model ??= 'gpt-3.5-turbo-1106';

  try {
    OpenAI.apiKey = apiKey;
    final completion = await OpenAI.instance.chat.create(
      topP: 1,
      model: model,
      maxTokens: 200,
      n: completions,
      temperature: .7,
      presencePenalty: 0,
      frequencyPenalty: 0,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              generatePrompt(
                locale: locale,
                maxLength: maxLength,
                isConventional: isConventional,
              ),
            ),
          ],
        ),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(diff),
          ],
        ),
      ],
    );

    final contents = <OpenAIChatCompletionChoiceMessageContentItemModel>[];

    for (final choice in completion.choices) {
      final content = choice.message.content;
      if (content != null) contents.addAll(content);
    }

    final messages = <String>[];

    for (final content in contents) {
      final text = content.text;

      if (text != null) messages.add(sanitizeMessage(text));
    }

    return deduplicateMessages(messages);
  } catch (e) {
    throw KnownError(e);
  }
}
