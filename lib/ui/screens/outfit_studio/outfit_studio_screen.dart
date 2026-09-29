import '../../../services/garment_storage.dart';
import '../../components/warped_garment.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/clothing_item.dart';
import '../../../providers/wardrobe_provider.dart';
import '../../../screens/add_clothing_screen.dart';
import '../../../screens/source_anchor_screen.dart';
import '../../../screens/usage_guide_screen.dart';
import '../../../services/anchor_fit_service.dart';
import '../../../services/avatar_preferences.dart';
import '../../../services/outfit_history_service.dart';

class OutfitStudioScreen extends StatefulWidget {
  const OutfitStudioScreen({super.key});
  @override
  State<OutfitStudioScreen> createState() => _OutfitStudioScreenState();
}

class _OutfitStudioScreenState extends State<OutfitStudioScreen> {
  static const _categories = [
    'Toate',
    'Tricou',
    'Pantaloni',
    'Geacă',
    'Pantofi',
    'Accesorii',
  ];
  static const _layers = [
    'Pantaloni',
    'Papucul 1',
    'Papucul 2',
    'Tricou',
    'Geacă',
    'Geantă',
    'Inel',
  ];
  final Map<String, ClothingItem> _selected = {};
  final Map<String, AnchorFit> _fits = {};
  final Set<String> _dirty = {};
  final String _profile = AvatarPreferences.selectedProfile.value;
  String _category = 'Toate';
  String? _editing;
  int _anchor = 0, _request = 0;
  bool _adjusting = false,
      _saving = false,
      _marking = false,
      _allowExit = false,
      _exitDialog = false;
  ClothingItem? get _active => _selected[_editing];
  AnchorFit? get _fit => _active == null ? null : _fits[_active!.imagePath];
  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _select(ClothingItem item) async {
    final request = ++_request;
    AnchorFit? fit = _fits[item.imagePath];
    try {
      fit ??= await AnchorFitService.load(item.imagePath, profile: _profile);
    } catch (_) {
      if (mounted) _message('Potrivirea salvată nu a putut fi citită.');
      return;
    }
    if (!mounted || request != _request) return;
    final isNew = fit == null;
    setState(() {
      _selected[item.slot] = item;
      _fits[item.imagePath] = (fit ?? AnchorFit.initial(item.slot))
          .withFiveAnchors();
      _editing = item.slot;
      _adjusting = false;
      _anchor = 0;
      if (isNew) _dirty.add(item.imagePath);
    });
  }

  void _update(AnchorFit fit) {
    if (_active == null || !fit.valid) return;
    setState(() {
      _fits[_active!.imagePath] = fit;
      _dirty.add(_active!.imagePath);
    });
  }

  void _move(int i, Offset point) {
    final fit = _fit;
    if (fit == null) return;
    final points = List<Offset>.of(fit.target);
    points[i] = Offset(point.dx.clamp(0, 1), point.dy.clamp(0, 1));
    final next = fit.copyWith(target: points);
    if (!next.valid) return;
    setState(() => _anchor = i);
    _update(next);
  }

  void _resize(double factor) {
    final fit = _fit!;
    final center =
        fit.target.reduce((a, b) => a + b) / fit.target.length.toDouble();
    _update(
      fit.copyWith(
        target: fit.target.map((p) => center + (p - center) * factor).toList(),
      ),
    );
  }

  Future<void> _source() async {
    final item = _active;
    if (item == null) return;
    final result = await Navigator.push<AnchorFit>(
      context,
      MaterialPageRoute(
        builder: (_) => SourceAnchorScreen(
          path: item.imagePath,
          slot: item.slot,
          fit: _fit!,
        ),
      ),
    );
    if (!mounted || result == null) return;
    _update(result);
    setState(() => _adjusting = true);
  }

