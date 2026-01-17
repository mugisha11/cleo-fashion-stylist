import 'package:flutter/material.dart';
import '../../../core/theme/fashion_design_system.dart';

/// Category Filter Chip - Horizontal scrollable category selector
class CategoryFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: FashionDesignSystem.animationMedium,
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: FashionDesignSystem.spacingLG,
          vertical: FashionDesignSystem.spacingMD,
        ),
        margin: EdgeInsets.only(right: FashionDesignSystem.spacingMD),
        decoration: BoxDecoration(
          color: isSelected
              ? FashionDesignSystem.primaryColor
              : FashionDesignSystem.backgroundWhite,
          borderRadius: BorderRadius.circular(FashionDesignSystem.radiusXL),
          border: Border.all(
            color: isSelected
                ? FashionDesignSystem.primaryColor
                : FashionDesignSystem.borderColor,
            width: 1,
          ),
          boxShadow: isSelected
              ? FashionDesignSystem.cardShadow
              : null,
        ),
        child: Text(
          label,
          style: FashionDesignSystem.bodyMedium().copyWith(
            color: isSelected
                ? Colors.white
                : FashionDesignSystem.textCharcoal,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

