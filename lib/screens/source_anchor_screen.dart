import '../services/garment_storage.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/anchor_fit_service.dart';

class AnchorHandles extends StatelessWidget {
  final List<Offset> points;
  final Size size;
  final int selected;
  final void Function(int, Offset) onMove;
  final ValueChanged<int> onSelect;
  const AnchorHandles({
    super.key,
    required this.points,
    required this.size,
    required this.selected,
    required this.onMove,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      for (var i = 0; i < points.length; i++)
        Positioned(
          left: points[i].dx * size.width - 22,
          top: points[i].dy * size.height - 22,
          child: Semantics(
            label: 'Ancora ${i + 1}',
            button: true,
            selected: selected == i,
            child: GestureDetector(
              key: ValueKey('anchor-$i'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(i),
              onPanStart: (_) => onSelect(i),
              onPanUpdate: (d) => onMove(
                i,
                points[i] +
                    Offset(d.delta.dx / size.width, d.delta.dy / size.height),
              ),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Container(
                    width: selected == i ? 30 : 24,
                    height: selected == i ? 30 : 24,
                    decoration: BoxDecoration(
                      color: selected == i
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selected == i
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class SourceAnchorScreen extends StatefulWidget {
  final String path, slot;
  final AnchorFit fit;
  const SourceAnchorScreen({
    super.key,
    required this.path,
    required this.slot,
    required this.fit,
  });
  @override
  State<SourceAnchorScreen> createState() => _SourceAnchorScreenState();
}

class _SourceAnchorScreenState extends State<SourceAnchorScreen> {
  late final List<Offset> _points = List.of(widget.fit.source);
  int _selected = 0;
  String? _error;
  late final Future<Size> _size = _readSize();
  Future<Size> _readSize() async {
    final codec = await ui.instantiateImageCodec(
      await readGarment(widget.path),
    );
    try {
      final frame = await codec.getNextFrame();
      final size = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      return size;
    } finally {
      codec.dispose();
    }
  }

  List<String> get _labels => switch (widget.slot) {
    'Tricou' || 'Geacă' => [
      'Umăr din stânga imaginii',
      'Umăr din dreapta imaginii',
      'Mijlocul tivului',
      'Tiv, stânga imaginii',
      'Tiv, dreapta imaginii',
    ],
    'Pantaloni' => [
      'Talie, stânga imaginii',
      'Talie, dreapta imaginii',
      'Jos, între cele două terminații',
      'Terminație stânga',
      'Terminație dreapta',
    ],
    _ => [
      'Margine sus-stânga',
      'Margine sus-dreapta',
      'Mijlocul marginii de jos',
      'Colț jos-stânga',
      'Colț jos-dreapta',
    ],
  };
  void _move(int i, Offset p) => setState(() {
    _selected = i;
    _points[i] = Offset(p.dx.clamp(0, 1), p.dy.clamp(0, 1));
    _error = null;
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ancore pe fotografie')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Alege un punct numerotat, apoi atinge locul lui pe fotografie sau trage cercul. Stânga și dreapta sunt cele din imagine.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < _points.length; i++)
              ChoiceChip(
                label: Text('${i + 1}'),
                selected: _selected == i,
                onSelected: (_) => setState(() => _selected = i),
              ),
          ],
        ),
        Text(
          _labels[_selected],
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        FutureBuilder<Size>(
          future: _size,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Fotografia nu poate fi deschisă. Alege o imagine validă din garderobă.',
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return SizedBox(
              height: 400,
              child: Center(
                child: AspectRatio(
                  aspectRatio: snapshot.data!.aspectRatio,
                  child: LayoutBuilder(
                    builder: (context, box) => GestureDetector(
                      onTapUp: (d) => _move(
                        _selected,
                        Offset(
                          d.localPosition.dx / box.maxWidth,
                          d.localPosition.dy / box.maxHeight,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: ColoredBox(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: Image(
                                image: garmentImage(widget.path),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: AnchorHandles(
                              points: _points,
                              size: box.biggest,
                              selected: _selected,
                              onMove: _move,
                              onSelect: (i) => setState(() => _selected = i),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        FilledButton(
          onPressed: () async {
            try {
              await _size;
            } catch (_) {
              return;
            }
            if (!mounted) return;
            final fit = widget.fit.copyWith(source: _points);
            if (!fit.valid) {
              setState(
                () => _error =
                    'Păstrează punctul 1 la stânga lui 2 și punctul 3 mai jos; nu le suprapune.',
              );
              return;
            }
            if (context.mounted) Navigator.pop(context, fit);
          },
          child: const Text('Aplică pe manechin'),
        ),
      ],
    ),
  );
}
