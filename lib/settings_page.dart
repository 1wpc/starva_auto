import 'package:flutter/material.dart';
import 'log_manager.dart';
import 'theme_manager.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(theme, "GENERAL"),
          AnimatedBuilder(
            animation: ThemeManager(),
            builder: (context, _) {
              final themeMode = ThemeManager().themeMode;
              String themeSubtitle = "System Default";
              if (themeMode == ThemeMode.light) themeSubtitle = "Light";
              if (themeMode == ThemeMode.dark) themeSubtitle = "Dark";
              
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const Icon(Icons.palette_outlined, color: Color(0xFFFC4C02)),
                  title: const Text("Theme"),
                  subtitle: Text(themeSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeDialog(context),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(theme, "DIAGNOSTICS"),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.history_rounded, color: Color(0xFFFC4C02)),
              title: const Text("Activity Logs"),
              subtitle: const Text("View application events and errors"),
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
          _buildSectionHeader(theme, "ABOUT"),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Color(0xFFFC4C02)),
                  title: const Text("Version"),
                  trailing: const Text("1.0.0"),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code, color: Color(0xFFFC4C02)),
                  title: const Text("Open Source"),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () {
                    // Future: Open GitHub repo
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
}

class _ThemeDialog extends StatelessWidget {
  const _ThemeDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Theme"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(context, "System Default", ThemeMode.system),
          _buildOption(context, "Light", ThemeMode.light),
          _buildOption(context, "Dark", ThemeMode.dark),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }

  Widget _buildOption(BuildContext context, String label, ThemeMode mode) {
    final currentMode = ThemeManager().themeMode;
    final isSelected = currentMode == mode;
    
    return RadioListTile<ThemeMode>(
      title: Text(label),
      value: mode,
      groupValue: currentMode,
      activeColor: const Color(0xFFFC4C02),
      onChanged: (value) {
        if (value != null) {
          ThemeManager().setThemeMode(value);
          Navigator.pop(context);
        }
      },
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
        title: const Text("Activity Logs"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Clear Logs",
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
                  Icon(Icons.history_toggle_off, size: 64, color: theme.disabledColor.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    "No logs available",
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
                        ? theme.colorScheme.error.withOpacity(0.2) 
                        : theme.dividerColor.withOpacity(0.5),
                  ),
                ),
                color: log.isError 
                    ? theme.colorScheme.errorContainer.withOpacity(0.2)
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
