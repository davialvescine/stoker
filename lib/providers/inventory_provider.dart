// lib/providers/inventory_provider.dart

import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/item.dart';
import 'base_provider.dart';
import '../core/services/supabase_service.dart';

class InventoryProvider extends BaseProvider<Item> {
  @override
  String get tableName => 'items';

  @override
  Item fromJson(Map<String, dynamic> json) => Item.fromJson(json);

  String _searchTerm = '';

  // CORREÇÃO: Use 'internalItems' em vez de '_items'
  List<Item> get filteredItems => internalItems
      .where(
        (item) => item.name.toLowerCase().contains(_searchTerm.toLowerCase()),
      )
      .toList();

  void search(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  UnmodifiableListView<MapEntry<String, List<Item>>> get groupedItems {
    final Map<String, List<Item>> temp = {};
    for (final item in filteredItems) {
      final cat = item.category.isEmpty ? 'Sem Categoria' : item.category;
      temp.putIfAbsent(cat, () => []).add(item);
    }
    final sortedMap = SplayTreeMap<String, List<Item>>.from(
      temp,
      (k1, k2) => k1.compareTo(k2),
    );
    return UnmodifiableListView(sortedMap.entries.toList());
  }

  // CORREÇÃO: Use 'internalItems' em vez de '_items'
  List<Item> get availableItems =>
      internalItems.where((item) => item.status == "Disponível").toList();

  // CORREÇÃO: Use 'internalItems' em vez de '_items'
  List<Item> get borrowedItems =>
      internalItems.where((item) => item.status == "Emprestado").toList();

  Item? getItemById(String id) {
    try {
      // CORREÇÃO: Use 'internalItems' em vez de '_items'
      return internalItems.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<String> _uploadImage(XFile imageFile) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      await supabase.storage.from('itemimages').uploadBinary(filePath, bytes);

      return supabase.storage.from('itemimages').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Erro no upload da imagem: $e');
      throw Exception('Falha ao fazer upload da imagem.');
    }
  }

  Future<bool> addItem(Item item, {XFile? imageFile}) async {
    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile);
      }
      // Criando um novo item para garantir que o ID esteja vazio e a imagem URL correta.
      final itemToInsert = Item(
        id: '', // Supabase gera o ID
        name: item.name,
        type: item.type,
        category: item.category,
        status: item.status,
        location: item.location,
        notes: item.notes,
        imageUrl: imageUrl,
        serialNumber: item.serialNumber,
        isInsured: item.isInsured,
        mainItemId: item.mainItemId,
      );
      final newItemData = await supabase
          .from(tableName)
          .insert(itemToInsert.toInsertJson())
          .select()
          .single();

      // CORREÇÃO: Modifique a lista interna e notifique
      internalItems.insert(0, fromJson(newItemData));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Erro ao adicionar item: $e");
      return false;
    }
  }

  Future<bool> updateItem(Item item, {XFile? imageFile}) async {
    try {
      String? imageUrl = item.imageUrl;
      if (imageFile != null) {
        if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
          try {
            final uri = Uri.parse(item.imageUrl!);
            final segments = uri.pathSegments;
            if (segments.length > segments.indexOf('itemimages') + 1) {
              final filePath = segments
                  .sublist(segments.indexOf('itemimages') + 1)
                  .join('/');
              await supabase.storage.from('itemimages').remove([filePath]);
            }
          } catch (e) {
            debugPrint("Aviso: Falha ao deletar a imagem antiga: $e");
          }
        }
        imageUrl = await _uploadImage(imageFile);
      }

      // Cria um mapa para atualização, passando o novo URL da imagem
      final updateData = item.copyWith(imageUrl: imageUrl).toInsertJson();
      await supabase.from(tableName).update(updateData).eq('id', item.id);

      await fetch(); // Rebuscar dados para garantir consistência
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar item: $e");
      return false;
    }
  }

  Future<bool> deleteItemImage(String itemId, String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return true;
    try {
      await supabase
          .from(tableName)
          .update({'image_url': null})
          .eq('id', itemId);

      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      if (segments.length > segments.indexOf('itemimages') + 1) {
        final filePath = segments
            .sublist(segments.indexOf('itemimages') + 1)
            .join('/');
        await supabase.storage.from('itemimages').remove([filePath]);
      }

      await fetch();
      return true;
    } catch (e) {
      debugPrint('Erro ao deletar imagem: $e');
      return false;
    }
  }

  Future<void> updateItemStatus(String itemId, String newStatus) async {
    try {
      await supabase
          .from(tableName)
          .update({'status': newStatus})
          .eq('id', itemId);
      // CORREÇÃO: Use 'internalItems'
      final index = internalItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        internalItems[index] = internalItems[index].copyWith(status: newStatus);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erro ao atualizar status do item: $e");
    }
  }

  Future<void> updateMultipleItemStatuses(
    List<String> itemIds,
    String newStatus,
  ) async {
    try {
      if (itemIds.isEmpty) return;
      await supabase
          .from(tableName)
          .update({'status': newStatus})
          .inFilter('id', itemIds);
      for (var itemId in itemIds) {
        // CORREÇÃO: Use 'internalItems'
        final index = internalItems.indexWhere((item) => item.id == itemId);
        if (index != -1) {
          internalItems[index] = internalItems[index].copyWith(
            status: newStatus,
          );
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao atualizar status de múltiplos itens: $e");
    }
  }

  List<Item> getAccessories(String mainItemId) {
    return internalItems.where((item) => item.mainItemId == mainItemId).toList();
  }

  List<Item> getAvailableAccessories(String mainItemId) {
    return internalItems
        .where((item) =>
          item.mainItemId == mainItemId &&
          item.status == 'Disponível'
        )
        .toList();
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      final item = getItemById(itemId);
      if (item?.status == "Emprestado") return false;

      if (item?.imageUrl != null && item!.imageUrl!.isNotEmpty) {
        // Chamada já faz o fetch, não precisa de outro.
        await deleteItemImage(itemId, item.imageUrl);
      }

      await supabase.from(tableName).delete().eq('id', itemId);
      // CORREÇÃO: Use 'internalItems'
      internalItems.removeWhere((item) => item.id == itemId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Erro ao deletar item: $e");
      return false;
    }
  }
}
