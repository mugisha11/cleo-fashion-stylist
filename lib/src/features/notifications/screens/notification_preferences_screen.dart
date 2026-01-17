/// Notification Preferences Screen
/// User-controlled notification settings
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../theme/calendar_theme.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, dynamic> _preferences = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notifications')
          .get();

      if (doc.exists) {
        setState(() {
          _preferences = doc.data() ?? {};
          _loading = false;
        });
      } else {
        // Default preferences
        setState(() {
          _preferences = {
            'tryon_completed': true,
            'tryon_processing': false,
            'tryon_failed': true,
            'calendar_reminders': true,
            'system_updates': true,
            'quiet_hours_enabled': false,
            'quiet_hours_start': '22:00',
            'quiet_hours_end': '08:00',
            'inactive_user_reduction': true,
          };
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePreference(String key, dynamic value) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      setState(() {
        _preferences[key] = value;
      });

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notifications')
          .set(_preferences, SetOptions(merge: true));
    } catch (e) {
      // Revert on error
      _loadPreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: FashionDesignSystem.backgroundIvory,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: FashionDesignSystem.backgroundWhite,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // AI Try-On Notifications
          _buildSectionHeader('AI Try-On Notifications'),
          _buildSwitchTile(
            'Try-On Completed',
            'Get notified when your try-on is ready',
            'tryon_completed',
            true,
          ),
          _buildSwitchTile(
            'Try-On Processing',
            'Silent background updates (recommended: off)',
            'tryon_processing',
            false,
          ),
          _buildSwitchTile(
            'Try-On Failed',
            'Get notified if try-on fails with retry option',
            'tryon_failed',
            true,
          ),
          
          const SizedBox(height: 24),
          
          // Calendar & Events
          _buildSectionHeader('Calendar & Events'),
          _buildSwitchTile(
            'Event Reminders',
            'Outfit planning and event reminders',
            'calendar_reminders',
            true,
          ),
          
          const SizedBox(height: 24),
          
          // System
          _buildSectionHeader('System'),
          _buildSwitchTile(
            'System Updates',
            'App updates and important announcements',
            'system_updates',
            true,
          ),
          
          const SizedBox(height: 24),
          
          // Quiet Hours
          _buildSectionHeader('Quiet Hours'),
          _buildSwitchTile(
            'Enable Quiet Hours',
            'Reduce notifications during selected hours',
            'quiet_hours_enabled',
            false,
          ),
          
          if (_preferences['quiet_hours_enabled'] == true) ...[
            const SizedBox(height: 16),
            _buildTimePicker('Start Time', 'quiet_hours_start', '22:00'),
            _buildTimePicker('End Time', 'quiet_hours_end', '08:00'),
          ],
          
          const SizedBox(height: 24),
          
          // Advanced
          _buildSectionHeader('Advanced'),
          _buildSwitchTile(
            'Reduce for Inactive Users',
            'Automatically reduce notifications if you\'re inactive',
            'inactive_user_reduction',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: CalendarTheme.headlineText().copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    String key,
    bool defaultValue,
  ) {
    final value = _preferences[key] as bool? ?? defaultValue;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: CalendarTheme.glassCard,
      child: SwitchListTile(
        title: Text(
          title,
          style: CalendarTheme.bodyText().copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: CalendarTheme.captionText(
            color: FashionDesignSystem.textSecondary,
          ),
        ),
        value: value,
        onChanged: (newValue) => _savePreference(key, newValue),
        activeColor: CalendarTheme.electricAccent,
      ),
    );
  }

  Widget _buildTimePicker(String title, String key, String defaultValue) {
    final timeStr = _preferences[key] as String? ?? defaultValue;
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: CalendarTheme.glassCard,
      child: ListTile(
        title: Text(
          title,
          style: CalendarTheme.bodyText().copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Text(
          timeStr,
          style: CalendarTheme.bodyText(
            color: CalendarTheme.electricAccent,
          ),
        ),
        onTap: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(hour: hour, minute: minute),
          );
          
          if (time != null) {
            final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
            await _savePreference(key, timeStr);
          }
        },
      ),
    );
  }
}
