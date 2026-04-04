import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'strava_service.dart';
import 'log_manager.dart';
import 'settings_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'theme_manager.dart';
import 'locale_manager.dart';
import 'privacy_policy_page.dart';
import 'background_service.dart';
import 'onelap_manager.dart';
import 'update_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundService.initialize();
  runApp(const UpstraApp());
}

class UpstraApp extends StatelessWidget {
  const UpstraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ThemeManager(), LocaleManager()]),
      builder: (context, child) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          locale: LocaleManager().locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('zh'), // Chinese
          ],
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFC4C02), // Strava Orange
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF7F7F7),
            appBarTheme: const AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle.dark,
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
              iconTheme: IconThemeData(color: Colors.black87),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
              ),
              color: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFC4C02),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFC4C02),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle.light,
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              iconTheme: IconThemeData(color: Colors.white),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
              ),
              color: const Color(0xFF1E1E1E),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFC4C02),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          themeMode: ThemeManager().themeMode,
          home: const DashboardPage(),
          // Fix for "Failed to handle route information"
          onGenerateRoute: (settings) {
            // If this is the auth redirect, show a transient loading page instead of pushing a new DashboardPage
            final routeName = settings.name?.toLowerCase() ?? '';
            if (routeName.contains('code=') || routeName.startsWith('starvaauto://')) {
              return MaterialPageRoute(
                builder: (context) => const AuthCallbackPage(),
              );
            }
            return MaterialPageRoute(
              builder: (context) => const DashboardPage(),
            );
          },
        );
      },
    );
  }
}

class AuthCallbackPage extends StatefulWidget {
  const AuthCallbackPage({super.key});

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  @override
  void initState() {
    super.initState();
    // Automatically close this page after a short delay to reveal the updated DashboardPage underneath
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFFFC4C02),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.finalizingConnection,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  final StravaService _stravaService = StravaService();
  final _appLinks = AppLinks();
  
  StreamSubscription<Uri>? _sub;
  StreamSubscription<List<SharedMediaFile>>? _intentSub;

