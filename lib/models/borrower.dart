import '../core/services/supabase_service.dart';

class Borrower {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? company;

  Borrower({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.company,
  });

  factory Borrower.fromJson(Map<String, dynamic> json) => Borrower(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Sem Nome',
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    company: json['company'] as String?,
  );

  Map<String, dynamic> toInsertJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'company': company,
    'user_id': supabase.auth.currentUser?.id,
  };
}
