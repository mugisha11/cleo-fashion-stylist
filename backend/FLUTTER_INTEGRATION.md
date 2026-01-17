# Flutter Integration Guide for Virtual Try-On API

## Overview

This guide shows how to integrate the Virtual Try-On API (`/api/tryon`) into your Flutter application.

## API Endpoint

**POST** `http://your-backend-url/api/tryon`

### Request Body

```json
{
  "user_image_url": "https://example.com/user-photo.jpg",
  "garment_image_urls": [
    "https://example.com/garment1.jpg",
    "https://example.com/garment2.jpg"
  ],
  "user_id": "user123",
  "trace_id": "optional-trace-id"
}
```

### Response

```json
{
  "status": "success",
  "result_image_url": "https://cdn.example.com/result.jpg",
  "result_image_base64": "base64-encoded-image",
  "metrics": {
    "face_similarity": 0.98,
    "garment_coverage": 0.15,
    "total_duration": 12.5
  },
  "trace_id": "uuid-here",
  "stages": {
    "stage1": {"duration": 0.5, "status": "success"},
    "stage2": {"duration": 2.1, "status": "success"},
    ...
  }
}
```

## Flutter Implementation

### 1. Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  image_picker: ^1.0.4
  cached_network_image: ^3.3.0
  flutter_spinkit: ^5.1.0  # For loading animations
