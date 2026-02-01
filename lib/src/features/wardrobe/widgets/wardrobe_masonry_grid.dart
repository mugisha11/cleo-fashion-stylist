import 'package:flutter/material.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../../../core/models/wardrobe_item_model.dart';
import 'wardrobe_item_card.dart';

/// Wardrobe Masonry Grid - Pinterest-style 2-column grid
class WardrobeMasonryGrid extends StatelessWidget {
  final List<WardrobeItemModel> items;
  final Function(WardrobeItemModel)? onItemTap;
  final Function(WardrobeItemModel)? onItemLongPress;
  final Function(WardrobeItemModel)? onItemMoreTap;

  const WardrobeMasonryGrid({
    super.key,
    required this.items,
    this.onItemTap,
    this.onItemLongPress,
    this.onItemMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Split items into two columns for masonry effect
    final leftColumn = <WardrobeItemModel>[];
    final rightColumn = <WardrobeItemModel>[];
    
    for (int i = 0; i < items.length; i++) {
      if (i % 2 == 0) {
        leftColumn.add(items[i]);
      } else {
        rightColumn.add(items[i]);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FashionDesignSystem.spacingMD),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column
          Expanded(
            child: Column(
              children: leftColumn.map((item) => WardrobeItemCard(
                item: item,
                onTap: onItemTap != null ? () => onItemTap!(item) : null,
                onLongPress: onItemLongPress != null ? () => onItemLongPress!(item) : null,
                onMoreTap: onItemMoreTap != null ? () => onItemMoreTap!(item) : null,
              )).toList(),
            ),
          ),
          
          const SizedBox(width: FashionDesignSystem.spacingMD),
          
          // Right Column
          Expanded(
            child: Column(
              children: rightColumn.map((item) => WardrobeItemCard(
                item: item,
                onTap: onItemTap != null ? () => onItemTap!(item) : null,
                onLongPress: onItemLongPress != null ? () => onItemLongPress!(item) : null,
                onMoreTap: onItemMoreTap != null ? () => onItemMoreTap!(item) : null,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

