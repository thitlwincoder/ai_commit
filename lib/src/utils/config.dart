import 'package:hive/hive.dart';

Future<void> setData(String key, dynamic value) async {
  final box = await Hive.openBox<dynamic>('ai_commit_config');
  await box.put(key, value);
}

Future<void> setKey(String value) async {
  await setData('api_key', value);
}

Future<void> setLocale(String value) async {
  await setData('locale', value);
}

Future<void> setCount(int value) async {
  await setData('generate_count', value);
}

Future<void> setConventional({required bool value}) async {
  await setData('generate_conventional_commits', value);
}

void getConfig() {
  final config = Hive.box<Map<String, dynamic>>('ai_commit_config');

  for (var key in config.keys) {}
}