```

### 2. API Service Class

Create `lib/services/tryon_service.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class TryOnService {
  final String baseUrl;
  
  TryOnService({required this.baseUrl});
  
  Future<TryOnResponse> tryOn({
    required String userImageUrl,
    required List<String> garmentImageUrls,
    String? userId,
    String? traceId,
    Function(String stage)? onStageUpdate,
  }) async {
    try {
      // Stage 1: Validating images
      onStageUpdate?.call("Validating images...");
      
      final requestBody = {
        'user_image_url': userImageUrl,
        'garment_image_urls': garmentImageUrls,
        if (userId != null) 'user_id': userId,
        if (traceId != null) 'trace_id': traceId,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/tryon'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TryOnResponse.fromJson(data);
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Try-on failed: $e');
    }
  }
  
  Future<String> uploadImage(File imageFile) async {
    // Upload image to your storage/CDN and return URL
    // Implementation depends on your storage solution
    // This is a placeholder
    return 'https://your-cdn.com/image.jpg';
  }
}

class TryOnResponse {
  final String status;
  final String? resultImageUrl;
  final String? resultImageBase64;
  final Map<String, dynamic>? metrics;
  final String traceId;
  final Map<String, dynamic>? stages;
  final String? error;
  final String? stageFailed;
  
  TryOnResponse({
    required this.status,
    this.resultImageUrl,
    this.resultImageBase64,
    this.metrics,
    required this.traceId,
    this.stages,
    this.error,
    this.stageFailed,
  });
  
  factory TryOnResponse.fromJson(Map<String, dynamic> json) {
    return TryOnResponse(
      status: json['status'],
      resultImageUrl: json['result_image_url'],
      resultImageBase64: json['result_image_base64'],
      metrics: json['metrics'],
      traceId: json['trace_id'],
      stages: json['stages'],
      error: json['error'],
      stageFailed: json['stage_failed'],
    );
  }
  
  bool get isSuccess => status == 'success';
}
```

### 3. Try-On Screen Widget

Create `lib/screens/tryon_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/tryon_service.dart';

class TryOnScreen extends StatefulWidget {
  @override
  _TryOnScreenState createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  final TryOnService _tryOnService = TryOnService(
    baseUrl: 'http://your-backend-url', // Replace with your backend URL
  );
  
  String? _userImageUrl;
  List<String> _garmentImageUrls = [];
  String? _currentStage;
  bool _isProcessing = false;
  TryOnResponse? _result;
  String? _error;
  
  Future<void> _pickUserImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      // Upload image and get URL
      // For demo, using file path directly (in production, upload to storage)
      setState(() {
        _userImageUrl = image.path;
      });
    }
  }
  
  void _addGarment(String imageUrl) {
    setState(() {
      _garmentImageUrls.add(imageUrl);
    });
  }
  
  Future<void> _processTryOn() async {
    if (_userImageUrl == null || _garmentImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select user image and at least one garment')),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _currentStage = 'Initializing...';
      _error = null;
      _result = null;
    });
    
    try {
      final result = await _tryOnService.tryOn(
        userImageUrl: _userImageUrl!,
        garmentImageUrls: _garmentImageUrls,
        userId: 'user123', // Get from auth
        onStageUpdate: (stage) {
          setState(() {
            _currentStage = stage;
          });
        },
      );
      
      setState(() {
        _isProcessing = false;
        _result = result;
        if (!result.isSuccess) {
          _error = result.error ?? 'Try-on failed';
        }
      });
      
      if (result.isSuccess) {
        _showResultDialog(result);
      } else {
        _showErrorDialog(result.error ?? 'Try-on failed');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = e.toString();
      });
      _showErrorDialog(e.toString());
    }
  }
  
  void _showResultDialog(TryOnResponse result) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Try-On Complete!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              if (result.resultImageUrl != null)
                CachedNetworkImage(
                  imageUrl: result.resultImageUrl!,
                  width: 300,
                  height: 400,
                  fit: BoxFit.contain,
                )
              else if (result.resultImageBase64 != null)
                Image.memory(
                  base64Decode(result.resultImageBase64!),
                  width: 300,
                  height: 400,
                  fit: BoxFit.contain,
                ),
              SizedBox(height: 16),
              if (result.metrics != null)
                Text('Face Similarity: ${result.metrics!['face_similarity']?.toStringAsFixed(2) ?? 'N/A'}'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Try-On'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Image Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('User Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    if (_userImageUrl != null)
                      Image.network(_userImageUrl!, height: 200, fit: BoxFit.contain)
                    else
                      Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Center(child: Text('No image selected')),
                      ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _pickUserImage,
                      child: Text('Select User Photo'),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Garments Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Garments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _garmentImageUrls.map((url) {
                        return Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: url,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _garmentImageUrls.remove(url);
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Add garment URL (in production, use image picker + upload)
                        _addGarment('https://example.com/garment.jpg');
                      },
                      child: Text('Add Garment'),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Processing Status
            if (_isProcessing)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SpinKitCircle(color: Colors.blue),
                      SizedBox(height: 16),
                      Text(_currentStage ?? 'Processing...'),
                    ],
                  ),
                ),
              ),
            
            // Process Button
            ElevatedButton(
              onPressed: _isProcessing ? null : _processTryOn,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isProcessing ? 'Processing...' : 'Try On',
                style: TextStyle(fontSize: 18),
              ),
            ),
            
            // Error Display
            if (_error != null)
              Card(
                color: Colors.red[100],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(_error!, style: TextStyle(color: Colors.red[900])),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

### 4. Usage Example

```dart
// In your main app or navigation
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => TryOnScreen()),
);
```

## Error Handling

The API returns structured errors:

```dart
if (!response.isSuccess) {
  // Handle error
  print('Error: ${response.error}');
  print('Failed at stage: ${response.stageFailed}');
}
```

## Real-time Stage Updates

The API provides stage information in the response:

```dart
if (result.stages != null) {
  result.stages!.forEach((stage, info) {
    print('$stage: ${info['status']} (${info['duration']}s)');
  });
}
```

## Best Practices

1. **Image Upload**: Upload images to your CDN/storage before sending URLs to API
2. **Caching**: Cache result images for better UX
3. **Loading States**: Show clear loading indicators for each stage
4. **Error Recovery**: Allow users to retry failed requests
5. **Trace IDs**: Use trace IDs for debugging and support

## Testing

Test with sample images:

```dart
final result = await tryOnService.tryOn(
  userImageUrl: 'https://example.com/user.jpg',
  garmentImageUrls: ['https://example.com/shirt.jpg'],
);
```
