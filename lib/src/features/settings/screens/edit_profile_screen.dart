import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/settings_theme.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  void _loadInitialValues(WidgetRef ref) {
    final user = ref.read(authStateProvider).value;
    if (_nameController.text.isEmpty) {
      _nameController.text = user?.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());
        await user.reload();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    
    // Load initial values on first build
    if (_nameController.text.isEmpty && user?.displayName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialValues(ref);
      });
    }

    return Scaffold(
      backgroundColor: SettingsTheme.backgroundLightBlue,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: SettingsTheme.backgroundWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: SettingsTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SettingsTheme.spacingMD),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: SettingsTheme.spacingLG),
              CircleAvatar(
                radius: 60,
                backgroundColor: SettingsTheme.primaryBlue,
                child: user?.photoURL != null
                    ? ClipOval(
                        child: Image.network(
                          user!.photoURL!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        user?.displayName?.substring(0, 1).toUpperCase() ??
                            user?.email?.substring(0, 1).toUpperCase() ??
                            'U',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: SettingsTheme.spacingXL),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SettingsTheme.radiusSM),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SettingsTheme.radiusSM),
                    borderSide: const BorderSide(color: SettingsTheme.primaryBlue, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: SettingsTheme.spacingLG),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SettingsTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: SettingsTheme.spacingMD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SettingsTheme.radiusSM),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

