import 'package:flutter/material.dart';
import '../../../core/theme/fashion_design_system.dart';

/// AI Calendar Assistant - Friendly style suggestions
class AICalendarAssistant extends StatelessWidget {
  final String message;
  final VoidCallback? onAction;

  const AICalendarAssistant({
    super.key,
    required this.message,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(FashionDesignSystem.spacingLG),
      padding: EdgeInsets.all(FashionDesignSystem.spacingXXL),
      decoration: BoxDecoration(
        color: FashionDesignSystem.backgroundWhite,
        borderRadius: BorderRadius.circular(FashionDesignSystem.radiusLG),
        border: Border.all(
          color: FashionDesignSystem.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // AI Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FashionDesignSystem.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: FashionDesignSystem.iconSize,
              color: FashionDesignSystem.primaryColor,
            ),
          ),
          
          SizedBox(width: FashionDesignSystem.spacingLG),
          
          // Message
          Expanded(
            child: Text(
              message,
              style: FashionDesignSystem.bodyMedium(),
            ),
          ),
          
          // Action Button
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                'View',
                style: FashionDesignSystem.bodySmall().copyWith(
                  color: FashionDesignSystem.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
