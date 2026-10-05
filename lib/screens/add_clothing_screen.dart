import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/clothing_item.dart';
import '../providers/wardrobe_provider.dart';
import '../services/garment_storage.dart';
import '../services/pro_service.dart';
import '../ui/screens/paywall_screen.dart';
import 'usage_guide_screen.dart';

class AddClothingScreen extends StatefulWidget {
  final String initialCategory;
  final String? initialSlot;
  const AddClothingScreen({
    super.key,
    this.initialCategory = 'Tricou',
    this.initialSlot,
  });
  @override
  State<AddClothingScreen> createState() => _AddClothingScreenState();
}

class _AddClothingScreenState extends State<AddClothingScreen> {
  Uint8List? _original, _cutout;
  String _extension = 'jpg';
  bool _processing = false, _saving = false, _showOriginal = false;
  bool _picking = false;
  String? _error;
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  late String _category = widget.initialCategory;
  late String _shoeSlot = widget.initialSlot == 'Papucul 2'
      ? 'Papucul 2'
      : 'Papucul 1';
  late String _accessorySlot = widget.initialSlot == 'Inel' ? 'Inel' : 'Geantă';
  double _threshold = .45;
  Future<void> _pick() async {
    if (_picking || _processing || _saving) return;
    setState(() => _picking = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _original = bytes;
        _extension = image.name.split('.').last.toLowerCase();
        if (!RegExp(r'^[a-z0-9]{1,5}$').hasMatch(_extension)) {
          _extension = 'jpg';
        }
        _cutout = null;
        _error = null;
        _showOriginal = false;
      });
      // Import stays independent of the optional native background remover.
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Galeria nu a putut fi deschisă. Încearcă din nou.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _process() async {
    if (_original == null || _processing) return;
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final result = await cutoutGarment(_original!, _threshold);
      if (mounted) {
        setState(() {
          _cutout = result;
          _showOriginal = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Decuparea automată nu a reușit. Poți reîncerca sau păstra originalul.',
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() ||
        _original == null ||
        _processing ||
        _picking ||
        _saving) {
      return;
    }
    final provider = context.read<WardrobeProvider>();
    if (!ProService.of(context).canAdd(provider.length)) {
      final pro = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(
            reason:
                'Ai ajuns la ${ProService.freeItemLimit} de piese în varianta gratuită.',
          ),
        ),
      );
      if (pro != true || !mounted) return;
    }
    final source = _showOriginal || _cutout == null ? _original! : _cutout!;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await saveGarment(
        source,
        identical(source, _original) ? _extension : 'png',
      );
      await provider.addItem(
        ClothingItem(
          name: _name.text.trim(),
          category: _category,
          placementSlot: _category == 'Pantofi'
              ? _shoeSlot
              : _category == 'Accesorii'
              ? _accessorySlot
              : null,
          imagePath: saved,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Haina nu a putut fi salvată. Încearcă din nou.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final image = _showOriginal || _cutout == null ? _original : _cutout;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaugă o piesă'),
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
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'O haină. O fotografie clară.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Așază haina întinsă, fotografiaz-o din față și lasă spațiu în jur. Evită fotografiile cu haina purtată de o persoană.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            Container(
              height: 280,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _Checkerboard(colors)),
                  if (image != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.memory(
                        image,
                        fit: BoxFit.contain,
                        cacheWidth: 800,
                        errorBuilder: (_, _, _) => const Center(
                          child: Text('Fotografia nu poate fi afișată.'),
                        ),
                      ),
                    )
                  else
                    const Center(child: Text('Alege o fotografie din galerie')),
                  if (_processing)
                    ColoredBox(
                      color: colors.surface.withValues(alpha: .8),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Se decupează pe dispozitiv…'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _picking || _processing || _saving ? null : _pick,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                image == null ? 'Alege fotografia' : 'Schimbă fotografia',
              ),
            ),
            if (_cutout != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Folosește originalul'),
                subtitle: const Text('Compară și alege ce salvezi.'),
                value: _showOriginal,
                onChanged: _processing || _saving
                    ? null
                    : (value) => setState(() => _showOriginal = value),
              ),
            if (_original != null) ...[
              if (kIsWeb)
                const Text(
                  'Decuparea se face pe acest dispozitiv. Prima utilizare descarcă motorul; păstrează aplicația deschisă.',
                ),
              const SizedBox(height: 8),
              const Text(
                'Poți salva fotografia originală. Decuparea este opțională.',
              ),
              const SizedBox(height: 8),
              const Text('Finețea decupării'),
              Row(
                children: [
                  const Text('Păstrează'),
                  Expanded(
                    child: Slider(
                      value: _threshold,
                      min: .2,
                      max: .75,
                      divisions: 11,
                      onChanged: _processing || _saving
                          ? null
                          : (value) => setState(() => _threshold = value),
                    ),
                  ),
                  const Text('Curăță'),
                ],
              ),
              TextButton(
                onPressed: _processing || _saving ? null : _process,
                child: Text(
                  _cutout == null
                      ? 'Decupează fundalul (opțional)'
                      : 'Reaplică decuparea',
                ),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_error!, style: TextStyle(color: colors.error)),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Numele hainei'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Introdu un nume pentru haină.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: ['Tricou', 'Pantaloni', 'Geacă', 'Pantofi', 'Accesorii']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _category = value!),
            ),
            if (_category == 'Pantofi') ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _shoeSlot,
                decoration: const InputDecoration(labelText: 'Locul în cabină'),
                items: ['Papucul 1', 'Papucul 2']
                    .map(
                      (slot) =>
                          DropdownMenuItem(value: slot, child: Text(slot)),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _shoeSlot = value!),
              ),
              const SizedBox(height: 8),
              const Text(
                'O fotografie pentru un singur papuc. Salvează prima piesă, apoi adaugă separat a doua. Papucul 1 este în stânga imaginii, Papucul 2 în dreapta.',
              ),
            ],
            if (_category == 'Accesorii') ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _accessorySlot,
                decoration: const InputDecoration(labelText: 'Tip accesoriu'),
                items: ['Geantă', 'Inel']
                    .map(
                      (slot) =>
                          DropdownMenuItem(value: slot, child: Text(slot)),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _accessorySlot = value!),
              ),
              const SizedBox(height: 8),
              const Text(
                'Un singur accesoriu în fotografie. Verifică atent decuparea mânerelor, curelelor și centrului inelului.',
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: image == null || _picking || _processing || _saving
                  ? null
                  : _save,
              child: Text(_saving ? 'Se salvează…' : 'Salvează în garderobă'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Checkerboard extends CustomPainter {
  final ColorScheme colors;
  _Checkerboard(this.colors);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = colors.onSurface.withValues(alpha: .045);
    for (double y = 0; y < size.height; y += 16) {
      for (double x = 0; x < size.width; x += 16) {
        if (((x / 16).floor() + (y / 16).floor()).isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, 16, 16), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Checkerboard oldDelegate) =>
      oldDelegate.colors != colors;
}