  // State
  bool _isConnected = false;
  bool _isUploading = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initStrava();
    _initDeepLinks();
    _initSharingIntent();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrivacyPolicy().then((_) {
        _checkOneLapMigration();
        if (mounted) {
          UpdateManager.checkUpdate(context, showNoUpdateMsg: false);
        }
      });
    });
  }

  Future<void> _checkOneLapMigration() async {
    final prefs = await SharedPreferences.getInstance();
    final migrationDone = prefs.getBool('onelap_migration_v2_done') ?? false;
    
    // 只有在没处理过迁移、且用户已经登录了顽鹿的情况下才提示
    await OneLapManager().init();
    if (!migrationDone && OneLapManager().username != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text("重要：顽鹿同步机制升级"),
            content: const Text(
                "由于近期顽鹿官方 API 接口发生了不兼容的变动（丢失了唯一记录标识），我们不得不升级了去重判定机制。\n\n"
                "这会导致您所有的历史骑行记录被识别为“全新”记录，如果直接同步，可能会引发大量历史数据被重新上传到 Strava（引发重复或错误）。\n\n"
                "⚠️ 强烈建议：点击【重置并从现在开始】。我们将为您在本地标记所有历史记录为已同步，下一次只会同步新产生的运动。\n"
                "（此弹窗仅会显示一次，这是由于顽鹿官方变动导致的无奈之举，敬请谅解！）"),
            actions: [
              TextButton(
                onPressed: () async {
                  await prefs.setBool('onelap_migration_v2_done', true);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text("不了，继续全量同步", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  await OneLapManager().markAllAsSynced();
                  await prefs.setBool('onelap_migration_v2_done', true);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text("重置并从现在开始（推荐）"),
              ),
            ],
          );
        },
      );
    } else if (!migrationDone) {
      // 如果还没登录顽鹿，就不需要弹窗，直接标记完成
      await prefs.setBool('onelap_migration_v2_done', true);
    }
  }

  Future<void> _checkPrivacyPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    final agreed = prefs.getBool('privacy_agreed') ?? false;
    if (!agreed && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        useSafeArea: false,
        builder: (context) => const PrivacyPolicyPage(isDialog: true),
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _intentSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _addLog(String message, {bool isError = false}) {
    LogManager().addLog(message, isError: isError);
  }

  // --- Initialization & Listeners ---

  Future<void> _initStrava() async {
    try {
      await _stravaService.init();
      setState(() {
        _isConnected = _stravaService.isAuthenticated;
      });
      if (_isConnected) {
        _addLog("Connected to Strava session.");
      } else {
        _addLog("Welcome! Please connect to Strava.");
      }
    } catch (e) {
      _addLog("Failed to initialize Strava service: $e", isError: true);
    }
  }

  void _initDeepLinks() {
    _sub = _appLinks.uriLinkStream.listen((uri) {
      _addLog("Received link: $uri");
      if (uri.scheme == 'starvaauto') {
        _handleAuthCallback(uri);
      } else if (uri.scheme == 'file') {
        // Handle file open request (iOS "Open with...")
        try {
          final filePath = uri.toFilePath();
          if (filePath.toLowerCase().endsWith('.fit')) {
            _addLog("Detected FIT file from link: $filePath");
            // Delay slightly to ensure UI is ready if app was just launched
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _showUploadDialog(File(filePath));
            });
          } else {
            _addLog("Ignored non-FIT file link: ${uri.pathSegments.last}", isError: true);
          }
        } catch (e) {
          _addLog("Error parsing file link: $e", isError: true);
        }
      }
    }, onError: (err) {
      _addLog("Deep link error: $err", isError: true);
    });
  }

  void _initSharingIntent() {
    // While running
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) _handleSharedFiles(value);
    }, onError: (err) {
      _addLog("Sharing intent error: $err", isError: true);
    });

    // Initial launch
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) _handleSharedFiles(value);
    });
  }

  // --- Logic ---

  Future<void> _handleAuthCallback(Uri uri) async {
    _addLog("Processing authorization...");
    try {
      final success = await _stravaService.handleAuthCallback(uri.toString());
      if (mounted) {
        setState(() {
          _isConnected = success;
        });
        if (success) {
          _addLog("Authorization successful! Ready to upload.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.connectedSuccess),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _addLog("Authorization failed.", isError: true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.authFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _addLog("Auth error: $e", isError: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.connectionError(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _connectToStrava() async {
    if (!_stravaService.hasCredentials) {
      _addLog("Missing Client ID/Secret configuration.", isError: true);
      return;
    }
    try {
      final url = _stravaService.getAuthorizationUrl();
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        _addLog("Launched Strava login...");
      } else {
        _addLog("Could not launch browser.", isError: true);
      }
    } catch (e) {
      _addLog("Auth launch error: $e", isError: true);
    }
  }

  Future<void> _confirmDisconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logoutConfirmationTitle),
        content: Text(AppLocalizations.of(context)!.logoutConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.confirmButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _disconnect();
    }
  }

  Future<void> _disconnect() async {
    await _stravaService.logout();
    setState(() {
      _isConnected = false;
    });
    _addLog("Disconnected from Strava.");
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    _addLog("Received shared files: ${files.length}");
    for (var file in files) {
      _addLog("Checking file: ${file.path}");
      if (file.path.toLowerCase().endsWith('.fit')) {
        _showUploadDialog(File(file.path));
        break; 
      } else {
        _addLog("Ignored non-FIT file: ${file.path.split('/').last}", isError: true);
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['fit'],
      );

      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        _showUploadDialog(File(result.files.single.path!));
      }
    } catch (e) {
      _addLog("File picker error: $e", isError: true);
    }
  }

  void _showUploadDialog(File file) {
    if (!_isConnected) {
      _addLog("Please connect to Strava to upload ${file.path.split('/').last}", isError: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseConnectFirst)),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context)!.uploadActivityTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center, color: Color(0xFFFC4C02)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      file.path.split('/').last,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.cancelButton),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog first
                      _uploadFile(file);
                    },
                    child: Text(AppLocalizations.of(context)!.uploadNowButton),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFile(File file) async {
    File uploadFile = file;
    
    // iOS Sandboxing Fix: Copy file to app's temp directory
    if (Platform.isIOS) {
      try {
        final tempDir = await getTemporaryDirectory();
        final newPath = '${tempDir.path}/${file.path.split('/').last}';
        final newFile = File(newPath);
        
        // Read bytes from the original (restricted) path and write to our temp path
        final bytes = await file.readAsBytes();
        await newFile.writeAsBytes(bytes);
        
        uploadFile = newFile;
        _addLog("Copied file to temp: $newPath");
      } catch (e) {
        _addLog("Failed to copy file: $e", isError: true);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(AppLocalizations.of(context)!.cannotAccessFile(file.path))),
           );
        }
        return;
      }
    }

    setState(() {
      _isUploading = true;
    });
    // Navigator.of(context).pop(); // REMOVED: Dialog should be closed by the caller
    
    final fileName = uploadFile.path.split('/').last;
    _addLog("Starting upload: $fileName...");

    try {
      final resultMsg = await _stravaService.uploadFitFile(uploadFile);
      _addLog("Success: $resultMsg");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.uploadFileSuccess(fileName)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _addLog("Upload failed: $e", isError: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.uploadFileFailed(fileName)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Status Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildStatusCard(theme),
            ),
            
            const SizedBox(height: 30),
            
            // Main Action Area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildMainActionArea(theme),
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isConnected
              ? [const Color(0xFFFC4C02), const Color(0xFFFF8243)]
              : [theme.cardColor, theme.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _isConnected ? const Color(0xFFFC4C02).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isConnected ? Icons.check_rounded : Icons.link_off_rounded,
              color: _isConnected ? Colors.white : theme.iconTheme.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected 
                    ? AppLocalizations.of(context)!.statusConnected 
                    : AppLocalizations.of(context)!.statusNotConnected,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _isConnected ? Colors.white : theme.textTheme.titleMedium?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isConnected 
                    ? AppLocalizations.of(context)!.readyToSync 
                    : AppLocalizations.of(context)!.connectToStart,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _isConnected ? Colors.white.withValues(alpha: 0.9) : theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            color: _isConnected ? Colors.white : theme.iconTheme.color,
            tooltip: AppLocalizations.of(context)!.settingsTooltip,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
              if (mounted) {
                setState(() {
                  _isConnected = _stravaService.isAuthenticated;
                });
              }
            },
          ),
          if (_isConnected) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              color: Colors.white,
              tooltip: AppLocalizations.of(context)!.disconnectTooltip,
              onPressed: _confirmDisconnect,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainActionArea(ThemeData theme) {
    if (!_isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.unlockUpload,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: _connectToStrava,
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/strava.png',
                height: 48,
              ),
            ),
          ],
        ),
      );
    }

    if (_isUploading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: const Color(0xFFFC4C02).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_upload_rounded, size: 60, color: Color(0xFFFC4C02)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.uploading,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _pickAndUploadFile,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.5),
            style: BorderStyle.none,
          ),
          boxShadow: [
             BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: theme.dividerColor,
            strokeWidth: 2,
            gap: 10,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_rounded, size: 40, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.tapToSelect,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.orShare,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({required this.color, this.strokeWidth = 1.0, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(24),
      ));

    final Path dashedPath = _dashPath(path, dashArray: CircularIntervalList<double>([10, gap]));
    canvas.drawPath(dashedPath, paint);
  }

  Path _dashPath(Path source, {required CircularIntervalList<double> dashArray}) {
    final Path dest = Path();
    for (final ui.PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = dashArray.next;
        if (draw) {
          dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CircularIntervalList<T> {
  final List<T> _values;
  int _index = 0;

  CircularIntervalList(this._values);

  T get next {
    if (_index >= _values.length) {
      _index = 0;
    }
    return _values[_index++];
  }
}
