import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/app_theme_mode.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/theme_helpers.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../models/settings_state.dart';
import '../../../routes.dart';
import '../../../core/widgets/fashion_drawer.dart';
import 'edit_profile_screen.dart';
import 'fashion_preferences_screen.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';

// Design tokens matching the Profile reference image (design only)
class _ProfilePageColors {
  static const Color background = Color(0xFFF8F8F8);
  static const Color primaryText = Color(0xFF333333);
  static const Color secondaryText = Color(0xFF888888);
  static const Color logoutRed = Color(0xFFE74C3C);
  static const Color editIconPurple = Color(0xFF6C5CE7);
  static const Color backButtonBg = Color(0xFFEEEEEE);
  static const Color toggleTrack = Color(0xFFE0E0E0);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFEEEEEE);
}

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
      setState(() => _appVersion = packageInfo.version);
    } catch (_) {
      setState(() => _appVersion = '1.0.0');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final userAsync = ref.watch(currentUserProvider);
    final firebaseUser = ref.watch(authStateProvider).value;
    final currentTheme = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: _ProfilePageColors.background,
      appBar: _buildAppBar(currentTheme),
      drawer: const AppDrawer(currentRoute: Routes.settings),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentUserProvider);
          ref.invalidate(authStateProvider);
          await ref.read(settingsProvider.notifier).loadSettings();
        },
        color: _ProfilePageColors.editIconPurple,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _buildProfileBlock(userAsync, firebaseUser),
            _buildSectionLabel('Account settings'),
            _buildSettingRow('Personal information', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            }),
            _divider(),
            _buildSettingRow('Privacy & security', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            }),
            _divider(),
            _buildSettingRow('Notifications', () {
              Navigator.of(context).pushNamed(Routes.notificationCenter);
            }),
            _divider(),
            _buildSettingRow('App\'s permission', () {
              _showAppPermissionSheet();
            }),
            const SizedBox(height: 24),
            _buildSectionLabel('Help & support'),
            _buildSettingRow('Terms & conditions', () {}),
            _divider(),
            _buildSettingRow('FAQ & Help', () {}),
            _divider(),
            _buildSettingRow('Privacy policy', () {}),
            const SizedBox(height: 32),
            _buildMoreSection(settings),
            const SizedBox(height: 24),
            _buildLogOutRow(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppThemeMode currentTheme) {
    final isDark = currentTheme == AppThemeMode.darkAI;
    return AppBar(
      backgroundColor: _ProfilePageColors.background,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Material(
          color: _ProfilePageColors.backButtonBg,
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: _ProfilePageColors.primaryText,
            ),
          ),
        ),
      ),
      title: const Text(
        'Profile',
        style: TextStyle(fontFamily: 'system-ui', 
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _ProfilePageColors.primaryText,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.dark_mode_outlined,
                size: 20,
                color: _ProfilePageColors.secondaryText,
              ),
              const SizedBox(width: 8),
              Switch(
                value: isDark,
                onChanged: (value) {
                  ref.read(themeModeProvider.notifier).setTheme(
                        value ? AppThemeMode.darkAI : AppThemeMode.giovanni,
                      );
                },
                activeColor: _ProfilePageColors.editIconPurple,
                activeTrackColor: _ProfilePageColors.toggleTrack,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const String _profileBoxBackgroundAsset =
      'assets/images/image-removebg-preview (11).png';

  Widget _buildProfileBlock(
      AsyncValue<UserModel?> userAsync, User? firebaseUser) {
    final userModel = userAsync.value;
    final displayName = userModel?.displayName ?? firebaseUser?.displayName ?? 'User';
    final email = userModel?.email.isNotEmpty == true
        ? userModel!.email
        : (firebaseUser?.email ?? 'No email');
    final photoUrl = userModel?.avatarUrl ?? firebaseUser?.photoURL;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 240,
          child: Stack(
          children: [
            // Background image behind the profile box
            Positioned.fill(
              child: Image.asset(
                _profileBoxBackgroundAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: _ProfilePageColors.cardSurface,
                ),
              ),
            ),
            // Profile content on top, centered in the box
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _ProfilePageColors.cardSurface.withValues(alpha: 0.95),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: photoUrl != null
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                                errorBuilder: (_, __, ___) => _avatarInitial(displayName, email),
                              )
                            : _avatarInitial(displayName, email),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                            );
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _ProfilePageColors.cardSurface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: _ProfilePageColors.editIconPurple,
                            ),
                          ),
                        ),
                      ),
                    ],
                    ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: const TextStyle(fontFamily: 'system-ui', 
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _ProfilePageColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(fontFamily: 'system-ui', 
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _ProfilePageColors.secondaryText,
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _avatarInitial(String displayName, String email) {
    final initial = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : (email.isNotEmpty ? email.substring(0, 1).toUpperCase() : 'U');
    return Center(
      child: Text(
        initial,
        style: const TextStyle(fontFamily: 'system-ui', 
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: _ProfilePageColors.secondaryText,
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 20),
      color: _ProfilePageColors.divider,
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8, top: 4),
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'system-ui', 
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: _ProfilePageColors.secondaryText,
        ),
      ),
    );
  }

  Widget _buildSettingRow(String title, VoidCallback? onTap) {
    return Material(
      color: _ProfilePageColors.cardSurface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontFamily: 'system-ui', 
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: _ProfilePageColors.primaryText,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 22,
                color: _ProfilePageColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogOutRow() {
    return Material(
      color: _ProfilePageColors.cardSurface,
      child: InkWell(
        onTap: _showLogoutConfirmation,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Text(
                'Log Out',
                style: TextStyle(fontFamily: 'system-ui', 
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _ProfilePageColors.logoutRed,
                ),
              ),
              Spacer(),
              Icon(
                Icons.logout,
                size: 20,
                color: _ProfilePageColors.logoutRed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppPermissionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _ProfilePageColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _ProfilePageColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildSectionLabel('About'),
            _buildInfoRow('Version', _appVersion ?? 'Loading...'),
            _buildSettingRow('Terms & Conditions', () => Navigator.pop(context)),
            _buildSettingRow('Privacy Policy', () => Navigator.pop(context)),
            _buildSettingRow('Help & Support', () => Navigator.pop(context)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontFamily: 'system-ui', 
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: _ProfilePageColors.primaryText,
            ),
          ),
          const Spacer(),
          Text(
            subtitle,
            style: const TextStyle(fontFamily: 'system-ui', 
              fontSize: 14,
              color: _ProfilePageColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreSection(SettingsState settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('More'),
        _settingTile(
          'Friends & Chats',
          onTap: () => Navigator.of(context).pushNamed(Routes.friendRequests),
        ),
        _settingTile(
          'Change Email',
          onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangeEmailScreen()),
              ),
        ),
        _settingTile(
          'My fit & style',
          onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FashionPreferencesScreen(),
                ),
              ),
        ),
        _settingTile('Language', onTap: () => _showLanguageSheet()),
        _settingTile(
          'Daily picks',
          trailing: Switch(
            value: settings.autoRecommendations,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).updateAutoRecommendations(v),
            activeColor: _ProfilePageColors.editIconPurple,
          ),
        ),
        _settingTile(
          'Push alerts',
          trailing: Switch(
            value: settings.pushNotifications,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).updatePushNotifications(v),
            activeColor: _ProfilePageColors.editIconPurple,
          ),
        ),
        _settingTile('Appearance', onTap: () => _showThemeSheet()),
        _settingTile('Data Usage', onTap: _showDataUsageDialog),
        _settingTile('Delete My Data', onTap: _showDeleteDataConfirmation, isDestructive: true),
        _settingTile('Delete Account', onTap: _showDeleteAccountConfirmation, isDestructive: true),
      ],
    );
  }

  Widget _settingTile(
    String title, {
    VoidCallback? onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? _ProfilePageColors.logoutRed
        : _ProfilePageColors.primaryText;
    return Material(
      color: _ProfilePageColors.cardSurface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontFamily: 'system-ui', 
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: color,
                  ),
                ),
              ),
              if (trailing != null) trailing,
              if (trailing == null && onTap != null)
                const Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: _ProfilePageColors.secondaryText,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _ProfilePageColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: LanguageSelector(onLanguageChanged: () {}),
      ),
    );
  }

  void _showThemeSheet() {
    final currentTheme = ref.read(themeModeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: _ProfilePageColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Appearance',
                style: TextStyle(fontFamily: 'system-ui', 
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _ProfilePageColors.primaryText,
                ),
              ),
              const SizedBox(height: 16),
              ...AppThemeMode.values.map((mode) {
                final isSelected = currentTheme == mode;
                return ListTile(
                  title: Text(
                    mode.displayName,
                    style: const TextStyle(fontFamily: 'system-ui', 
                      fontSize: 16,
                      color: _ProfilePageColors.primaryText,
                    ),
                  ),
                  subtitle: Text(
                    mode.description,
                    style: const TextStyle(fontFamily: 'system-ui', 
                      fontSize: 13,
                      color: _ProfilePageColors.secondaryText,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: _ProfilePageColors.editIconPurple,
                          size: 22,
                        )
                      : null,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setTheme(mode);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
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
          Navigator.of(context).pushNamedAndRemoveUntil(
            Routes.login,
            (route) => false,
          );
        }
      },
      onCancel: () => Navigator.pop(context),
    );
  }
}
