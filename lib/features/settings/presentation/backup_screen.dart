import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/utils/app_log.dart';
import '../../../domain/entities/expense_status.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  DateTime? _exportStart;
  DateTime? _exportEnd;
  ExpenseStatus? _exportStatus;
  bool _isBusy = false;

  Future<void> _export({bool filtered = false}) async {
    setState(() => _isBusy = true);
    try {
      final prefs = ref.read(userPreferencesProvider);
      final backup = ref.read(backupServiceProvider);
      final json = await backup.exportBackup(
        filters: filtered
            ? BackupExportFilters(
                startDate: _exportStart,
                endDate: _exportEnd,
                status: _exportStatus,
              )
            : null,
        encrypt: prefs.encryptedBackup,
      );

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/paytrack_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(json);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'PayTrack Backup',
      );
    } catch (e) {
      _showError('Export failed. Please try again.');
      appLog('Backup export failed', e);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _import(ImportMode mode) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(mode == ImportMode.replace ? 'Replace all data?' : 'Merge backup?'),
        content: Text(
          mode == ImportMode.replace
              ? 'This will delete existing expenses and tags before importing.'
              : 'Existing records will be kept. Duplicate IDs will be overwritten.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      final raw = await File(result.files.single.path!).readAsString();
      final importResult = await ref.read(backupServiceProvider).importBackup(
            raw,
            mode: mode,
          );
      await ref.read(expensesProvider.notifier).load();
      await ref.read(tagsProvider.notifier).load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported ${importResult.expensesImported} expenses, '
              '${importResult.tagsImported} tags',
            ),
          ),
        );
      }
    } on BackupValidationException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Import failed. Check the file and try again.');
      appLog('Backup import failed', e);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & restore')),
      body: _isBusy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Export',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Backups use JSON format v${1} with metadata. Enable encrypted backup in Settings for AES encryption.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Export all data'),
                  leading: const Icon(Icons.cloud_upload_rounded),
                  onTap: () => _export(),
                ),
                const Divider(),
                Text('Filtered export', style: Theme.of(context).textTheme.titleMedium),
                ListTile(
                  title: Text(
                    _exportStart == null
                        ? 'Start date (optional)'
                        : 'From ${_exportStart!.day}/${_exportStart!.month}/${_exportStart!.year}',
                  ),
                  trailing: const Icon(Icons.date_range_rounded),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _exportStart = d);
                  },
                ),
                ListTile(
                  title: Text(
                    _exportEnd == null
                        ? 'End date (optional)'
                        : 'To ${_exportEnd!.day}/${_exportEnd!.month}/${_exportEnd!.year}',
                  ),
                  trailing: const Icon(Icons.date_range_rounded),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _exportEnd = d);
                  },
                ),
                DropdownMenu<ExpenseStatus?>(
                  label: const Text('Status filter'),
                  initialSelection: _exportStatus,
                  dropdownMenuEntries: [
                    const DropdownMenuEntry(value: null, label: 'All'),
                    ...ExpenseStatus.values.map(
                      (s) => DropdownMenuEntry(value: s, label: s.label),
                    ),
                  ],
                  onSelected: (v) => setState(() => _exportStatus = v),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _export(filtered: true),
                  icon: const Icon(Icons.filter_alt_rounded),
                  label: const Text('Export with filters'),
                ),
                const SizedBox(height: 32),
                Text('Import', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Pick a PayTrack JSON backup file. Data is validated before import.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () => _import(ImportMode.merge),
                  icon: const Icon(Icons.merge_rounded),
                  label: const Text('Import & merge'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _import(ImportMode.replace),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Import & replace all'),
                ),
              ],
            ),
    );
  }
}
