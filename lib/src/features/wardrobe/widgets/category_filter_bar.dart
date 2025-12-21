import 'package:flutter/material.dart';
import '../../../core/theme/fashion_design_system.dart';
import 'category_filter_chip.dart';

/// Category Filter Bar - Horizontal scrollable category selector
class CategoryFilterBar extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const CategoryFilterBar({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  static const List<String> categories = [
    'All',
    'Tops',
    'Bottoms',
    'Dresses',
    'Outerwear',
    'Shoes',
    'Accessories',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(vertical: FashionDesignSystem.spacingMD),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: FashionDesignSystem.spacingLG),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category || 
              (selectedCategory == null && category == 'All');
          
          return CategoryFilterChip(
            label: category,
            isSelected: isSelected,
            onTap: () => onCategorySelected(category == 'All' ? null : category),
          );
        },
      ),
    );
  }
}

