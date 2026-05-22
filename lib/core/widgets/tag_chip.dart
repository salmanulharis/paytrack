import 'package:flutter/material.dart';

import '../../domain/entities/expense_tag.dart';

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final ExpenseTag tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(tag.colorValue);
    return FilterChip(
      selected: selected,
      label: Text(tag.name),
      avatar: Icon(Icons.circle, size: 12, color: color),
      onSelected: (_) => onTap(),
      selectedColor: color.withValues(alpha: 0.25),
      checkmarkColor: color,
    );
  }
}
