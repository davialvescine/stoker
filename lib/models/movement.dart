

class Movement {
  final String id;
  final String itemId;
  final String borrowerId;
  final String type;
  final DateTime date;
  final DateTime? expectedReturn;
  final String? notes;
  final String? userId; // Adicionado para rastreamento

  Movement({
    required this.id,
    required this.itemId,
    required this.borrowerId,
    required this.type,
    required this.date,
    this.expectedReturn,
    this.notes,
    this.userId,
  });

  factory Movement.fromJson(Map<String, dynamic> json) => Movement(
    id: json['id'] as String,
    itemId: json['item_id'] as String,
    borrowerId: json['borrower_id'] as String,
    type: json['type'] as String,
    date: DateTime.parse(json['date'] as String),
    expectedReturn: json['expected_return'] != null
        ? DateTime.parse(json['expected_return'] as String)
        : null,
    notes: json['notes'] as String?,
    userId: json['user_id'] as String?,
  );

  Map<String, dynamic> toInsertJson() => {
    'item_id': itemId,
    'borrower_id': borrowerId,
    'type': type,
    'date': date.toIso8601String(),
    'expected_return': expectedReturn?.toIso8601String(),
    'notes': notes,
    'user_id': userId,
  };
}
