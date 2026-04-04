import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'l10n/generated/app_localizations.dart';
import 'log_manager.dart';
import 'theme_manager.dart';
import 'locale_manager.dart';
import 'privacy_policy_page.dart';
import 'strava_config_page.dart';
import 'strava_service.dart';
import 'onelap_login_page.dart';
import 'onelap_manager.dart';
import 'update_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(theme, AppLocalizations.of(context)!.generalSection),
          AnimatedBuilder(
            animation: ThemeManager(),
            builder: (context, _) {
              final themeMode = ThemeManager().themeMode;
              String themeSubtitle = AppLocalizations.of(context)!.themeSystem;
              if (themeMode == ThemeMode.light) themeSubtitle = AppLocalizations.of(context)!.themeLight;
              if (themeMode == ThemeMode.dark) themeSubtitle = AppLocalizations.of(context)!.themeDark;
              
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const Icon(Icons.palette_outlined, color: Color(0xFFFC4C02)),
                  title: Text(AppLocalizations.of(context)!.themeTitle),
                  subtitle: Text(themeSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeDialog(context),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: LocaleManager(),
            builder: (context, _) {
              final locale = LocaleManager().locale;
              String languageSubtitle = AppLocalizations.of(context)!.languageSystem;
              if (locale?.languageCode == 'en') languageSubtitle = AppLocalizations.of(context)!.languageEn;
              if (locale?.languageCode == 'zh') languageSubtitle = AppLocalizations.of(context)!.languageZh;
              
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const Icon(Icons.language, color: Color(0xFFFC4C02)),
                  title: Text(AppLocalizations.of(context)!.languageTitle),
                  subtitle: Text(languageSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLanguageDialog(context),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.api_rounded, color: Color(0xFFFC4C02)),
              title: Text(AppLocalizations.of(context)!.stravaConfigTitle),
              subtitle: Text(AppLocalizations.of(context)!.stravaConfigSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StravaConfigPage(stravaService: StravaService()),
                  ),
                );
                // If config changed, you might want to refresh state if needed
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(theme, AppLocalizations.of(context)!.experimentalSection),
          AnimatedBuilder(
            animation: Listenable.merge([OneLapManager(), LocaleManager()]),
            builder: (context, _) {
              final isConnected = OneLapManager().username != null;
              final subtitle = isConnected 
                  ? OneLapManager().username! 
                  : AppLocalizations.of(context)!.oneLapSyncSubtitle;

              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const Icon(Icons.sync_rounded, color: Color(0xFFFC4C02)),
                  title: Text(AppLocalizations.of(context)!.oneLapSyncTitle),
                  subtitle: Text(subtitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isConnected) 
                         const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      if (isConnected)
                         const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OneLapLoginPage()),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(theme, AppLocalizations.of(context)!.diagnosticsSection),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.history_rounded, color: Color(0xFFFC4C02)),
              title: Text(AppLocalizations.of(context)!.activityLogsTitle),
              subtitle: Text(AppLocalizations.of(context)!.activityLogsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ActivityLogPage()),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(theme, AppLocalizations.of(context)!.aboutSection),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFFFC4C02)),
                  title: Text(AppLocalizations.of(context)!.privacyPolicyTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage(isDialog: false)),
                    );
                  },
                ),
                const Divider(height: 1),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.hasData ? snapshot.data!.version : "1.1.0";
                    return ListTile(
                      leading: const Icon(Icons.info_outline, color: Color(0xFFFC4C02)),
                      title: Text(AppLocalizations.of(context)!.versionTitle),
                      trailing: Text(version),
                      onTap: () {
                        UpdateManager.checkUpdate(context, showNoUpdateMsg: true);
                      },
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.update, color: Color(0xFFFC4C02)),
                  title: Text(AppLocalizations.of(context)!.checkUpdateTitle),
                  trailing: const Icon(Icons.chevron_right, size: 16),
                  onTap: () {
                    UpdateManager.checkUpdate(context, showNoUpdateMsg: true);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code, color: Color(0xFFFC4C02)),
                  title: Text(AppLocalizations.of(context)!.openSourceTitle),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () async {
                    final Uri url = Uri.parse('https://github.com/1wpc/starva_auto');
                    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not launch $url')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const _ThemeDialog();
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const _LanguageDialog();
      },
    );
  }
}

class _ThemeDialog extends StatelessWidget {
  const _ThemeDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.selectThemeTitle),
      content: RadioGroup<ThemeMode>(
        groupValue: ThemeManager().themeMode,
        onChanged: (value) {
          if (value != null) {
            ThemeManager().setThemeMode(value);
            Navigator.pop(context);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOption(context, AppLocalizations.of(context)!.themeSystem, ThemeMode.system),
            _buildOption(context, AppLocalizations.of(context)!.themeLight, ThemeMode.light),
            _buildOption(context, AppLocalizations.of(context)!.themeDark, ThemeMode.dark),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancelButton),
        ),
      ],
    );
  }

  Widget _buildOption(BuildContext context, String label, ThemeMode mode) {
    return RadioListTile<ThemeMode>(
      title: Text(label),
      value: mode,
      activeColor: const Color(0xFFFC4C02),
    );
  }
}

class _LanguageDialog extends StatelessWidget {
  const _LanguageDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.selectLanguageTitle),
      content: RadioGroup<String?>(
        groupValue: LocaleManager().locale?.languageCode,
        onChanged: (value) {
          LocaleManager().setLocale(value != null ? Locale(value) : null);
          Navigator.pop(context);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOption(context, AppLocalizations.of(context)!.languageSystem, null),
            _buildOption(context, AppLocalizations.of(context)!.languageEn, const Locale('en')),
            _buildOption(context, AppLocalizations.of(context)!.languageZh, const Locale('zh')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancelButton),
        ),
      ],
    );
  }

  Widget _buildOption(BuildContext context, String label, Locale? locale) {
    return RadioListTile<String?>(
      title: Text(label),
      value: locale?.languageCode,
      activeColor: const Color(0xFFFC4C02),
    );
  }
}

class ActivityLogPage extends StatelessWidget {
  const ActivityLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logManager = LogManager();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.activityLogsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: AppLocalizations.of(context)!.clearLogsTooltip,
            onPressed: () {
              logManager.clearLogs();
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: logManager,
        builder: (context, _) {
          final logs = logManager.logs;
          
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: theme.disabledColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noLogsAvailable,
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: log.isError 
                        ? theme.colorScheme.error.withValues(alpha: 0.2) 
                        : theme.dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                color: log.isError 
                    ? theme.colorScheme.errorContainer.withValues(alpha: 0.2)
                    : theme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          log.isError ? Icons.error_outline : Icons.check_circle_outline,
                          size: 20,
                          color: log.isError ? theme.colorScheme.error : Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.message,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: log.isError ? theme.colorScheme.error : theme.textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(log.timestamp),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.hintColor,
                                fontFamily: 'Monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} "
           "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
  }
}
