import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'local_cache.dart';

class BackupResult {
  final bool success;
  final String message;
  final String? filePath;
  const BackupResult({required this.success, required this.message, this.filePath});
}

/// Handles exporting WeBAlert's local data (profile + cached weather) to a
/// backup file, and restoring it back.
///
/// Two locations are used:
///  - A public, user-visible folder ("WeBAlert" inside the device's
///    Documents/Downloads area) so the file survives an app uninstall and
///    is reachable from any file manager or a PC - this is the "outside the
///    app, accessible folder" backup the app is asked for.
///  - A fallback to the app's own external files directory
///    (Android/data/.../files/WeBAlert) when broad storage access isn't
///    granted, so backup/restore still works without extra permissions.
class BackupService {
  BackupService._internal();
  static final BackupService instance = BackupService._internal();

  static const String _folderName = 'WeBAlert';
  static const String _fileName = 'webalert_backup.json';

  /// Requests whatever storage permission is appropriate for the running
  /// Android version. Safe to call repeatedly; returns true if the app can
  /// write to the public folder, false if it must fall back to app-private
  /// external storage (backup/restore still works either way).
  Future<bool> requestStoragePermission() async {
    try {
      final manageStatus = await Permission.manageExternalStorage.status;
      if (manageStatus.isGranted) return true;

      final result = await Permission.manageExternalStorage.request();
      if (result.isGranted) return true;

      // Older Android (<=10) fallback permission.
      final legacy = await Permission.storage.request();
      return legacy.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<Directory> _publicBackupDir() async {
    // /storage/emulated/0/Documents/WeBAlert
    final dir = Directory('/storage/emulated/0/Documents/$_folderName');
    await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _privateBackupDir() async {
    final base = await getExternalStorageDirectory();
    final dir = Directory('${base!.path}/$_folderName');
    await dir.create(recursive: true);
    return dir;
  }

  Future<BackupResult> backupNow() async {
    try {
      final data = await LocalCache.instance.exportAll();
      data['_backup_created_at'] = DateTime.now().toIso8601String();
      data['_app'] = 'WeBAlert - Kerala Disaster Management';
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      final hasPublicAccess = await requestStoragePermission();
      Directory dir;
      bool usedPublicFolder;
      try {
        if (hasPublicAccess) {
          dir = await _publicBackupDir();
          usedPublicFolder = true;
        } else {
          dir = await _privateBackupDir();
          usedPublicFolder = false;
        }
      } catch (_) {
        dir = await _privateBackupDir();
        usedPublicFolder = false;
      }

      final file = File('${dir.path}/$_fileName');
      await file.writeAsString(jsonStr, flush: true);

      return BackupResult(
        success: true,
        message: usedPublicFolder
            ? 'Backup saved to Documents/$_folderName on your device storage.'
            : 'Backup saved to the app\'s external folder (grant "All files access" for a Documents/$_folderName copy).',
        filePath: file.path,
      );
    } catch (e) {
      return BackupResult(success: false, message: 'Backup failed: $e');
    }
  }

  Future<BackupResult> restoreNow() async {
    try {
      File? file;
      final hasPublicAccess = await requestStoragePermission();
      if (hasPublicAccess) {
        final publicFile = File('${(await _publicBackupDir()).path}/$_fileName');
        if (await publicFile.exists()) file = publicFile;
      }
      file ??= File('${(await _privateBackupDir()).path}/$_fileName');

      if (!await file.exists()) {
        return const BackupResult(success: false, message: 'No backup file found on this device yet.');
      }

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      await LocalCache.instance.importAll(data);

      return BackupResult(success: true, message: 'Backup restored successfully.', filePath: file.path);
    } catch (e) {
      return BackupResult(success: false, message: 'Restore failed: $e');
    }
  }
}
