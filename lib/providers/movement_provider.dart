import 'package:flutter/material.dart';
import 'package:stoker/providers/inventory_provider.dart';
import '../models/movement.dart';


import 'package:supabase_flutter/supabase_flutter.dart';

import 'base_provider.dart';

class MovementProvider extends BaseProvider<Movement> {
  SupabaseClient get supabase => Supabase.instance.client;
  @override
  String get tableName => 'movements';

  @override
  Movement fromJson(Map<String, dynamic> json) => Movement.fromJson(json);

  // CORREÇÃO: Use 'internalItems'
  List<Movement> get recentMovements => internalItems.take(5).toList();

  Future<bool> addMovement(Movement movement, InventoryProvider inventoryProvider) async {
    try {
      List<String> allItemIds = [movement.itemId];
      final accessories = inventoryProvider.getAccessories(movement.itemId);
      allItemIds.addAll(accessories.map((e) => e.id));

      final movements = allItemIds
          .map((itemId) => Movement(
                id: '', // Gerado pelo Supabase
                itemId: itemId,
                borrowerId: movement.borrowerId,
                type: movement.type,
                date: movement.date,
              ))
          .toList();

      final movementsToInsert =
          movements.map((m) => m.toInsertJson()).toList();

      await supabase.from(tableName).insert(movementsToInsert);

      await inventoryProvider.updateMultipleItemStatuses(
          allItemIds, movement.type == 'Empréstimo' ? 'Emprestado' : 'Disponível');

      await fetch();
      return true;
    } catch (e) {
      debugPrint("Erro ao adicionar movimentação: $e");
      return false;
    }
  }

  Future<bool> addMovementsForItems({
    required List<String> itemIds,
    required String borrowerId,
    required String movementType,
    required String newStatus,
    required InventoryProvider inventoryProvider,
  }) async {
    if (itemIds.isEmpty) return true;

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      debugPrint("Erro: Usuário não autenticado.");
      return false;
    }

    try {
      List<String> allItemIds = [];
      for (var itemId in itemIds) {
        allItemIds.add(itemId);
        final accessories = inventoryProvider.getAccessories(itemId);
        allItemIds.addAll(accessories.map((e) => e.id));
      }

      final movements = allItemIds
          .map((itemId) => Movement(
                id: '', // Gerado pelo Supabase
                itemId: itemId,
                borrowerId: borrowerId,
                type: movementType,
                date: DateTime.now(),
                userId: currentUser.id,
              ))
          .toList();

      final movementsToInsert =
          movements.map((m) => m.toInsertJson()).toList();

      await supabase.from(tableName).insert(movementsToInsert);

      await inventoryProvider.updateMultipleItemStatuses(allItemIds, newStatus);

      await fetch();
      return true;
    } catch (e) {
      debugPrint("Erro ao adicionar movimentações em lote: $e");
      return false;
    }
  }

  Future<Movement?> getLastMovement(String itemId) async {
    try {
      final response = await supabase
          .from(tableName)
          .select()
          .eq('item_id', itemId)
          .order('date', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return fromJson(response.first);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao buscar última movimentação: $e');
      return null;
    }
  }
}
