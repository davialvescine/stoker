import '../core/services/supabase_service.dart';

class Item {
  final String id;
  final String name;
  final String type;
  final String category;
  final String status;
  final String? location;
  final String? notes;
  final String? imageUrl;
  final String? serialNumber;
  final bool isInsured;
  final String? mainItemId;

  const Item({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.status,
    this.location,
    this.notes,
    this.imageUrl,
    this.serialNumber,
    this.isInsured = false,
    this.mainItemId,
  });

  Item copyWith({
    String? status,
    String? imageUrl,
    String? name,
    String? type,
    String? category,
    String? location,
    String? notes,
    String? serialNumber,
    bool? isInsured,
    String? mainItemId,
  }) {
    return Item(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      status: status ?? this.status,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      serialNumber: serialNumber ?? this.serialNumber,
      isInsured: isInsured ?? this.isInsured,
      mainItemId: mainItemId ?? this.mainItemId,
    );
  }

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Sem Nome',
        type: json['type'] as String? ?? '',
        category: json['category'] as String? ?? '',
        status: json['status'] as String? ?? 'Disponível',
        location: json['location'] as String?,
        notes: json['notes'] as String?,
        imageUrl: json['image_url'] as String?,
        serialNumber: json['serial_number'] as String?,
        
        mainItemId: json['main_item_id'] as String?,
      );

  Map<String, dynamic> toInsertJson() => {
        'name': name,
        'type': type,
        'category': category,
        'status': status,
        'user_id': supabase.auth.currentUser?.id,
        'image_url': imageUrl,
        'location': location,
        'notes': notes,
        'serial_number': serialNumber,
        
        'main_item_id': mainItemId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          category == other.category &&
          status == other.status &&
          location == other.location &&
          notes == other.notes &&
          imageUrl == other.imageUrl &&
          serialNumber == other.serialNumber &&
          isInsured == other.isInsured &&
          mainItemId == other.mainItemId;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      type.hashCode ^
      category.hashCode ^
      status.hashCode ^
      location.hashCode ^
      notes.hashCode ^
      imageUrl.hashCode ^
      serialNumber.hashCode ^
      isInsured.hashCode ^
      mainItemId.hashCode;
}
