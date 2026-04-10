import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'l10n/generated/app_localizations.dart';

class UpdateManager {
  static const String _repoUrl = 'https://api.github.com/repos/1wpc/starva_auto/releases/latest';
  static const String _bundleId = 'ltd.mijiu.upstra';
  static const String _itunesUrl = 'https://itunes.apple.com/lookup?bundleId=$_bundleId';

  static Future<void> checkUpdate(BuildContext context, {bool showNoUpdateMsg = true}) async {
    if (showNoUpdateMsg) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.checkingUpdate),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    try {
      if (Platform.isIOS) {
        await _checkIosUpdate(context, showNoUpdateMsg);
      } else {
        await _checkAndroidUpdate(context, showNoUpdateMsg);
      }
    } catch (e) {
      if (showNoUpdateMsg && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.updateError)),
        );
      }
    }
  }

  static Future<void> _checkAndroidUpdate(BuildContext context, bool showNoUpdateMsg) async {
    final response = await http.get(Uri.parse(_repoUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (!data.containsKey('tag_name')) {
        throw Exception('Invalid response: no tag_name');
      }
      
      final latestVersionTag = data['tag_name'] as String;
      final releaseNotes = data['body'] as String?;
      final downloadUrl = data['html_url'] as String;

      final latestVersion = latestVersionTag.startsWith('v') 
          ? latestVersionTag.substring(1) 
          : latestVersionTag;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isNewerVersion(currentVersion, latestVersion)) {
        if (context.mounted) {
          _showUpdateDialog(context, latestVersion, releaseNotes, downloadUrl);
        }
      } else if (showNoUpdateMsg) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.updateUpToDate)),
          );
        }
      }
    } else if (showNoUpdateMsg) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.updateError)),
        );
      }
    }
  }

  static Future<void> _checkIosUpdate(BuildContext context, bool showNoUpdateMsg) async {
    final response = await http.get(Uri.parse(_itunesUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['resultCount'] > 0) {
        final result = data['results'][0];
        final latestVersion = result['version'] as String;
        final releaseNotes = result['releaseNotes'] as String?;
        final downloadUrl = result['trackViewUrl'] as String;

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isNewerVersion(currentVersion, latestVersion)) {
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, releaseNotes, downloadUrl);
          }
        } else if (showNoUpdateMsg) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.updateUpToDate)),
            );
          }
        }
      } else if (showNoUpdateMsg) {
        // Not found on App Store (might not be published yet)
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.updateUpToDate)),
          );
        }
      }
    } else if (showNoUpdateMsg) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.updateError)),
        );
      }
    }
  }

  static bool _isNewerVersion(String current, String latest) {
    List<int> currentParts = current.split('.').map((s) => int.tryParse(s.split('+').first) ?? 0).toList();
    List<int> latestParts = latest.split('.').map((s) => int.tryParse(s.split('+').first) ?? 0).toList();

    for (int i = 0; i < latestParts.length; i++) {
      int c = i < currentParts.length ? currentParts[i] : 0;
      int l = latestParts[i];
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context, String version, String? releaseNotes, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.updateAvailable(version)),
        content: SingleChildScrollView(
          child: Text(releaseNotes ?? ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.updateLater),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri.parse(url);
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not launch $url')),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.updateDownload),
          ),
        ],
      ),
    );
  }
}