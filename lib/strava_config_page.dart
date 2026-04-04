import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'strava_service.dart';
import 'l10n/generated/app_localizations.dart';

class StravaConfigPage extends StatefulWidget {
  final StravaService stravaService;
  
  const StravaConfigPage({super.key, required this.stravaService});

  @override
  State<StravaConfigPage> createState() => _StravaConfigPageState();
}

class _StravaConfigPageState extends State<StravaConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomConfig();
  }

  Future<void> _loadCustomConfig() async {
    final customId = await _storage.read(key: 'strava_custom_client_id');
    final customSecret = await _storage.read(key: 'strava_custom_client_secret');
    
    if (mounted) {
      setState(() {
        if (customId != null) _clientIdController.text = customId;
        if (customSecret != null) _clientSecretController.text = customSecret;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { _isLoading = true; });
    
    await widget.stravaService.saveCustomCredentials(
      _clientIdController.text, 
      _clientSecretController.text
    );
    
    if (mounted) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.configSavedMessage),
          backgroundColor: Colors.green,
        )
      );
      Navigator.pop(context, true); // Return true to indicate config changed
    }
  }

  Future<void> _clearConfig() async {
    setState(() { _isLoading = true; });
    
    await widget.stravaService.clearCustomCredentials();
    _clientIdController.clear();
    _clientSecretController.clear();
    
    if (mounted) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.configClearedMessage),
          backgroundColor: Colors.orange,
        )
      );
      Navigator.pop(context, true); // Return true to indicate config changed
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.stravaConfigPageTitle),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.stravaConfigDescription,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _clientIdController,
                    decoration: InputDecoration(
                      labelText: l10n.stravaClientIdLabel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter Client ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _clientSecretController,
                    decoration: InputDecoration(
                      labelText: l10n.stravaClientSecretLabel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.key_outlined),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter Client Secret';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveConfig,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(l10n.saveButton),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: widget.stravaService.hasCustomCredentials ? _clearConfig : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: theme.colorScheme.error,
                    ),
                    child: Text(l10n.clearConfigButton),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
