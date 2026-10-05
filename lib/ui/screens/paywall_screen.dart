import 'package:flutter/material.dart';

import '../../services/pro_service.dart';

/// Ecranul abonamentului Stylo Pro. Se închide cu `true` când utilizatorul
/// este Pro.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.reason});

  /// De ce a fost deschis ecranul (de exemplu, limita de piese).
  final String? reason;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _busy = false;

  Future<void> _run(Future<bool> Function() action, String failure) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final pro = await action();
      if (pro && mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ProService.of(context, listen: true);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final benefits = <(String, bool)>[
      ('Piese nelimitate în garderobă', true),
      ('Proba virtuală pe tine, cu AI', false),
      ('Stilist AI pentru vremea și ocazia ta', false),
      ('Insights: culori, piese nepurtate, ținute', false),
      ('Backup și sincronizare între telefoane', false),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Închide',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(
              'STYLO PRO',
              style: TextStyle(
                color: colors.primary,
                fontSize: 12,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Garderoba ta,\nfără limite.',
              style: text.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
                height: .98,
              ),
            ),
            if (widget.reason != null) ...[
              const SizedBox(height: 14),
              Text(
                widget.reason!,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  service.priceLabel,
                  style: text.displayMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'pe lună',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            for (final (label, ready) in benefits)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Icon(
                      ready
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      size: 22,
                      color: ready ? colors.primary : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(label)),
                    if (!ready)
                      Text(
                        'în curând',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            if (service.isPro)
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ești Pro. Continuă'),
              )
            else ...[
              FilledButton(
                onPressed: !service.storeReady || _busy
                    ? null
                    : () => _run(
                        service.purchase,
                        'Plata nu a putut fi finalizată. Nu s-a retras nimic.',
                      ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(
                  _busy
                      ? 'Se procesează…'
                      : 'Abonează-te · ${service.priceLabel}/lună',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: !service.storeReady || _busy
                    ? null
                    : () => _run(
                        service.restore,
                        'Nu am putut verifica achizițiile. Încearcă din nou.',
                      ),
                child: const Text('Restaurează achizițiile'),
              ),
              if (!service.storeReady)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Plățile nu sunt disponibile în această versiune.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            Text(
              'Abonamentul se reînnoiește automat în fiecare lună și se '
              'poate anula oricând din Google Play sau App Store. Plata se '
              'face prin magazin; Stylo nu vede și nu stochează datele '
              'cardului tău.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
