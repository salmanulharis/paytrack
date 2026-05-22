import 'package:uuid/uuid.dart';

import '../../domain/entities/expense_tag.dart';
import '../datasources/local/hive_storage.dart';

class TagRepository {
  TagRepository(this._storage);

  final HiveStorage _storage;
  final _uuid = const Uuid();

  Future<List<ExpenseTag>> getAll() => _storage.getAllTags();

  Future<ExpenseTag?> getById(String id) async {
    final tags = await _storage.getAllTags();
    try {
      return tags.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<ExpenseTag> create({
    required String name,
    required String iconName,
    required int colorValue,
  }) async {
    final tag = ExpenseTag(
      id: _uuid.v4(),
      name: name,
      iconName: iconName,
      colorValue: colorValue,
    );
    await _storage.saveTag(tag);
    return tag;
  }

  Future<void> update(ExpenseTag tag) => _storage.saveTag(tag);

  Future<void> delete(String id) => _storage.deleteTag(id);

  Future<List<ExpenseTag>> getRecent({int limit = 8}) async {
    final tags = await _storage.getAllTags();
    return tags.take(limit).toList();
  }

  Future<List<ExpenseTag>> search(String query) async {
    final q = query.toLowerCase();
    final tags = await _storage.getAllTags();
    return tags.where((t) => t.name.toLowerCase().contains(q)).toList();
  }
}