  Future<void> _save() async {
    final item = _active, fit = _fit;
    if (item == null || fit == null || _saving) return;
    setState(() => _saving = true);
    try {
      await AnchorFitService.save(item.imagePath, fit, profile: _profile);
      if (mounted) {
        setState(() {
          _dirty.remove(item.imagePath);
          _adjusting = false;
        });
        _message(
          'Potrivire salvată. Ancorele sunt ascunse și reglajele vor fi reutilizate.',
        );
      }
    } catch (_) {
      if (mounted) {
        _message(
          'Salvarea nu a reușit. Reglajele tale sunt încă aici; reîncearcă.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _leave() async {
    if (_exitDialog || _saving) return;
    _exitDialog = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Ai potriviri nesalvate'),
        content: const Text(
          'Revino la piesele marcate „nesalvat” și salvează-le sau ieși fără aceste modificări.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Continuă editarea'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Ieși fără salvare'),
          ),
        ],
      ),
    );
    _exitDialog = false;
    if (!mounted || discard != true) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _markWorn() async {
    if (_selected.isEmpty || _marking) return;
    setState(() => _marking = true);
    try {
      await OutfitHistoryService.markWorn(_selected.values);
      if (mounted) {
        context.read<WardrobeProvider>().refresh();
        _message('Ținuta este marcată ca purtată azi.');
      }
    } catch (_) {
      if (mounted) _message('Istoricul nu a putut fi salvat.');
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  Future<void> _shoe(String slot) async {
    if (_selected.containsKey(slot)) {
      setState(() {
        _editing = slot;
        _adjusting = false;
      });
      return;
    }
    final available = context
        .read<WardrobeProvider>()
        .items
        .where((item) => item.slot == slot)
        .toList();
    if (available.isNotEmpty) {
      await _select(available.first);
      return;
    }
    setState(() => _category = 'Pantofi');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddClothingScreen(initialCategory: 'Pantofi', initialSlot: slot),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = context
        .watch<WardrobeProvider>()
        .items
        .where((i) => _category == 'Toate' || i.category == _category)
        .toList();
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_saving && (_dirty.isEmpty || _allowExit),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cabina de probă'),
          actions: [
            IconButton(
              tooltip: 'Ghid utilizare',
              icon: const Icon(Icons.help_outline),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsageGuideScreen()),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
          children: [
            Text(
              'Ținuta, punct cu punct.',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Previzualizare 2D. Marchează reperele fotografiei, aliniază-le pe corp și salvează potrivirea.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: math.min(620, MediaQuery.sizeOf(context).height * .60),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: ColoredBox(
                  color: colors.surfaceContainerLow,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 828 / 1900,
                      child: LayoutBuilder(
                        builder: (context, box) => GestureDetector(
                          key: const ValueKey('fitting-stage'),
                          behavior: HitTestBehavior.opaque,
                          onTapUp: !_adjusting || _saving
                              ? null
                              : (d) => _move(
                                  _anchor,
                                  Offset(
                                    d.localPosition.dx / box.maxWidth,
                                    d.localPosition.dy / box.maxHeight,
                                  ),
                                ),
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  _profile == 'Feminin'
                                      ? 'assets/images/mannequin_female_v1.png'
                                      : 'assets/images/mannequin.png',
                                  fit: BoxFit.fill,
                                ),
                              ),
                              for (final slot in _layers)
                                if (_selected[slot] != null)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: WarpedGarment(
                                        path: _selected[slot]!.imagePath,
                                        fit: _fits[_selected[slot]!.imagePath]!,
                                      ),
                                    ),
                                  ),
                              if (_adjusting && !_saving && _fit != null)
                                Positioned.fill(
                                  child: AnchorHandles(
                                    points: _fit!.target,
                                    size: box.biggest,
                                    selected: _anchor,
                                    onMove: _move,
                                    onSelect: (i) =>
                                        setState(() => _anchor = i),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slot in ['Papucul 1', 'Papucul 2'])
                  OutlinedButton.icon(
                    onPressed: _saving ? null : () => _shoe(slot),
                    icon: Icon(
                      _selected.containsKey(slot) ? Icons.check : Icons.add,
                    ),
                    label: Text(slot),
                  ),
              ],
            ),
            const Text(
              'Papucul 1: stânga imaginii · Papucul 2: dreapta imaginii',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selected.entries
                  .map(
                    (e) => InputChip(
                      label: Text(
                        '${e.value.name}${_dirty.contains(e.value.imagePath) ? ' · nesalvat' : ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: _editing == e.key,
                      onPressed: _saving
                          ? null
                          : () => setState(() {
                              _editing = e.key;
                              _adjusting = false;
                            }),
                      onDeleted: _saving
                          ? null
                          : () => setState(() {
                              _selected.remove(e.key);
                              if (_editing == e.key) {
                                _editing = null;
                                _adjusting = false;
                              }
                            }),
                    ),
                  )
                  .toList(),
            ),
            if (_active != null) ...[
              const SizedBox(height: 12),
              Text(
                '${_active!.name} · ${_active!.slot}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : _source,
                    child: const Text('1. Ancore pe fotografie'),
                  ),
                  OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() => _adjusting = !_adjusting),
                    child: Text(
                      _adjusting ? 'Ascunde ancorele' : '2. Ajustează pe corp',
                    ),
                  ),
                ],
              ),
              if (_adjusting && !_saving) ...[
                const Text(
                  'Selectează ancora, apoi atinge manechinul sau trage cercul. Folosește săgețile pentru detalii mici.',
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var i = 0; i < _fit!.target.length; i++)
                      ChoiceChip(
                        label: Text('Ancora ${i + 1}'),
                        selected: _anchor == i,
                        onSelected: (_) => setState(() => _anchor = i),
                      ),
                  ],
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Mută ancora la stânga',
                      onPressed: () => _move(
                        _anchor,
                        _fit!.target[_anchor] + const Offset(-.002, 0),
                      ),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    IconButton(
                      tooltip: 'Mută ancora în sus',
                      onPressed: () => _move(
                        _anchor,
                        _fit!.target[_anchor] + const Offset(0, -.001),
                      ),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      tooltip: 'Mută ancora în jos',
                      onPressed: () => _move(
                        _anchor,
                        _fit!.target[_anchor] + const Offset(0, .001),
                      ),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    IconButton(
                      tooltip: 'Mută ancora la dreapta',
                      onPressed: () => _move(
                        _anchor,
                        _fit!.target[_anchor] + const Offset(.002, 0),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                    IconButton(
                      tooltip: 'Micșorează piesa',
                      onPressed: () => _resize(.95),
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      tooltip: 'Mărește piesa',
                      onPressed: () => _resize(1.05),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Se salvează…' : 'Salvează potrivirea'),
              ),
              if (!_adjusting && !_dirty.contains(_active!.imagePath))
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Potrivire salvată · ancore ascunse'),
                ),
            ],
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = c),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Column(
                children: [
                  const Text('Nu există haine în această categorie.'),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddClothingScreen(
                          initialCategory: _category == 'Toate'
                              ? 'Tricou'
                              : _category,
                        ),
                      ),
                    ),
                    child: const Text('Adaugă o piesă'),
                  ),
                ],
              )
            else
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    final selected =
                        _selected[item.slot]?.imagePath == item.imagePath;
                    return SizedBox(
                      width: 112,
                      child: Material(
                        color: colors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: selected
                                ? colors.primary
                                : colors.outlineVariant,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _saving ? null : () => _select(item),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Image(
                                    image: garmentImage(item.imagePath),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) =>
                                        const Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                                Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  item.slot,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _selected.isEmpty || _marking ? null : _markWorn,
              icon: const Icon(Icons.check_rounded),
              label: Text(
                _marking ? 'Se salvează…' : 'Port această ținută azi',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
