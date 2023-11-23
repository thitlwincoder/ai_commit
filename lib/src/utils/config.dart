import 'package:hive/hive.dart';

// store data in hive box
Future<void> setData(String key, dynamic value) async {
  final box = await Hive.openBox<dynamic>('ai_commit_config');
  await box.put(key, value);
}

// store openai api key
Future<void> setKey(String value) async {
  await setData('api_key', value);
}

// store locale language
Future<void> setLocale(String value) async {
  await setData('locale', value);
}

// store generate commit message count
Future<void> setCount(int value) async {
  await setData('generate_count', value);
}

// store is_conventional value
Future<void> setConventional({required bool value}) async {
  await setData('is_conventional', value);
}

// store proxy server address
Future<void> setProxy(String value) async {
  await setData('proxy', value);
}

// store model name
Future<void> setModel(String value) async {
  await setData('model', value);
}

// store timeout value
Future<void> setTimeout(int value) async {
  await setData('timeout', value);
}

void getConfig() {
  final config = Hive.box<Map<String, dynamic>>('ai_commit_config');

  for (var key in config.keys) {}
}
