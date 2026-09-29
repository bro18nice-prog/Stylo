import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class AvatarPreferences {
  static final selectedProfile = ValueNotifier<String>('Masculin');
  static late Box _box;

  static Future<void> init() async {
    _box = await Hive.openBox('avatar_preferences');
    selectedProfile.value =
        _box.get('profile', defaultValue: 'Masculin') as String;
  }

  static Future<void> setProfile(String profile) async {
    await _box.put('profile', profile);
    selectedProfile.value = profile;
  }
}
