import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/tag_icon_helper.dart';

class ManageTagsScreen extends ConsumerWidget {
  const ManageTagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView.builder(
        itemCount: tags.length,
        itemBuilder: (context, i) {
          final tag = tags[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(tag.colorValue).withValues(alpha: 0.2),
              child: Icon(
                TagIconHelper.iconFor(tag.iconName),
                color: Color(tag.colorValue),
              ),
            ),
            title: Text(tag.name),
            subtitle: Text('Used ${tag.usageCount} times'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                await ref.read(tagRepositoryProvider).delete(tag.id);
                await ref.read(tagsProvider.notifier).load();
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    var selectedIcon = TagIconHelper.availableIcons.first;
    var selectedColor = TagIconHelper.tagColors.first;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: TagIconHelper.availableIcons.take(9).map<Widget>((icon) {
                    final isSelected = selectedIcon == icon;
                    return InkWell(
                      onTap: () => setState(() => selectedIcon = icon),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Icon(TagIconHelper.iconFor(icon)),
                      ),
                    );
                  }).toList(),
                ),
                Wrap(
                  spacing: 8,
                  children: TagIconHelper.tagColors.map<Widget>((color) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(color),
                        child: selectedColor == color
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await ref.read(tagsProvider.notifier).create(
                        name: nameController.text,
                        iconName: selectedIcon,
                        colorValue: selectedColor,
                      );
                  if (context.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
