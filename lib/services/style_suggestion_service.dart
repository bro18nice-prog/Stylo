import '../models/clothing_item.dart';
import 'weather_service.dart';

/// Prima versiune este deliberat locală: fără cost per cerere sau cheie API.
class StyleSuggestionService {
  static String suggest({
    required String request,
    required List<ClothingItem> wardrobe,
    WeatherSnapshot? weather,
  }) {
    final normalized = request.toLowerCase();
    final hasJacket = wardrobe.any((item) => item.category == 'Geacă');
    final hasShoes = wardrobe.any((item) => item.category == 'Pantofi');
    final formal =
        normalized.contains('interviu') ||
        normalized.contains('oficial') ||
        normalized.contains('formal');

    if (wardrobe.isEmpty) {
      return 'Adaugă câteva piese în garderobă, apoi îți pot construi un look.';
    }
    final weatherTip = weather == null
        ? ''
        : weather.isRainy
        ? ' E posibilă ploaie, deci ia o geacă.'
        : weather.isCold
        ? ' E răcoare, deci stratifică ținuta cu o geacă.'
        : ' Vremea este potrivită pentru o ținută lejeră.';
    if (formal) {
      return 'Pentru un interviu: alege pantaloni curați, un tricou simplu și '
          '${hasShoes ? 'pantofii cei mai sobri' : 'încălțăminte închisă la culoare'}.'
          '$weatherTip';
    }
    return 'Începe cu un tricou, pantaloni și ${hasShoes ? 'pantofi' : 'încălțămintea preferată'}.'
        '${hasJacket ? weatherTip : ''}';
  }
}
