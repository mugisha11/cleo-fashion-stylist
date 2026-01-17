import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/dashboard_design_system.dart';
import '../../../core/widgets/cleo_logo.dart';

/// Dashboard Sidebar - Pi Network Style
class DashboardSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  final bool isCollapsed;

  const DashboardSidebar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.isCollapsed = false,
  });

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar> {
  final List<SidebarItem> _items = [
    SidebarItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      index: 0,
    ),
    SidebarItem(
      icon: Icons.style_outlined,
      activeIcon: Icons.style,
      label: 'AI Stylist',
      index: 1,
    ),
    SidebarItem(
      icon: Icons.checkroom_outlined,
      activeIcon: Icons.checkroom,
      label: 'My Wardrobe',
      index: 2,
    ),
    SidebarItem(
      icon: Icons.favorite_outline,
      activeIcon: Icons.favorite,
      label: 'Saved Outfits',
      index: 3,
    ),
    SidebarItem(
      icon: Icons.face_outlined,
      activeIcon: Icons.face,
      label: '3D Avatar',
      index: 4,
    ),
    SidebarItem(
      icon: Icons.tune_outlined,
      activeIcon: Icons.tune,
      label: 'Style Settings',
      index: 5,
    ),
    SidebarItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Account & Profile',
      index: 6,
    ),
    SidebarItem(
      icon: Icons.help_outline,
      activeIcon: Icons.help,
      label: 'Support',
      index: 7,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      return _buildMobileBottomNav();
    }

    return Container(
      width: widget.isCollapsed
          ? DashboardDesignSystem.sidebarWidthCollapsed
          : DashboardDesignSystem.sidebarWidth,
      decoration: BoxDecoration(
        color: DashboardDesignSystem.sidebarBackground,
        boxShadow: DashboardDesignSystem.sidebarShadow,
      ),
      child: Column(
        children: [
          // Logo/Header
          _buildHeader(widget.isCollapsed),
          
          Divider(height: 1, color: DashboardDesignSystem.borderLight),
          
          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: DashboardDesignSystem.spacingMD),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isActive = widget.selectedIndex == item.index;
                return _buildSidebarItem(item, isActive, widget.isCollapsed);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isCollapsed) {
    return Container(
      padding: EdgeInsets.all(
        isCollapsed
            ? DashboardDesignSystem.spacingMD
            : DashboardDesignSystem.spacingLG,
      ),
      child: isCollapsed
          ? const CleoLogo.small(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            )
          : Row(
              children: [
                const CleoLogo.small(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                const SizedBox(width: DashboardDesignSystem.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'StyleApp',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: DashboardDesignSystem.textCharcoal,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'AI Fashion Assistant',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: DashboardDesignSystem.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSidebarItem(SidebarItem item, bool isActive, bool isCollapsed) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DashboardDesignSystem.spacingMD,
        vertical: DashboardDesignSystem.spacingXS,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onTabSelected(item.index),
          borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusMD),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed
                  ? DashboardDesignSystem.spacingMD
                  : DashboardDesignSystem.spacingLG,
              vertical: DashboardDesignSystem.spacingMD,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? DashboardDesignSystem.sidebarActive
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(DashboardDesignSystem.radiusMD),
              border: isActive
                  ? Border.all(
                      color: DashboardDesignSystem.secondaryLavender.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive
                      ? DashboardDesignSystem.secondaryLavender
                      : DashboardDesignSystem.textSecondary,
                  size: 22,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: DashboardDesignSystem.spacingMD),
                  Expanded(
                    child: Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive
                            ? DashboardDesignSystem.secondaryLavender
                            : DashboardDesignSystem.textSecondary,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate(target: isActive ? 1 : 0).shimmer(
      duration: 300.ms,
      color: DashboardDesignSystem.secondaryLavender.withValues(alpha: 0.1),
    );
  }

  Widget _buildMobileBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: DashboardDesignSystem.sidebarBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _items.take(5).map((item) {
            final isActive = widget.selectedIndex == item.index;
            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.onTabSelected(item.index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: DashboardDesignSystem.spacingSM,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive
                              ? DashboardDesignSystem.secondaryLavender
                              : DashboardDesignSystem.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: DashboardDesignSystem.spacingXS),
                        Text(
                          item.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                            color: isActive
                                ? DashboardDesignSystem.secondaryLavender
                                : DashboardDesignSystem.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class SidebarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
  });
}


