import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/clothing_item.dart';
import '../providers/wardrobe_provider.dart';
import '../services/outfit_history_service.dart';
import '../ui/components/clothing_tile.dart';
import '../ui/components/hanger_rail.dart';
import 'add_clothing_screen.dart';
import 'clothing_details_screen.dart';
import 'usage_guide_screen.dart';
import '../ui/screens/outfit_studio/outfit_studio_screen.dart';

class WardrobeScreen extends StatefulWidget {
  final String? initialCategory;
  const WardrobeScreen({super.key, this.initialCategory});
  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  late String? category = widget.initialCategory;
  String query = '';
  final _search = TextEditingController();
  static String _normalize(String value) {
    var result = value.toLowerCase().trim();
    const replacements = {
      'ă': 'a',
      'â': 'a',
      'î': 'i',
      'ș': 's',
      'ş': 's',
      'ț': 't',
      'ţ': 't',
    };
    replacements.forEach((from, to) => result = result.replaceAll(from, to));
    return result;
  }

  void _resetFilters() {
    _search.clear();
    setState(() {
      query = '';
      category = null;
      favorites = false;
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool favorites = false;
  bool railView = true;
  int railIndex = 0;

  void _openDetails(List<ClothingItem> all, ClothingItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClothingDetailsScreen(initialIndex: all.indexOf(item)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>().items;
    final items = wardrobe
        .where(
          (item) =>
              (category == null || item.category == category) &&
              (!favorites || item.isFavorite) &&
              _normalize(item.name).contains(_normalize(query)),
        )
        .toList();
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garderoba mea'),
        actions: [
          IconButton(
            tooltip: railView ? 'Vezi ca grilă' : 'Vezi pe umerașe',
            icon: Icon(
              railView ? Icons.grid_view_rounded : Icons.checkroom_rounded,
            ),
            onPressed: () => setState(() => railView = !railView),
          ),
          IconButton(
            tooltip: 'Ghid utilizare',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UsageGuideScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Adaugă o piesă',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddClothingScreen()),
            ),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Colecția ta.\nStilul tău.',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${wardrobe.length} piese · un loc pentru fiecare ținută',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OutfitStudioScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.accessibility_new_rounded),
                    label: const Text('Cabina de probă'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    onChanged: (value) => setState(() => query = value),
                    decoration: InputDecoration(
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Golește căutarea',
                              onPressed: () {
                                _search.clear();
                                setState(() => query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      hintText: 'Caută după nume',
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final value in <String?>[
                          null,
                          'Tricou',
                          'Pantaloni',
                          'Geacă',
                          'Pantofi',
                          'Accesorii',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(value ?? 'Toate'),
                              selected: category == value,
                              onSelected: (_) =>
                                  setState(() => category = value),
                            ),
                          ),
                        FilterChip(
                          label: const Text('Favorite'),
                          selected: favorites,
                          onSelected: (value) =>
                              setState(() => favorites = value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        wardrobe.isEmpty
                            ? 'Primul pas spre stilul tău.'
                            : 'Nicio piesă găsită.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        wardrobe.isEmpty
                            ? 'Adaugă o fotografie din galerie și începe colecția.'
                            : 'Încearcă alt nume sau schimbă filtrele.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      if (wardrobe.isEmpty)
                        FilledButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddClothingScreen(),
                            ),
                          ),
                          child: const Text('Adaugă prima piesă'),
                        )
                      else
                        OutlinedButton(
                          onPressed: _resetFilters,
                          child: const Text('Resetează filtrele'),
                        ),
                    ],
                  ),
                ),
              ),
            )
          else if (railView)
            SliverToBoxAdapter(child: _railSection(wardrobe, items, colors))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisExtent: 290,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, index) => ClothingTile(
                    item: items[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClothingDetailsScreen(
                          initialIndex: wardrobe.indexOf(items[index]),
                        ),
                      ),
                    ),
                  ),
                  childCount: items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _railSection(
    List<ClothingItem> wardrobe,
    List<ClothingItem> items,
    ColorScheme colors,
  ) {
    final position = railIndex.clamp(0, items.length - 1).toInt();
    final selected = items[position];
    final lastWorn = OutfitHistoryService.lastWornLabel(selected.imagePath);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              height: 440,
              child: HangerRail(
                items: items,
                onIndexChanged: (index) {
                  if (mounted && index != railIndex) {
                    setState(() => railIndex = index);
                  }
                },
                onOpen: (index) => _openDetails(wardrobe, items[index]),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${position + 1} / ${items.length}'
                      '${lastWorn == null ? '' : ' · $lastWorn'}',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () => _openDetails(wardrobe, selected),
                child: const Text('Detalii'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
