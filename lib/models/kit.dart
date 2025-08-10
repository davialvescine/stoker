import 'package:equatable/equatable.dart';
import 'package:stoker/models/item.dart';

class Kit extends Equatable {
  final String id;
  final String name;
  final List<Item> items;

  const Kit({
    required this.id,
    required this.name,
    required this.items,
  });

  factory Kit.fromJson(Map<String, dynamic> json, List<Item> allItems) {
    final itemIds = (json['kit_items'] as List)
        .map((e) => e['item_id'] as String)
        .toList();

    final kitItems = allItems.where((item) => itemIds.contains(item.id)).toList();

    return Kit(
      id: json['id'] as String,
      name: json['name'] as String,
      items: kitItems,
    );
  }

  @override
  List<Object?> get props => [id, name, items];
}
