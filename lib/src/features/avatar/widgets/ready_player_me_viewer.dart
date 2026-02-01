import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/grok_design_system.dart';

/// Ready Player Me Avatar Viewer
/// Renders 3D avatar using Ready Player Me GLB model
class ReadyPlayerMeViewer extends StatefulWidget {
  final String avatarId;
  final double? width;
  final double? height;

  const ReadyPlayerMeViewer({
    super.key,
    required this.avatarId,
    this.width,
    this.height,
  });

  @override
  State<ReadyPlayerMeViewer> createState() => _ReadyPlayerMeViewerState();
}

class _ReadyPlayerMeViewerState extends State<ReadyPlayerMeViewer> {
  late WebViewController _controller;
  bool _isLoading = true;

  String get _avatarUrl {
    final params = {
      'quality': 'high',
      'lod': '0',
      'textureQuality': 'high',
      'textureFormat': 'png',
      'pose': 'A',
      'useDracoMeshCompression': 'true',
    };
    
    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    return 'https://models.readyplayer.me/${widget.avatarId}.glb?$queryString';
  }

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(GrokDesignSystem.backgroundOffWhite)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(_buildViewerHTML()));
  }

  String _buildViewerHTML() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script type="module" src="https://unpkg.com/@google/model-viewer/dist/model-viewer.min.js"></script>
  <style>
    body {
      margin: 0;
      padding: 0;
      background: #FAFAFA;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
    }
    model-viewer {
      width: 100%;
      height: 100%;
    }
  </style>
</head>
<body>
  <model-viewer
    src="$_avatarUrl"
    alt="3D Avatar"
    auto-rotate
    camera-controls
    interaction-policy="allow-when-focused"
    style="width: 100%; height: 100%;"
  ></model-viewer>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: GrokDesignSystem.backgroundLightGray,
        borderRadius: BorderRadius.circular(GrokDesignSystem.radiusLG),
      ),
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(GrokDesignSystem.primaryCharcoal),
              ),
            ),
        ],
      ),
    );
  }
}

