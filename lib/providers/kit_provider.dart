import 'package:flutter/material.dart';
import '../models/kit.dart';
import '../models/item.dart';
import '../core/services/supabase_service.dart';

class KitProvider with ChangeNotifier {
  List<Kit> _kits = [];
  bool _isLoading = true;
  bool _isDisposed = false;

  List<Kit> get kits => List.unmodifiable(_kits);
  bool get isLoading => _isLoading;

  Future<void> fetch(List<Item> allItems) async {
    if (_isDisposed) return;
    _isLoading = true;
    notifyListeners();

    try {
      if (supabase.auth.currentUser == null) return;
      final data = await supabase
          .from('kits')
          .select('*, kit_items(item_id)')
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);

      if (!_isDisposed) {
        _kits = data.map((json) => Kit.fromJson(json, allItems)).toList();
      }
    } catch (e) {
      debugPrint('Erro ao buscar kits: $e');
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createKit(String name, List<String> itemIds) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final newKitData = await supabase
          .from('kits')
          .insert({'name': name, 'user_id': userId})
          .select()
          .single();

      final newKitId = newKitData['id'];

      final List<Map<String, dynamic>> kitItemsRelations = itemIds
          .map((itemId) => {'kit_id': newKitId, 'item_id': itemId})
          .toList();

      if (kitItemsRelations.isNotEmpty) {
        await supabase.from('kit_items').insert(kitItemsRelations);
      }

      return true;
    } catch (e) {
      debugPrint('Erro ao criar kit: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
