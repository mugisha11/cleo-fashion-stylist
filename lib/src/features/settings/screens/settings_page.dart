import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/app_theme_mode.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/widgets/theme_helpers.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/cleo_logo.dart';
import '../../../core/widgets/dashboard_components.dart';
import '../../../core/theme/app_theme_data.dart';
import '../../../core/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/providers/social_provider.dart';
import '../providers/settings_provider.dart';
import '../models/settings_state.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_toggle_tile.dart';
import '../widgets/settings_action_tile.dart';
import '../../../routes.dart';
import 'edit_profile_screen.dart';
import 'fashion_preferences_screen.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final accentPink = context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    final settings = ref.watch(settingsProvider);
    final userAsync = ref.watch(currentUserProvider);
    final firebaseUser = ref.watch(authStateProvider).value;

    final unreadCount = ref.watch(socialUnreadCountProvider);
    return Scaffold(
      backgroundColor: theme.backgroundPrimary,
      appBar: DashboardTopBar(
        aiStatus: 'Settings',
        isAITyping: false,
        notificationCount: unreadCount,
        onProfileTap: () {
          Scaffold.of(context).closeDrawer();
        },
        onNotificationsTap: () {
          Navigator.of(context).pushNamed(Routes.notificationCenter);
        },
      ),
      drawer: _buildNavigationDrawer(context),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh both settings and user data
          ref.invalidate(currentUserProvider);
          ref.invalidate(authStateProvider);
          await ref.read(settingsProvider.notifier).loadSettings();
        },
        color: accentPink,
        child: ListView(
          children: [
            const SizedBox(height: AppThemeData.spacingMD),

            // Profile Section
            _buildProfileSection(userAsync, firebaseUser),

            // Friends & Messages
            _buildSocialSection(),

            // Account Settings
            _buildAccountSettingsSection(),

            // Fashion Preferences
            _buildFashionPreferencesSection(settings),

            // AI & Try-On Settings
            _buildAISettingsSection(settings),

            // Theme Settings
            _buildThemeSection(),

            // Language Settings
            _buildLanguageSection(),

            // Notifications
            _buildNotificationsSection(settings),

            // Privacy & Data
            _buildPrivacySection(),

            // App Information
            _buildAppInfoSection(),

            const SizedBox(height: AppThemeData.spacingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    final isDark = context.isDarkMode;
    return Drawer(
      child: Container(
        color:
            isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? DesignTokens.darkBorder
                        : DesignTokens.lightBorder,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cleo Fashion',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? DesignTokens.darkAccent
                              : DesignTokens.lightAccent,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your AI Fashion Assistant',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.home,
              label: 'Dashboard',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.dashboard);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.checkroom,
              label: 'Wardrobe',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.wardrobe);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.image_search,
              label: 'Virtual Try-On',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.tryon);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.lightbulb,
              label: 'Recommendations',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.recommendations);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.calendar_today,
              label: 'Calendar & Events',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.calendar);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.grid_view_rounded,
              label: 'Style Feed',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.styleFeed);
              },
            ),
            const Divider(),
            _buildNavItem(
              context: context,
              icon: Icons.settings,
              label: 'Settings',
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent,
      ),
      title: Text(label),
      onTap: onTap,
      hoverColor: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
    );
  }

  Widget _buildProfileSection(
      AsyncValue<UserModel?> userAsync, User? firebaseUser) {
    final theme = context.appTheme;

    // Get user data from Firestore first, fallback to Firebase user
    final userModel = userAsync.value;
    final displayName = userModel?.displayName ?? firebaseUser?.displayName;
    final email = userModel?.email.isNotEmpty == true
        ? userModel!.email
        : (firebaseUser?.email ?? 'No email');
    final photoUrl = userModel?.avatarUrl ?? firebaseUser?.photoURL;

    return SettingsSectionCard(
      title: 'Profile',
      children: [
        Padding(
          padding: const EdgeInsets.all(AppThemeData.spacingMD),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: context.isDarkMode ? DesignTokens.darkAccent : DesignTokens.lightAccent,
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(
                        displayName?.substring(0, 1).toUpperCase() ??
                            email.substring(0, 1).toUpperCase() ??
                            'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppThemeData.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName ?? 'User',
                      style: theme.titleLarge(),
                    ),
                    const SizedBox(height: AppThemeData.spacingXS),
                    Text(
                      email,
                      style: theme.bodySmall(color: theme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.borderLight),
        SettingsActionTile(
          title: 'Edit Profile',
          leadingIcon: Icons.edit,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSocialSection() {
    final isDark = context.isDarkMode;
    final accent = isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent;
    return SettingsSectionCard(
      title: 'Friends & Messages',
      children: [
        SettingsActionTile(
          title: 'Friend requests',
          subtitle: 'View pending and sent requests',
          leadingIcon: Icons.person_add_rounded,
          onTap: () => Navigator.of(context).pushNamed(Routes.friendRequests),
        ),
        SettingsActionTile(
          title: 'Messages',
          subtitle: 'Chat with friends',
          leadingIcon: Icons.chat_bubble_outline_rounded,
          onTap: () => Navigator.of(context).pushNamed(Routes.chats),
        ),
      ],
    );
  }

  Widget _buildAccountSettingsSection() {
    final theme = context.appTheme;
    return SettingsSectionCard(
      title: 'Account Settings',
      children: [
        SettingsActionTile(
          title: 'Change Email',
          subtitle: 'Update your email address',
          leadingIcon: Icons.email_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangeEmailScreen()),
            );
          },
        ),
        Divider(height: 1, color: theme.borderLight),
        SettingsActionTile(
          title: 'Change Password',
          subtitle: 'Update your password',
          leadingIcon: Icons.lock_outline,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFashionPreferencesSection(SettingsState settings) {
    return SettingsSectionCard(
      title: 'Fashion Preferences',
      children: [
        SettingsActionTile(
          title: 'Body Measurements & Style',
          subtitle: settings.height != null
              ? '${settings.height?.toStringAsFixed(0)} cm, ${settings.bodyType ?? "Not set"}'
              : 'Set your measurements and preferences',
          leadingIcon: Icons.straighten,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FashionPreferencesScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAISettingsSection(SettingsState settings) {
    final theme = context.appTheme;
    return SettingsSectionCard(
      title: 'AI & Try-On Settings',
      children: [
        SettingsToggleTile(
          title: 'Auto Outfit Recommendations',
          subtitle: 'Get AI-powered outfit suggestions automatically',
          value: settings.autoRecommendations,
          icon: Icons.auto_awesome,
          onChanged: (value) {
            ref
                .read(settingsProvider.notifier)
                .updateAutoRecommendations(value);
          },
        ),
        Divider(height: 1, color: theme.borderLight),
        SettingsToggleTile(
          title: 'High-Quality Rendering',
          subtitle: 'Use enhanced quality for try-on results (slower)',
          value: settings.highQualityRendering,
          icon: Icons.high_quality,
          onChanged: (value) {
            ref
                .read(settingsProvider.notifier)
                .updateHighQualityRendering(value);
          },
        ),
        Divider(height: 1, color: theme.borderLight),
        SettingsToggleTile(
          title: 'Background Preservation',
          subtitle: 'Keep original background in try-on results',
          value: settings.backgroundPreservation,
          icon: Icons.image_outlined,
          onChanged: (value) {
            ref
                .read(settingsProvider.notifier)
                .updateBackgroundPreservation(value);
          },
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(SettingsState settings) {
    final theme = context.appTheme;
    return SettingsSectionCard(
      title: 'Notifications',
      children: [
        SettingsToggleTile(
          title: 'Push Notifications',
          subtitle: 'Receive push notifications',
          value: settings.pushNotifications,
          icon: Icons.notifications_outlined,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).updatePushNotifications(value);
          },
        ),
        Divider(height: 1, color: theme.borderLight),
        SettingsToggleTile(
          title: 'Outfit Reminders',
          subtitle: 'Get reminders for planned outfits',
          value: settings.outfitReminders,
          icon: Icons.calendar_today,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).updateOutfitReminders(value);
          },
        ),
        Divider(height: 1, color: theme.borderLight),
        SettingsToggleTile(
          title: 'Recommendation Alerts',
          subtitle: 'Get notified about new outfit recommendations',
          value: settings.recommendationAlerts,
          icon: Icons.star_outline,
          onChanged: (value) {
            ref
                .read(settingsProvider.notifier)
                .updateRecommendationAlerts(value);
          },
        ),
        Divider(height: 1, color: theme.borderLight),
        SettingsActionTile(
          title: 'View all notifications',
          subtitle: 'Friend requests, messages, likes, comments',
          leadingIcon: Icons.notifications_active_outlined,
          onTap: () => Navigator.of(context).pushNamed(Routes.notificationCenter),
        ),
      ],
    );
  }

  Widget _buildThemeSection() {
    final currentTheme = ref.watch(themeModeProvider);
    final themeData = ref.watch(themeDataProvider);

    return SettingsSectionCard(
      title: 'Appearance',
      children: [
        ...AppThemeMode.values.map((mode) {
          final isSelected = currentTheme == mode;
          return RadioListTile<AppThemeMode>(
            title: Text(
              mode.displayName,
              style: TextStyle(color: themeData.textPrimary),
            ),
            subtitle: Text(
              mode.description,
              style: themeData.bodySmall(color: themeData.textSecondary),
            ),
            value: mode,
            groupValue: currentTheme,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setTheme(value);
              }
            },
            activeColor: themeData.primary,
            selected: isSelected,
          );
        }),
      ],
    );
  }

  Widget _buildLanguageSection() {
    final theme = context.appTheme;

    return SettingsSectionCard(
      title: 'Language',
      children: [
        Padding(
          padding: const EdgeInsets.all(AppThemeData.spacingMD),
          child: LanguageSelector(
            onLanguageChanged: () {
              // Language changed, UI will update automatically via Riverpod
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    final theme = context.appTheme;
    return SettingsSectionCard(
      title: 'Privacy & Data',
      children: [
        SettingsActionTile(
          title: 'Data Usage',
          subtitle: 'Learn how we use your data',
          leadingIcon: Icons.info_outline,
          onTap: () {
            _showDataUsageDialog();
          },
        ),
        Divider(height: 1, color: theme.borderLight),
        SettingsActionTile(
          title: 'AI Image Processing',
          subtitle: 'Understand how AI processes your images',
          leadingIcon: Icons.psychology_outlined,
          onTap: () {
            _showAIImageProcessingDialog();
          },
        ),
        Divider(height: 1, color: theme.borderLight),
        SettingsActionTile(
          title: 'Delete My Data',
          subtitle: 'Permanently delete all your data',
          leadingIcon: Icons.delete_outline,
          isDestructive: true,
          onTap: () {
            _showDeleteDataConfirmation();
          },
        ),
        Divider(height: 1, color: theme.borderLight),
        SettingsActionTile(
          title: 'Logout',
          leadingIcon: Icons.logout,
          isDestructive: true,
          onTap: () {
            _showLogoutConfirmation();
          },
        ),
        Divider(height: 1, color: theme.borderLight),
        SettingsActionTile(
          title: 'Delete Account',
          subtitle: 'Permanently delete your account',
          leadingIcon: Icons.delete_forever,
          isDestructive: true,
          onTap: () {
            _showDeleteAccountConfirmation();
          },
        ),
      ],
    );
  }

  Widget _buildAppInfoSection() {
    final theme = context.appTheme;
    return SettingsSectionCard(
      title: 'App Information',
      children: [
        // Logo
        const Padding(
          padding: EdgeInsets.all(AppThemeData.spacingMD),
          child: Center(
            child: CleoLogo.medium(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        SettingsActionTile(
          title: 'Version',
          subtitle: _appVersion ?? 'Loading...',
          leadingIcon: Icons.info,
        ),
        Divider(height: 1, color: theme.borderLight),
        SettingsActionTile(
          title: 'Terms & Conditions',
          leadingIcon: Icons.description_outlined,
          onTap: () {
            // Navigate to terms
          },
        ),
        Divider(height: 1, color: theme.borderLight),
        SettingsActionTile(
          title: 'Privacy Policy',
          leadingIcon: Icons.privacy_tip_outlined,
          onTap: () {
            // Navigate to privacy policy
          },
        ),
        Divider(height: 1, color: theme.borderLight),
        SettingsActionTile(
          title: 'Help & Support',
          leadingIcon: Icons.help_outline,
          onTap: () {
            // Navigate to help
          },
        ),
      ],
    );
  }

  void _showDataUsageDialog() {
    ThemedDialog.show(
      context: context,
      title: 'Data Usage',
      content:
          'We use your data to provide personalized fashion recommendations and improve your experience. Your data is encrypted and stored securely.',
      confirmText: 'OK',
      onConfirm: () => Navigator.pop(context),
    );
  }

  void _showAIImageProcessingDialog() {
    ThemedDialog.show(
      context: context,
      title: 'AI Image Processing',
      content:
          'Your images are processed using AI to create virtual try-on results. Images are processed securely and not shared with third parties.',
      confirmText: 'OK',
      onConfirm: () => Navigator.pop(context),
    );
  }

  void _showDeleteDataConfirmation() {
    ThemedDialog.show(
      context: context,
      title: 'Delete All Data?',
      content:
          'This will permanently delete all your data including wardrobe, preferences, and try-on history. This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
      onConfirm: () {
        Navigator.pop(context);
        // Implement delete data
      },
      onCancel: () => Navigator.pop(context),
    );
  }

  void _showLogoutConfirmation() {
    ThemedDialog.show(
      context: context,
      title: 'Logout?',
      content: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      onConfirm: () async {
        Navigator.pop(context);
        final authService = ref.read(authServiceProvider);
        await authService.signOut();
        if (context.mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      onCancel: () => Navigator.pop(context),
    );
  }

  void _showDeleteAccountConfirmation() {
    ThemedDialog.show(
      context: context,
      title: 'Delete Account?',
      content:
          'This will permanently delete your account and all associated data. This action cannot be undone.',
      confirmText: 'Delete Account',
      cancelText: 'Cancel',
      isDestructive: true,
      onConfirm: () {
        Navigator.pop(context);
        // Implement delete account
      },
      onCancel: () => Navigator.pop(context),
    );
  }
}

