import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart'; // Add this import for getDatabasesPath

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  // Get the path to the database file
  Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), 'flour_tracker.db');
  }

  // Create a backup file
  Future<File> createBackup() async {
    // Get database path
    final dbPath = await getDatabasePath();
    final dbFile = File(dbPath);

    // Check if database exists
    if (!await dbFile.exists()) {
      throw Exception('Database file not found');
    }

    // Create backup file name with timestamp
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupFileName = 'flour_tracker_backup_$timestamp.db';

    // Get directory for backup
    Directory? backupDir;
    if (Platform.isAndroid) {
      // On Android, use the downloads directory
      backupDir = await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      // On iOS, use the documents directory
      backupDir = await getApplicationDocumentsDirectory();
    } else {
      // On desktop, use the downloads directory
      backupDir = await getDownloadsDirectory();
    }

    if (backupDir == null) {
      throw Exception('Could not find a suitable directory for backup');
    }

    // Create backup directory if it doesn't exist
    final backupPath = join(backupDir.path, 'flour_tracker_backups');
    final backupDirObj = Directory(backupPath);
    if (!await backupDirObj.exists()) {
      await backupDirObj.create(recursive: true);
    }

    // Create the backup file path
    final backupFilePath = join(backupPath, backupFileName);

    // Copy the database file to the backup location
    final backupFile = await dbFile.copy(backupFilePath);

    return backupFile;
  }

  // Share the backup file
  Future<void> shareBackup(File backupFile) async {
    try {
      final filePath = backupFile.path;
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Flour Tracker Database Backup',
        text: 'Here is your Flour Tracker backup file. Keep it safe!',
      );
    } catch (e) {
      throw Exception('Failed to share backup: $e');
    }
  }

  // Restore from a backup file
  Future<bool> restoreBackup() async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      // Let user pick the backup file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        dialogTitle: 'Select Flour Tracker backup file',
      );

      if (result == null || result.files.isEmpty) {
        // User canceled the picker
        return false;
      }

      final pickedFile = result.files.first;

      if (Platform.isAndroid || Platform.isIOS) {
        if (pickedFile.path == null) {
          throw Exception('Could not get path from picked file');
        }

        final sourcePath = pickedFile.path!;
        final sourceFile = File(sourcePath);

        // Copy to database location
        final dbPath = await getDatabasePath();
        final dbFile = File(dbPath);

        // Make sure we close any open database connections
        // This will be handled by restarting the app after restore

        // Copy the backup file to the database location
        await sourceFile.copy(dbPath);

        return true;
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        if (pickedFile.path == null) {
          throw Exception('Could not get path from picked file');
        }

        final sourcePath = pickedFile.path!;
        final sourceFile = File(sourcePath);

        // Copy to database location
        final dbPath = await getDatabasePath();

        // Copy the backup file to the database location
        await sourceFile.copy(dbPath);

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      rethrow;
    }
  }

  // List available backups
  Future<List<File>> listBackups() async {
    try {
      Directory? backupDir;
      if (Platform.isAndroid) {
        backupDir = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        backupDir = await getApplicationDocumentsDirectory();
      } else {
        backupDir = await getDownloadsDirectory();
      }

      if (backupDir == null) {
        throw Exception('Could not find backup directory');
      }

      final backupPath = join(backupDir.path, 'flour_tracker_backups');
      final backupDirObj = Directory(backupPath);

      if (!await backupDirObj.exists()) {
        return [];
      }

      final files =
          await backupDirObj
              .list()
              .where((entity) => entity is File && entity.path.endsWith('.db'))
              .map((entity) => entity as File)
              .toList();

      // Sort by creation date (newest first)
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      return files;
    } catch (e) {
      debugPrint('Error listing backups: $e');
      return [];
    }
  }

  // Delete a backup file
  Future<bool> deleteBackup(File backupFile) async {
    try {
      if (await backupFile.exists()) {
        await backupFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting backup: $e');
      return false;
    }
  }
}
