import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/expense_list_tile.dart';
import '../../../domain/entities/expense_status.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryController = TextEditingController();
  String? _selectedTagId;
  ExpenseStatus? _selectedStatus;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Search expenses')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: 'Search merchant, notes, amount...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _queryController.clear();
                    setState(() {});
                  },
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('All status'),
                  selected: _selectedStatus == null,
                  onSelected: (_) => setState(() => _selectedStatus = null),
                ),
                ...ExpenseStatus.values.map((s) => FilterChip(
                      label: Text(s.label),
                      selected: _selectedStatus == s,
                      onSelected: (_) => setState(() => _selectedStatus = s),
                    )),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('All categories'),
                  selected: _selectedTagId == null,
                  onSelected: (_) => setState(() => _selectedTagId = null),
                ),
                ...tags.map((t) => FilterChip(
                      label: Text(t.name),
                      selected: _selectedTagId == t.id,
                      onSelected: (_) => setState(() => _selectedTagId = t.id),
                    )),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: ref.read(expenseRepositoryProvider).search(
                    query: _queryController.text.isEmpty ? null : _queryController.text,
                    tagIds: _selectedTagId != null ? [_selectedTagId!] : null,
                    status: _selectedStatus,
                  ),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final results = snap.data!;
                if (results.isEmpty) {
                  return const Center(child: Text('No expenses found'));
                }
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, i) => ExpenseListTile(
                    expense: results[i],
                    tags: tags,
                    index: i,
                    onTap: () => context.push('/expense/${results[i].id}'),
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
