import 'package:equatable/equatable.dart';

/// Settings State Model
class SettingsState extends Equatable {
  final bool isLoading;
  final String? error;
  
  // AI & Try-On Settings
  final bool autoRecommendations;
  final bool highQualityRendering;
  final bool backgroundPreservation;
  
  // Notifications
  final bool pushNotifications;
  final bool outfitReminders;
  final bool recommendationAlerts;
  
  // Fashion Preferences
  final double? height;
  final String? bodyType;
  final List<String> preferredStyles;
  final List<String> colorPreferences;
  final List<String> eventPreferences;
  
  const SettingsState({
    this.isLoading = false,
    this.error,
    this.autoRecommendations = true,
    this.highQualityRendering = true,
    this.backgroundPreservation = true,
    this.pushNotifications = true,
    this.outfitReminders = true,
    this.recommendationAlerts = true,
    this.height,
    this.bodyType,
    this.preferredStyles = const [],
    this.colorPreferences = const [],
    this.eventPreferences = const [],
  });
  
  SettingsState copyWith({
    bool? isLoading,
    String? error,
    bool? autoRecommendations,
    bool? highQualityRendering,
    bool? backgroundPreservation,
    bool? pushNotifications,
    bool? outfitReminders,
    bool? recommendationAlerts,
    double? height,
    String? bodyType,
    List<String>? preferredStyles,
    List<String>? colorPreferences,
    List<String>? eventPreferences,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      autoRecommendations: autoRecommendations ?? this.autoRecommendations,
      highQualityRendering: highQualityRendering ?? this.highQualityRendering,
      backgroundPreservation: backgroundPreservation ?? this.backgroundPreservation,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      outfitReminders: outfitReminders ?? this.outfitReminders,
      recommendationAlerts: recommendationAlerts ?? this.recommendationAlerts,
      height: height ?? this.height,
      bodyType: bodyType ?? this.bodyType,
      preferredStyles: preferredStyles ?? this.preferredStyles,
      colorPreferences: colorPreferences ?? this.colorPreferences,
      eventPreferences: eventPreferences ?? this.eventPreferences,
    );
  }
  
  @override
  List<Object?> get props => [
    isLoading,
    error,
    autoRecommendations,
    highQualityRendering,
    backgroundPreservation,
    pushNotifications,
    outfitReminders,
    recommendationAlerts,
    height,
    bodyType,
    preferredStyles,
    colorPreferences,
    eventPreferences,
  ];
}

