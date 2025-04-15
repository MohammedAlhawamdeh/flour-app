import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flour_tracker/services/backup_service.dart';
import 'package:flour_tracker/services/translations_service.dart';
import 'package:intl/intl.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  bool _isLoading = false;
  bool _isRestoring = false;
  String? _errorMessage;
  List<File> _backupFiles = [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final backups = await _backupService.listBackups();
      setState(() {
        _backupFiles = backups;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final backupFile = await _backupService.createBackup();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.t(context, 'backupCreated')),
          duration: const Duration(seconds: 2),
        ),
      );
      _loadBackups();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppTranslations.t(context, 'backupFailed')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreBackup() async {
    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });

    try {
      final success = await _backupService.restoreBackup();
      if (success && mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: Text(AppTranslations.t(context, 'restoreSuccessTitle')),
                content: Text(
                  AppTranslations.t(context, 'restoreSuccessMessage'),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Restart app or navigate to home screen
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    },
                    child: Text(AppTranslations.t(context, 'ok')),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppTranslations.t(context, 'restoreFailed')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRestoring = false;
      });
    }
  }

  Future<void> _shareBackup(File backupFile) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _backupService.shareBackup(backupFile);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppTranslations.t(context, 'shareFailed')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBackup(File backupFile) async {
    final bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(AppTranslations.t(context, 'confirmDeleteBackup')),
                content: Text(
                  AppTranslations.t(context, 'deleteBackupMessage'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(AppTranslations.t(context, 'cancel')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      AppTranslations.t(context, 'delete'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final success = await _backupService.deleteBackup(backupFile);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppTranslations.t(context, 'backupDeleted')),
            ),
          );
          _loadBackups();
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppTranslations.t(context, 'deleteFailed')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatBackupDate(File file) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final lastModified = file.lastModifiedSync();
    return dateFormat.format(lastModified);
  }

  String _getBackupName(File file) {
    final path = file.path;
    return path.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.t(context, 'backupRestore')),
        backgroundColor: Colors.amber.shade700,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppTranslations.t(context, 'errorOccurred'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadBackups,
                      child: Text(AppTranslations.t(context, 'tryAgain')),
                    ),
                  ],
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _createBackup,
                                icon: const Icon(Icons.backup),
                                label: Text(
                                  AppTranslations.t(context, 'createBackup'),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isRestoring ? null : _restoreBackup,
                                icon: const Icon(Icons.restore),
                                label: Text(
                                  AppTranslations.t(context, 'restoreBackup'),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      AppTranslations.t(context, 'availableBackups'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child:
                        _backupFiles.isEmpty
                            ? Center(
                              child: Text(
                                AppTranslations.t(context, 'noBackupsFound'),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            )
                            : ListView.builder(
                              itemCount: _backupFiles.length,
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (context, index) {
                                final backupFile = _backupFiles[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(
                                      _getBackupName(backupFile),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _formatBackupDate(backupFile),
                                    ),
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.amber,
                                      child: Icon(
                                        Icons.storage,
                                        color: Colors.white,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.share),
                                          onPressed:
                                              () => _shareBackup(backupFile),
                                          tooltip: AppTranslations.t(
                                            context,
                                            'shareBackup',
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed:
                                              () => _deleteBackup(backupFile),
                                          tooltip: AppTranslations.t(
                                            context,
                                            'deleteBackup',
                                          ),
                                          color: Colors.red,
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

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Text(
                  AppTranslations.t(context, 'backupInfo'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(AppTranslations.t(context, 'backupInfoText')),
            const SizedBox(height: 8),
            Text(
              AppTranslations.t(context, 'backupShareText'),
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
