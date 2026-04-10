// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Starva Auto';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get generalSection => 'GENERAL';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeSystem => 'System Default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get selectThemeTitle => 'Select Theme';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'System Default';

  @override
  String get languageEn => 'English';

  @override
  String get languageZh => 'Chinese';

  @override
  String get selectLanguageTitle => 'Select Language';

  @override
  String get logoutConfirmationTitle => 'Disconnect?';

  @override
  String get logoutConfirmationMessage =>
      'Are you sure you want to disconnect from Strava?';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get agreeButton => 'Agree';

  @override
  String get disagreeButton => 'Disagree';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get experimentalSection => 'Experimental Features';

  @override
  String get oneLapSyncTitle => 'OneLap Auto Sync';

  @override
  String get oneLapSyncSubtitle => 'Sync OneLap activities to Strava';

  @override
  String get backgroundSyncTip =>
      'Note: Background sync depends on system scheduling.\n• First Connect: Sync starts from your next new activity.\n• iOS: Force quitting stops sync; reopen to reactivate.\n• Android: Enable \'Auto-start\' and disable \'Battery Optimization\'.';

  @override
  String get oneLapLoginTitle => 'Connect OneLap';

  @override
  String get oneLapLoginDescription =>
      'Connect your OneLap account to automatically sync activities to Strava.';

  @override
  String get accountLabel => 'Account / Phone';

  @override
  String get passwordLabel => 'Password';

  @override
  String get connectSyncButton => 'Connect & Sync';

  @override
  String get reconnectButton => 'Reconnect';

  @override
  String get disconnectAccountButton => 'Disconnect Account';

  @override
  String get loginSuccess => 'Connected to OneLap successfully!';

  @override
  String get loginFailed => 'Login failed. Please check your credentials.';

  @override
  String get diagnosticsSection => 'DIAGNOSTICS';

  @override
  String get activityLogsTitle => 'Activity Logs';

  @override
  String get activityLogsSubtitle => 'View application events and errors';

  @override
  String get aboutSection => 'ABOUT';

  @override
  String get versionTitle => 'Version';

  @override
  String get openSourceTitle => 'Open Source';

  @override
  String get stravaConfigTitle => 'Strava API Config';

  @override
  String get stravaConfigSubtitle => 'Custom Client ID and Secret';

  @override
  String get stravaConfigPageTitle => 'Custom Strava Config';

  @override
  String get stravaConfigDescription =>
      'The official API limits have been lifted to support up to 999 connected users. You do not need to fill this out unless strictly necessary.\nIf you still want to use your own Strava Client ID and Client Secret, configure them here. Reconnection is required after saving.';

  @override
  String get stravaClientIdLabel => 'Client ID';

  @override
  String get stravaClientSecretLabel => 'Client Secret';

  @override
  String get saveButton => 'Save Config';

  @override
  String get clearConfigButton => 'Clear Custom Config';

  @override
  String get configSavedMessage => 'Config saved, please reconnect to Strava';

  @override
  String get configClearedMessage =>
      'Custom config cleared, please reconnect to Strava';

  @override
  String get clearLogsTooltip => 'Clear Logs';

  @override
  String get noLogsAvailable => 'No logs available';

  @override
  String get checkUpdateTitle => 'Check for Updates';

  @override
  String get checkingUpdate => 'Checking for updates...';

  @override
  String updateAvailable(String version) {
    return 'New version available: $version';
  }

  @override
  String get updateUpToDate => 'You are on the latest version';

  @override
  String get updateDownload => 'Download';

  @override
  String get updateLater => 'Later';

  @override
  String get updateError => 'Failed to check for updates';

  @override
  String get finalizingConnection => 'Finalizing connection...';

  @override
  String get connectedSuccess => 'Connected to Strava successfully!';

  @override
  String get authFailed => 'Authorization failed. Check logs.';

  @override
  String connectionError(String error) {
    return 'Connection Error: $error';
  }

  @override
  String cannotAccessFile(String path) {
    return 'Cannot access file: $path';
  }

  @override
  String get uploadSuccess => 'Upload successful!';

  @override
  String get uploadFailed => 'Upload failed. Check logs.';

  @override
  String uploadFileSuccess(String fileName) {
    return 'Uploaded $fileName successfully!';
  }

  @override
  String uploadFileFailed(String fileName) {
    return 'Failed to upload $fileName';
  }

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get disconnectTooltip => 'Disconnect';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusNotConnected => 'Not Connected';

  @override
  String get statusReady => 'Ready to upload activities';

  @override
  String get statusPleaseConnect => 'Please connect to Strava to start';

  @override
  String get connectButton => 'Connect to Strava';

  @override
  String get uploadFileButton => 'Upload File';

  @override
  String get uploadFileHint => 'Select a FIT file to upload';

  @override
  String get uploadActivityTitle => 'Upload Activity?';

  @override
  String get uploadNowButton => 'Upload Now';

  @override
  String get pleaseConnectFirst => 'Please connect to Strava first.';

  @override
  String get readyToSync => 'Ready to sync activities';

  @override
  String get connectToStart => 'Connect to Strava to start';

  @override
  String get connectShort => 'Connect';

  @override
  String get unlockUpload => 'Please connect to unlock upload';

  @override
  String get uploading => 'Uploading...';

  @override
  String get tapToSelect => 'Tap to Select .FIT File';

  @override
  String get orShare => 'or share from other apps';

  @override
  String get syncNowButton => 'Sync Now';

  @override
  String get syncingMessage => 'Syncing...';

  @override
  String syncSuccessMessage(int count) {
    return 'Sync completed! $count activities synced.';
  }

  @override
  String get syncFailedMessage => 'Sync failed. Check logs.';
}
