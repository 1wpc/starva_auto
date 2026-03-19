import 'package:workmanager/workmanager.dart';
import 'onelap_manager.dart';
import 'log_manager.dart';

const String oneLapSyncTask = "oneLapSyncTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == oneLapSyncTask) {
        // Initialize logging for background (optional, might need file logging)
        LogManager().addLog("Background Sync Started: $task");
        
        final manager = OneLapManager();
        await manager.init(); // Load credentials
        await manager.syncNow();
        
        LogManager().addLog("Background Sync Completed: $task");
      }
    } catch (e) {
      LogManager().addLog("Background Task Error: $e", isError: true);
      return Future.value(false);
    }
    return Future.value(true);
  });
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      "1",
      oneLapSyncTask,
      frequency: const Duration(hours: 1), // Minimum 15 mins on Android
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
  
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}
