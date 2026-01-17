import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../routes.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Fashion questions
  String? _fashionStyle;
  String? _favoriteColors;
  String? _occasion;
  String? _budget;
  String? _shoppingFrequency;
  String? _styleInspiration;

  // Body inputs
  double _height = 170.0; // cm
  String? _gender;
  String? _bodyType;

  final List<String> _fashionStyles = [
    'Casual',
    'Formal',
    'Streetwear',
    'Bohemian',
    'Minimalist',
    'Vintage',
    'Athletic',
  ];

  final List<String> _colors = [
    'Black & White',
    'Neutrals',
    'Bold Colors',
    'Pastels',
    'Earth Tones',
  ];

  final List<String> _occasions = [
    'Everyday Wear',
    'Work/Office',
    'Special Events',
    'Weekend',
    'Travel',
  ];

  final List<String> _budgets = [
    'Budget-Friendly',
    'Mid-Range',
    'Premium',
    'Luxury',
  ];

  final List<String> _frequencies = [
    'Weekly',
    'Monthly',
    'Seasonally',
    'Rarely',
  ];

  final List<String> _inspirations = [
    'Celebrities',
    'Fashion Bloggers',
    'Street Style',
    'Runway',
    'Friends',
  ];

  final List<String> _genders = ['Male', 'Female', 'Non-Binary', 'Prefer not to say'];
  final List<String> _bodyTypes = ['Slim', 'Athletic', 'Average', 'Curvy', 'Plus Size'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 7) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _fashionStyle != null;
      case 1:
        return _favoriteColors != null;
      case 2:
        return _occasion != null;
      case 3:
        return _budget != null;
      case 4:
        return _shoppingFrequency != null;
      case 5:
        return _styleInspiration != null;
      case 6:
        return _gender != null && _bodyType != null;
      default:
        return true;
    }
  }

  Future<void> _completeOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final onboardingData = OnboardingData(
        fashionStyle: _fashionStyle!,
        favoriteColors: _favoriteColors!,
        occasion: _occasion!,
        budget: _budget!,
        shoppingFrequency: _shoppingFrequency!,
        styleInspiration: _styleInspiration!,
        bodyInputs: BodyInputs(
          height: _height,
          gender: _gender!,
          bodyType: _bodyType!,
        ),
      );

      final authService = AuthService();
      await authService.updateOnboardingData(user.uid, onboardingData);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.avatarCreation);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save onboarding: $e')),
        );
      }
    }
  }

  Widget _buildQuestionStep({
    required String question,
    required List<String> options,
    required String? selectedValue,
    required Function(String) onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Text(
            question,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 48),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = selectedValue == option;
                return _buildOptionCard(
                  option,
                  isSelected,
                  () => onSelect(option),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(String option, bool isSelected, VoidCallback onTap) {
    return Card(
      color: isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Text(
            option,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ).animate().scale(
          duration: 200.ms,
          begin: const Offset(0.95, 0.95),
        );
  }

  Widget _buildBodyInputsStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Text(
            'Tell us about yourself',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 48),
          // Height
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Height: ${_height.toInt()} cm',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _height,
                    min: 140,
                    max: 220,
                    divisions: 80,
                    label: '${_height.toInt()} cm',
                    onChanged: (value) {
                      setState(() => _height = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Gender
          Text(
            'Gender',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _genders.map((gender) {
              final isSelected = _gender == gender;
              return ChoiceChip(
                label: Text(gender),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _gender = selected ? gender : null);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Body Type
          Text(
            'Body Type',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _bodyTypes.map((type) {
              final isSelected = _bodyType == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _bodyType = selected ? type : null);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step ${_currentStep + 1} of 7'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildQuestionStep(
            question: 'What\'s your fashion style?',
            options: _fashionStyles,
            selectedValue: _fashionStyle,
            onSelect: (value) => setState(() => _fashionStyle = value),
          ),
          _buildQuestionStep(
            question: 'What colors do you love?',
            options: _colors,
            selectedValue: _favoriteColors,
            onSelect: (value) => setState(() => _favoriteColors = value),
          ),
          _buildQuestionStep(
            question: 'Where do you dress for most?',
            options: _occasions,
            selectedValue: _occasion,
            onSelect: (value) => setState(() => _occasion = value),
          ),
          _buildQuestionStep(
            question: 'What\'s your budget range?',
            options: _budgets,
            selectedValue: _budget,
            onSelect: (value) => setState(() => _budget = value),
          ),
          _buildQuestionStep(
            question: 'How often do you shop?',
            options: _frequencies,
            selectedValue: _shoppingFrequency,
            onSelect: (value) => setState(() => _shoppingFrequency = value),
          ),
          _buildQuestionStep(
            question: 'Where do you get style inspiration?',
            options: _inspirations,
            selectedValue: _styleInspiration,
            onSelect: (value) => setState(() => _styleInspiration = value),
          ),
          _buildBodyInputsStep(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: _canProceed() ? _nextStep : null,
            child: Text(_currentStep == 6 ? 'Complete' : 'Next'),
          ),
        ),
      ),
    );
  }
}

