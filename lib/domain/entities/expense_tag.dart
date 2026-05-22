import 'package:equatable/equatable.dart';

class ExpenseTag extends Equatable {
  const ExpenseTag({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    this.usageCount = 0,
  });

  final String id;
  final String name;
  final String iconName;
  final int colorValue;
  final int usageCount;

  ExpenseTag copyWith({
    String? id,
    String? name,
    String? iconName,
    int? colorValue,
    int? usageCount,
  }) {
    return ExpenseTag(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconName': iconName,
        'colorValue': colorValue,
        'usageCount': usageCount,
      };

  factory ExpenseTag.fromJson(Map<String, dynamic> json) => ExpenseTag(
        id: json['id'] as String,
        name: json['name'] as String,
        iconName: json['iconName'] as String,
        colorValue: json['colorValue'] as int,
        usageCount: json['usageCount'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [id, name, iconName, colorValue, usageCount];
}
