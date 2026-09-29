import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/wardrobe_provider.dart';
import '../../screens/add_clothing_screen.dart';
import '../../screens/wardrobe_screen.dart';
import '../../services/weather_service.dart';
import '../../services/avatar_preferences.dart';
import 'outfit_studio/outfit_studio_screen.dart';
import 'profile_screen.dart';
import '../components/garment_illustration.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  WeatherSnapshot? _weather;
  bool _loadingWeather = false;

  Future<void> _activateWeather() async {
    setState(() => _loadingWeather = true);
    try {
      final weather = await WeatherService.loadCurrentWeather();
      if (mounted) setState(() => _weather = weather);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingWeather = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/stylo_icon.png',
                      width: 36,
                      height: 36,
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: Theme.of(
                          context,
                        ).textTheme.titleLarge?.fontFamily,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                      children: [
                        TextSpan(
                          text: 'Styl',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        TextSpan(
                          text: 'O',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  _circleIcon(
                    Icons.add_rounded,
                    () => _open(AddClothingScreen()),
                  ),
                  SizedBox(width: 10),
                  _circleIcon(
                    Icons.person_outline_rounded,
                    () => _open(ProfileScreen()),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'SMART WARDROBE',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Dress for\nthe moment.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 38,
                  height: .95,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.8,
                ),
              ),
              SizedBox(height: 20),
              _heroCard(wardrobe.length),
              SizedBox(height: 28),
              Row(
                children: [
                  Text(
                    'MY WARDROBE',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () => _open(WardrobeScreen()),
                    child: Text(
                      'VIEW ALL',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 166,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, _) => SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    const categories = [
                      ('Tricouri', 'assets/images/category_tshirt.png'),
                      ('Pantaloni', 'assets/images/category_pants.png'),
                      ('Pantofi', 'assets/images/category_shoes.png'),
                      ('Geci', 'assets/images/category_jacket.png'),
                    ];
                    return _categoryPreview(index, categories[index].$1);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroCard(int itemCount) {
    return Container(
      height: 390,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: RadialGradient(
          center: Alignment(-.25, -.3),
          radius: 1.25,
          colors: [Color(0xFF293554), Color(0xFF0D1019)],
        ),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Stack(
        children: [
          Positioned(top: 18, left: 18, child: _label('TODAY\'S LOOK')),
          Positioned(top: 18, right: 18, child: _label('$itemCount PIECES')),
          Center(
            child: ValueListenableBuilder<String>(
              valueListenable: AvatarPreferences.selectedProfile,
              builder: (_, profile, _) => Image.asset(
                profile == 'Feminin'
                    ? 'assets/images/hero_mannequin_female_v1.png'
                    : 'assets/images/hero_mannequin_v1.png',
                height: 342,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 18,
            child: _weather == null
                ? InkWell(
                    onTap: _loadingWeather ? null : _activateWeather,
                    child: _weatherChip(
                      _loadingWeather ? 'Loading weather…' : 'Enable weather',
                    ),
                  )
                : _weatherChip(
                    '${_weather!.temperature.round()}°  ${_weather!.label}',
                  ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: FilledButton.icon(
              onPressed: () => _open(OutfitStudioScreen()),
              icon: Icon(Icons.auto_awesome_rounded, size: 17),
              label: Text('STYLE ME'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryPreview(int index, String category) {
    final key = ['Tricou', 'Pantaloni', 'Pantofi', 'Geacă'][index];
    final count = context
        .watch<WardrobeProvider>()
        .items
        .where((item) => item.category == key)
        .length;
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 124,
      child: Card(
        child: InkWell(
          onTap: () => _open(WardrobeScreen(initialCategory: key)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: GarmentIllustration(kind: index)),
                const SizedBox(height: 8),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$count piese',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: .8,
      ),
    ),
  );
  Widget _weatherChip(String text) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  Widget _circleIcon(IconData icon, VoidCallback onTap) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: CircleBorder(),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      ),
    ),
  );
  void _open(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
