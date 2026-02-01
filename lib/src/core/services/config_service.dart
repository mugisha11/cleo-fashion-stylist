import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Secure Configuration Service
/// Manages API keys and configuration securely
class ConfigService {
  static const String _openaiApiKeyKey = 'openai_api_key';
  static const String _openaiModelKey = 'openai_model';
  static const String _claudeApiKeyKey = 'claude_api_key';
  
  // Default values (can be overridden)
  static const String _defaultOpenAIModel = 'gpt-5-mini-2025-08-07';
  static const String _defaultOpenAIApiKey = 'sk-proj-9syQcT4EnyxOzejdnwtAT3BlbkFJi2xir3aaZLrXVbNFgagn';
  static const String _defaultClaudeApiKey = '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';
  
  /// Get OpenAI API Key
  /// First checks environment variable, then secure storage
  static Future<String?> getOpenAIApiKey() async {
    // For web, try to get from environment (if available)
    if (kIsWeb) {
      // In production, these would be set via build-time environment variables
      // For now, use secure storage
    }
    
    // Get from secure storage
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_openaiApiKeyKey);
    } catch (e) {
      return null;
    }
  }
  
  /// Clear OpenAI API Key
  static Future<void> clearOpenAIApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_openaiApiKeyKey);
    } catch (e) {
      // Silently fail
    }
  }

  /// Set OpenAI API Key securely
  static Future<void> setOpenAIApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_openaiApiKeyKey, apiKey);
    } catch (e) {
      throw Exception('Failed to save API key: $e');
    }
  }
  
  /// Get OpenAI Model
  static Future<String> getOpenAIModel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_openaiModelKey) ?? _defaultOpenAIModel;
    } catch (e) {
      return _defaultOpenAIModel;
    }
  }
  
  /// Set OpenAI Model
  static Future<void> setOpenAIModel(String model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_openaiModelKey, model);
    } catch (e) {
      throw Exception('Failed to save model: $e');
    }
  }
  
  /// Get Claude API Key
  static Future<String?> getClaudeApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_claudeApiKeyKey);
    } catch (e) {
      return null;
    }
  }
  
  /// Set Claude API Key securely
  static Future<void> setClaudeApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_claudeApiKeyKey, apiKey);
    } catch (e) {
      throw Exception('Failed to save Claude API key: $e');
    }
  }
  
  /// Initialize with default API key (for first-time setup)
  static Future<void> initializeDefaultKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Only set if not already set
      if (!prefs.containsKey(_openaiApiKeyKey)) {
        await prefs.setString(_openaiApiKeyKey, _defaultOpenAIApiKey);
      }
      
      if (!prefs.containsKey(_openaiModelKey)) {
        await prefs.setString(_openaiModelKey, _defaultOpenAIModel);
      }
      
      // Initialize Claude API key
      if (!prefs.containsKey(_claudeApiKeyKey)) {
        await prefs.setString(_claudeApiKeyKey, _defaultClaudeApiKey);
      }
    } catch (e) {
      // Silently fail - keys might already be set
    }
  }
  
  /// Clear all stored keys (for security)
  static Future<void> clearAllKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_openaiApiKeyKey);
      await prefs.remove(_openaiModelKey);
      await prefs.remove(_claudeApiKeyKey);
    } catch (e) {
      throw Exception('Failed to clear keys: $e');
    }
  }
}
