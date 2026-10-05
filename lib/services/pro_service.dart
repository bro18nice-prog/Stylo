import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Stylo Pro: abonament de 5 €/lună prin Google Play / App Store (RevenueCat).
///
/// Securitate:
/// - Statutul „Pro” vine doar din răspunsul magazinului, confirmat de
///   RevenueCat. Nu există un steag local care să poată fi modificat.
/// - În aplicație se află doar cheia publică RevenueCat, dată la build:
///   `--dart-define=REVENUECAT_ANDROID_KEY=...` (și `REVENUECAT_IOS_KEY`).
///   Fără cheie, plățile sunt dezactivate și aplicația rămâne în varianta
///   gratuită, fără erori.
/// - Limita de piese gratuite e o limită de produs, aplicată pe telefon.
///   Funcțiile care costă bani (AI) trebuie verificate și pe server.
class ProService extends ChangeNotifier {
  /// Numărul de piese permis în varianta gratuită.
  static const int freeItemLimit = 30;

  /// Numele „entitlement”-ului din RevenueCat.
  static const String entitlementId = 'pro';

  static const String _androidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
  );
  static const String _iosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');

  static final ProService _fallback = ProService();

  /// Găsește serviciul din arbore; fără el (de exemplu în teste) întoarce o
  /// instanță gratuită, neconfigurată.
  static ProService of(BuildContext context, {bool listen = false}) {
    try {
      return Provider.of<ProService>(context, listen: listen);
    } on ProviderNotFoundException {
      return _fallback;
    }
  }

  bool _isPro = false;
  bool _storeReady = false;
  Package? _package;

  bool get isPro => _isPro;

  /// Magazinul e configurat și oferta lunară a fost găsită.
  bool get storeReady => _storeReady;

  /// Prețul afișat, în moneda utilizatorului, așa cum îl dă magazinul.
  String get priceLabel => _package?.storeProduct.priceString ?? '5 €';

  bool canAdd(int currentCount) => _isPro || currentCount < freeItemLimit;

  Future<void> init() async {
    if (kIsWeb) return;
    final key = switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidKey,
      TargetPlatform.iOS => _iosKey,
      _ => '',
    };
    if (key.isEmpty) return;
    try {
      await Purchases.configure(PurchasesConfiguration(key));
      Purchases.addCustomerInfoUpdateListener(_apply);
      _apply(await Purchases.getCustomerInfo());
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      _package =
          current?.monthly ??
          (current != null && current.availablePackages.isNotEmpty
              ? current.availablePackages.first
              : null);
      _storeReady = _package != null;
    } catch (_) {
      _storeReady = false;
    }
    notifyListeners();
  }

  void _apply(CustomerInfo info) {
    final active = info.entitlements.active.containsKey(entitlementId);
    if (active != _isPro) {
      _isPro = active;
      notifyListeners();
    }
  }

  /// Întoarce true dacă utilizatorul e Pro după achiziție. Anularea de către
  /// utilizator nu e eroare.
  Future<bool> purchase() async {
    final package = _package;
    if (package == null) return false;
    try {
      _apply(await Purchases.purchasePackage(package));
      return _isPro;
    } on PlatformException catch (error) {
      if (PurchasesErrorHelper.getErrorCode(error) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      rethrow;
    }
  }

  Future<bool> restore() async {
    if (!_storeReady) return false;
    _apply(await Purchases.restorePurchases());
    return _isPro;
  }
}
