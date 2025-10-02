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

      // Buscar kits e kit_items separadamente para evitar problema de relacionamento
      final kitsData = await supabase
          .from('kits')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);

      final kitItemsData = await supabase
          .from('kit_items')
          .select();

      if (!_isDisposed) {
        // Combinar dados em Dart
        _kits = kitsData.map((kitJson) {
          final kitId = kitJson['id'];
          final itemIds = kitItemsData
              .where((ki) => ki['kit_id'] == kitId)
              .map((ki) => ki['item_id'] as String)
              .toList();

          // Criar JSON com formato esperado por Kit.fromJson
          final combinedJson = {
            ...kitJson,
            'kit_items': itemIds.map((id) => {'item_id': id}).toList(),
          };

          return Kit.fromJson(combinedJson, allItems);
        }).toList();
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

  Future<bool> updateKit(String kitId, String name, List<String> itemIds) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Atualizar nome do kit
      await supabase
          .from('kits')
          .update({'name': name})
          .eq('id', kitId)
          .eq('user_id', userId);

      // Deletar relações antigas
      await supabase.from('kit_items').delete().eq('kit_id', kitId);

      // Inserir novas relações
      if (itemIds.isNotEmpty) {
        final List<Map<String, dynamic>> kitItemsRelations = itemIds
            .map((itemId) => {'kit_id': kitId, 'item_id': itemId})
            .toList();
        await supabase.from('kit_items').insert(kitItemsRelations);
      }

      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar kit: $e');
      return false;
    }
  }

  Future<bool> deleteKit(String kitId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Deletar relações primeiro (kit_items)
      await supabase.from('kit_items').delete().eq('kit_id', kitId);

      // Deletar kit
      await supabase
          .from('kits')
          .delete()
          .eq('id', kitId)
          .eq('user_id', userId);

      // Remover da lista local
      if (!_isDisposed) {
        _kits.removeWhere((kit) => kit.id == kitId);
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Erro ao deletar kit: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
