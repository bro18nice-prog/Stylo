import 'package:flutter/material.dart';
import 'services/garment_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'ui/screens/app_shell.dart';
import 'providers/wardrobe_provider.dart';
import 'theme/theme_preferences.dart';
import 'services/outfit_history_service.dart';
import 'services/avatar_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await initGarmentStorage();
  await OutfitHistoryService.init();
  await AvatarPreferences.init();
  await ThemePreferences.init();
  final wardrobe = WardrobeProvider();
  await wardrobe.init();
  runApp(ChangeNotifierProvider.value(value: wardrobe, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<StyleTheme>(
    valueListenable: ThemePreferences.selected,
    builder: (_, selected, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StylO',
      theme: ThemePreferences.data(selected),
      home: const AppShell(),
    ),
  );
}
