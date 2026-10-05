import 'package:flutter/material.dart';
import '../../services/avatar_preferences.dart';
import '../../services/pro_service.dart';
import '../../theme/theme_preferences.dart';
import 'paywall_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  Future<void> _save(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Preferința nu a putut fi salvată. Încearcă din nou.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pro = ProService.of(context, listen: true);
    return Scaffold(
      appBar: AppBar(title: const Text('Profilul meu')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Stilul începe\ncu tine.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Fă loc preferințelor tale.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: Icon(
                Icons.workspace_premium_rounded,
                color: colors.primary,
              ),
              title: const Text(
                'Stylo Pro',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                pro.isPro
                    ? 'Activ · piese nelimitate'
                    : 'Piese nelimitate · ${pro.priceLabel}/lună',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ASPECTUL APLICAȚIEI',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<StyleTheme>(
            valueListenable: ThemePreferences.selected,
            builder: (_, selected, _) => Column(
              children: [
                for (final theme in StyleTheme.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        leading: Container(
                          width: 42,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                ThemePreferences.data(
                                  theme,
                                ).scaffoldBackgroundColor,
                                ThemePreferences.data(
                                  theme,
                                ).colorScheme.primary,
                              ],
                            ),
                          ),
                        ),
                        title: Text(switch (theme) {
                          StyleTheme.dark => 'Dark Fashion-Tech',
                          StyleTheme.light => 'Light Editorial',
                          StyleTheme.vibrant => 'Vibrant',
                          StyleTheme.rose => 'Rose Atelier',
                        }, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(switch (theme) {
                          StyleTheme.dark =>
                            'Navy, profunzime și accente coral',
                          StyleTheme.light =>
                            'Tonuri calde și contrast editorial',
                          StyleTheme.vibrant =>
                            'Violet intens și accente liliachii',
                          StyleTheme.rose => 'Roz pudrat și accente de zmeură',
                        }),
                        trailing: selected == theme
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: colors.primary,
                              )
                            : null,
                        onTap: () => _save(
                          context,
                          () => ThemePreferences.setTheme(theme),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'PROFIL DE STIL',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<String>(
            valueListenable: AvatarPreferences.selectedProfile,
            builder: (_, selected, _) => Wrap(
              spacing: 10,
              children: ['Masculin', 'Feminin']
                  .map(
                    (profile) => ChoiceChip(
                      label: Text(profile),
                      selected: selected == profile,
                      onSelected: (_) => _save(
                        context,
                        () => AvatarPreferences.setProfile(profile),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Alegerea schimbă manechinul de pe Home și din următoarea cabină de probă deschisă. Potrivirile se salvează separat pentru fiecare variantă.',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.location_on_outlined),
            title: Text('Vreme, la cererea ta'),
            subtitle: Text(
              'Locația este solicitată când activezi vremea pe Home.',
            ),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.lock_outline_rounded),
            title: Text('Colecția rămâne cu tine'),
            subtitle: Text(
              'Hainele, istoricul și preferințele sunt salvate local pe acest dispozitiv.',
            ),
          ),
        ],
      ),
    );
  }
}
