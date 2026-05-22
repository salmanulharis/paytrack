import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/floating_form_scaffold.dart';
import '../../../core/widgets/tag_chip.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/expense_status.dart';
import '../../../domain/entities/note_field_mode.dart';

class ManualExpenseScreen extends ConsumerStatefulWidget {
  const ManualExpenseScreen({super.key});

  @override
  ConsumerState<ManualExpenseScreen> createState() => _ManualExpenseScreenState();
}

class _ManualExpenseScreenState extends ConsumerState<ManualExpenseScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _merchantController = TextEditingController();
  final Set<String> _selectedTags = {};
  DateTime _date = DateTime.now();
  String? _receiptPath;
  String _paymentMethod = 'Cash';

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _receiptPath = image.path);
  }

  Future<void> _save() async {
    final userPrefs = ref.read(userPreferencesProvider);
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one category')),
      );
      return;
    }
    if (userPrefs.noteFieldMode == NoteFieldMode.mandatory &&
        _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason or note')),
      );
      return;
    }

    final expense = Expense(
      id: const Uuid().v4(),
      amount: amount,
      tagIds: _selectedTags.toList(),
      createdAt: _date,
      notes: userPrefs.noteFieldMode == NoteFieldMode.disabled ||
              _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      merchantName:
          _merchantController.text.isEmpty ? null : _merchantController.text,
      status: ExpenseStatus.success,
      receiptPath: _receiptPath,
      paymentSource: _paymentMethod,
      isManual: true,
    );

    await ref.read(expensesProvider.notifier).add(expense);

    final limitService = ref.read(spendingLimitServiceProvider);
    await limitService.recordDailyExcessIfNeeded(
      prefs: userPrefs,
      expenses: ref.read(expensesProvider),
      date: _date,
    );

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagsProvider);
    final userPrefs = ref.watch(userPreferencesProvider);

    return FloatingFormScaffold(
      title: 'Add expense',
      actionLabel: 'Save expense',
      actionIcon: Icons.check_rounded,
      onAction: _save,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount *',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _merchantController,
            decoration: const InputDecoration(labelText: 'Merchant / Description'),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(
              '${_date.day}/${_date.month}/${_date.year} ${_date.hour}:${_date.minute.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.calendar_today_rounded),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) {
                setState(() => _date = DateTime(
                      d.year,
                      d.month,
                      d.day,
                      _date.hour,
                      _date.minute,
                    ));
              }
            },
          ),
          const SizedBox(height: 8),
          DropdownMenu<String>(
            initialSelection: _paymentMethod,
            label: const Text('Payment method'),
            dropdownMenuEntries: ['Cash', 'Card', 'UPI', 'Bank Transfer', 'Other']
                .map((m) => DropdownMenuEntry(value: m, label: m))
                .toList(),
            onSelected: (v) => setState(() => _paymentMethod = v ?? 'Cash'),
          ),
          const SizedBox(height: 16),
          Text('Categories *', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (tag) => TagChip(
                    tag: tag,
                    selected: _selectedTags.contains(tag.id),
                    onTap: () {
                      setState(() {
                        if (_selectedTags.contains(tag.id)) {
                          _selectedTags.remove(tag.id);
                        } else {
                          _selectedTags.add(tag.id);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          if (userPrefs.noteFieldMode != NoteFieldMode.disabled) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: userPrefs.noteFieldMode == NoteFieldMode.mandatory
                    ? 'Reason / note *'
                    : 'Notes (optional)',
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickReceipt,
            icon: const Icon(Icons.receipt_long_rounded),
            label: Text(
              _receiptPath != null ? 'Receipt attached' : 'Attach receipt',
            ),
          ),
        ],
      ),
    );
  }
}
