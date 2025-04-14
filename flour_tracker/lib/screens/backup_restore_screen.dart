import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flour_tracker/services/database_service.dart';
import 'package:flour_tracker/services/backup_service.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late final BackupService _backupService;
  List<String> _backupFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _backupService = BackupService(_databaseService);
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final backups = await _backupService.getAvailableBackups();
      setState(() {
        _backupFiles = backups;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading backups: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final backupPath = await _backupService.exportData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup created successfully at: $backupPath'),
          ),
        );
      }

      await _loadBackups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating backup: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreBackup(String backupPath) async {
    final bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Restore Backup'),
                content: const Text(
                  'Are you sure you want to restore this backup? All current data will be replaced with the backup data. This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Restore',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm) {
      try {
        setState(() {
          _isLoading = true;
        });

        await _backupService.importData(backupPath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup restored successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error restoring backup: $e')));
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteBackup(String backupPath) async {
    final bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete Backup'),
                content: const Text(
                  'Are you sure you want to delete this backup? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm) {
      try {
        setState(() {
          _isLoading = true;
        });

        final file = File(backupPath);
        await file.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup deleted successfully')),
          );
        }

        await _loadBackups();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting backup: $e')));
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatBackupName(String backupPath) {
    final fileName = path.basename(backupPath);
    // Extract date and time from filename (format: flour_tracker_backup_YYYYMMDD_HHMMSS.json)
    final regex = RegExp(r'flour_tracker_backup_(\d{8}_\d{6})\.json');
    final match = regex.firstMatch(fileName);

    if (match != null) {
      final dateTimeStr = match.group(1)!;
      try {
        final dateFormat = DateFormat('yyyyMMdd_HHmmss');
        final dateTime = dateFormat.parse(dateTimeStr);
        return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
      } catch (_) {
        return fileName;
      }
    }

    return fileName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: Colors.amber.shade700,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Info card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber.shade800,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Data Backup & Restore',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create backups to save your flour business data. Restore from a backup if you need to recover your data.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Create backup button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _createBackup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        minimumSize: const Size(double.infinity, 54),
                      ),
                      icon: const Icon(Icons.backup),
                      label: const Text(
                        'Create New Backup',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  // Available backups
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Available Backups',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${_backupFiles.length})',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),

                  // List of backups
                  Expanded(
                    child:
                        _backupFiles.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.backup_outlined,
                                    size: 80,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No backups found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Create a backup to protect your data',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _backupFiles.length,
                              itemBuilder: (context, index) {
                                final backupPath = _backupFiles[index];
                                final backupName = _formatBackupName(
                                  backupPath,
                                );
                                final file = File(backupPath);
                                final fileSize = (file.lengthSync() / 1024)
                                    .toStringAsFixed(2);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    title: Text(backupName),
                                    subtitle: Text('Size: $fileSize KB'),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.amber.shade100,
                                      child: Icon(
                                        Icons.description,
                                        color: Colors.amber.shade800,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.restore),
                                          color: Colors.green,
                                          onPressed:
                                              () => _restoreBackup(backupPath),
                                          tooltip: 'Restore',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed:
                                              () => _deleteBackup(backupPath),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
