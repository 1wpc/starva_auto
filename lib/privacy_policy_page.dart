import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'privacy_policy_content.dart';
import 'l10n/generated/app_localizations.dart';

class PrivacyPolicyPage extends StatelessWidget {
  final bool isDialog;

  const PrivacyPolicyPage({super.key, this.isDialog = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Using the provided Chinese content
    final content = PrivacyPolicyContent.zh;

    Widget body = Column(
      children: [
        if (isDialog) ...[
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.privacyPolicyTitle,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (isDialog)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      if (Platform.isAndroid) {
                        SystemNavigator.pop();
                      } else {
                        exit(0);
                      }
                    },
                    child: Text(
                      AppLocalizations.of(context)!.disagreeButton,
                      style: TextStyle(color: theme.disabledColor),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('privacy_agreed', true);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC4C02),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(AppLocalizations.of(context)!.agreeButton),
                  ),
                ),
              ],
            ),
          ),
        if (!isDialog)
          const SizedBox(height: 20),
      ],
    );

    if (isDialog) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(child: body),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.privacyPolicyTitle),
        ),
        body: SafeArea(child: body),
      );
    }
  }
}
