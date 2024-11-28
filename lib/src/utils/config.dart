import 'package:hive/hive.dart';

String defaultModel = 'gpt-3.5-turbo-1106';
int defaultMaxLength = 20;

// store data in hive box
Future<void> setData(String key, dynamic value) async {
  final box = await Hive.openBox<dynamic>('ai_commit_config');
  await box.put(key, value);
}

// get data from hive box
Future<dynamic> getData(String key, [dynamic defaultValue]) async {
  final box = await Hive.openBox<dynamic>('ai_commit_config');
  return box.get(key) ?? defaultValue;
}

Future<void> clearData() async {
  final box = await Hive.openBox<dynamic>('ai_commit_config');
  await box.clear();
}

// store openai api key
Future<void> setKey(String value) async {
  await setData('api_key', value);
}

// get openai api key
Future<String?> getKey() async {
  final value = await getData('api_key');
  return value as String?;
}

// store locale language
Future<void> setLocale(String value) async {
  await setData('locale', value);
}

// get locale language
Future<String?> getLocale() async {
  final value = await getData('locale');
  return value as String?;
}

// store generate commit message count
Future<void> setCount(int value) async {
  await setData('generate_count', value);
}

// get generate commit message count
Future<int> getCount() async {
  final value = await getData('generate_count', 1);
  return value as int;
}

// store is_conventional value
Future<void> setConventional({required bool value}) async {
  await setData('is_conventional', value);
}

// get is_conventional value
Future<bool> getConventional() async {
  final value = await getData('is_conventional', false);
  return value as bool;
}

// store model name
Future<void> setModel(String value) async {
  await setData('model', value);
}

// get model name
Future<String> getModel() async {
  final value = await getData('model', defaultModel);
  return value as String;
}

// store max length
Future<void> setMaxLength(int value) async {
  await setData('max_length', value);
}

// get max length
Future<int> getMaxLength() async {
  final value = await getData('max_length', defaultMaxLength);
  return value as int;
}
