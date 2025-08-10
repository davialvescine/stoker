import 'package:flutter/material.dart';
import '../core/services/supabase_service.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  @protected // Adicione esta anotação
  List<T> internalItems = []; // Renomeie de _items para internalItems e remova o '_'

  bool _isLoading = true;
  bool _isDisposed = false;

  // Modifique o getter público para usar a nova lista protegida
  List<T> get items => List.unmodifiable(internalItems);
  bool get isLoading => _isLoading;

  String get tableName;
  T fromJson(Map<String, dynamic> json);

  Future<void> fetch() async {
    if (_isDisposed) return;
    _isLoading = true;
    notifyListeners();
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');
      final data = await supabase
          .from(tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      if (!_isDisposed) {
        // Atualize para usar a nova lista
        internalItems = data.map((json) => fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Erro ao buscar dados de $tableName: $e');
      if (!_isDisposed) internalItems = [];
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
