import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'strava_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strava Upload Tool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Strava FIT Uploader'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final StravaService _stravaService = StravaService();
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  String _status = 'Initializing...';
  bool _isConnected = false;
  bool _isUploading = false;
  String? _uploadResult;

  @override
  void initState() {
    super.initState();
    _initStrava();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _initStrava() async {
    await _stravaService.init();
    setState(() {
      _isConnected = _stravaService.isAuthenticated;
      _status = _isConnected ? 'Connected to Strava' : 'Not Connected';
    });
  }

  void _initDeepLinks() {
    _sub = _appLinks.uriLinkStream.listen((uri) {
      if (uri.toString().startsWith('starvaauto://localhost')) {
        _handleAuthCallback(uri);
      }
    });
  }

  Future<void> _handleAuthCallback(Uri uri) async {
    setState(() {
      _status = 'Authorizing...';
    });

    try {
      final code = uri.queryParameters['code'];
      if (code != null) {
        // Exchange code for token
        // 注意：StravaService._exchangeToken 是私有的，需要公开或者通过 handleAuthCallback 调用
        // 这里假设 StravaService 内部处理
        // 为了简单，我需要在 StravaService 中暴露一个方法，或者让 handleAuthCallback 处理所有逻辑
        // 我已经在 StravaService 中实现了 handleAuthCallback，但是它需要 url 字符串
        // 这里直接调用 _stravaService.handleAuthCallback
        
        // Wait, StravaService.handleAuthCallback takes a string URL.
        // Let's modify StravaService to handle the code exchange directly if we pass the code, 
        // or just use the URL string.
        
        // Let's assume handleAuthCallback handles everything.
        // But wait, the previous implementation of handleAuthCallback returns a Future<bool>.
        
        // Re-checking StravaService implementation...
        // It has `Future<bool> handleAuthCallback(String url)` which parses the URL.
        // So I can pass uri.toString()
        
        final success = await _stravaService.handleAuthCallback(uri.toString());
        
        setState(() {
          _isConnected = success;
          _status = success ? 'Connected successfully!' : 'Authorization failed.';
        });
      } else {
        setState(() {
          _status = 'Authorization denied or invalid response.';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error during auth: $e';
      });
    }
  }

  Future<void> _connectToStrava() async {
    if (!_stravaService.hasCredentials) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure Client ID and Secret in lib/secrets.dart')),
      );
      return;
    }

    try {
      final url = _stravaService.getAuthorizationUrl();
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        setState(() {
          _status = 'Could not launch browser for auth.';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error initiating auth: $e';
      });
    }
  }

  Future<void> _disconnect() async {
    await _stravaService.logout();
    setState(() {
      _isConnected = false;
      _status = 'Disconnected';
    });
  }

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['fit'],
    );

    if (result != null) {
      setState(() {
        _isUploading = true;
        _uploadResult = null;
        _status = 'Uploading...';
      });

      try {
        File file = File(result.files.single.path!);
        final resultMsg = await _stravaService.uploadFitFile(file);
        setState(() {
          _uploadResult = resultMsg;
          _status = 'Upload Complete';
        });
      } catch (e) {
        setState(() {
          _uploadResult = 'Error: $e';
          _status = 'Upload Failed';
        });
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Settings Section
              if (!_isConnected) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Strava Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _connectToStrava,
                          child: const Text('Connect with Strava'),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                 Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 48),
                        const SizedBox(height: 10),
                        const Text('Connected to Strava', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _disconnect,
                          child: const Text('Disconnect'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 30),

              // Status Display
              Text(
                _status,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // Upload Section
              if (_isConnected) ...[
                if (_isUploading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: _pickAndUploadFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Select .FIT File to Upload'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                
                if (_uploadResult != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(_uploadResult!),
                  ),
                ]
              ],
            ],
          ),
        ),
      ),
    );
  }
}
