import '../services/garment_storage.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import '../models/clothing_item.dart';
import '../providers/wardrobe_provider.dart';

class ClothingDetailsScreen extends StatefulWidget {
  final int initialIndex;
  const ClothingDetailsScreen({super.key, required this.initialIndex});
  @override
  State<ClothingDetailsScreen> createState() => _ClothingDetailsScreenState();
}

class _ClothingDetailsScreenState extends State<ClothingDetailsScreen> {
  late final PageController _pages;
  late int _index;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pages = PageController(initialPage: _index < 0 ? 0 : _index);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _favorite(ClothingItem item) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.read<WardrobeProvider>().toggleFavorite(item);
    } catch (_) {
      if (mounted) _message('Nu am putut salva favorita. Încearcă din nou.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
  Future<void> _delete(ClothingItem item) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Ștergi această piesă?'),
          content: Text('„${item.name}” va fi eliminată din garderobă.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Păstrează'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Șterge'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await context.read<WardrobeProvider>().removeItem(item);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) _message('Piesa nu a putut fi ștearsă. Încearcă din nou.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<WardrobeProvider>().items;
    final colors = Theme.of(context).colorScheme;
    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalii piesă')),
        body: const Center(child: Text('Nu mai există haine în garderobă.')),
      );
    }
    final index = _index.clamp(0, items.length - 1);
    final item = items[index];
    return Scaffold(
      appBar: AppBar(
        title: Text('${index + 1} din ${items.length}'),
        actions: [
          IconButton(
            tooltip: item.isFavorite
                ? 'Elimină din favorite'
                : 'Adaugă la favorite',
            onPressed: _busy ? null : () => _favorite(item),
            icon: Icon(
              item.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: item.isFavorite ? colors.primary : null,
            ),
          ),
          IconButton(
            tooltip: 'Șterge piesa',
            onPressed: _busy ? null : () => _delete(item),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pages,
                physics: _busy ? const NeverScrollableScrollPhysics() : null,
                itemCount: items.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (_, position) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: PhotoView(
                      backgroundDecoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                      ),
                      imageProvider: garmentImage(items[position].imagePath),
                      minScale: PhotoViewComputedScale.contained,
                      initialScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 3,
                      errorBuilder: (_, _, _) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: 40,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Fotografia nu mai este disponibilă.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.category,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Apropie cu două degete pentru detalii${items.length > 1 ? ' · Glisează pentru altă piesă' : ''}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
