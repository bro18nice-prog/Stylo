import '../../services/garment_storage.dart';

import 'package:flutter/material.dart';

import '../../models/clothing_item.dart';
import '../../services/outfit_history_service.dart';

class ClothingTile extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback onTap;

  const ClothingTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final photo = garmentImage(item.imagePath);

    final lastWorn = OutfitHistoryService.lastWornLabel(item.imagePath);

    return InkWell(
      onTap: onTap,
      child: Card(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  SizedBox(
                    height: double.infinity,
                    width: double.infinity,
                    child: Image(
                      image: photo,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                  if (item.isFavorite)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Tooltip(
                        message: 'Favorită',
                        child: Icon(
                          Icons.favorite_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  if (lastWorn != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          lastWorn,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
