import 'package:flutter/material.dart';
import '../models/borrower.dart';
import '../core/services/supabase_service.dart';
import 'base_provider.dart';

class BorrowerProvider extends BaseProvider<Borrower> {
  @override
  String get tableName => 'borrowers';

  @override
  Borrower fromJson(Map<String, dynamic> json) => Borrower.fromJson(json);

  Future<bool> addBorrower(Borrower borrower) async {
    try {
      final newBorrowerData = await supabase
          .from(tableName)
          .insert(borrower.toInsertJson())
          .select()
          .single();

      internalItems.insert(0, fromJson(newBorrowerData));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Erro ao adicionar mutuário: $e");
      return false;
    }
  }

  Future<bool> updateBorrower(Borrower borrower) async {
    try {
      await supabase
          .from(tableName)
          .update(borrower.toInsertJson())
          .eq('id', borrower.id);

      final index = internalItems.indexWhere((b) => b.id == borrower.id);
      if (index != -1) {
        internalItems[index] = borrower;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar mutuário: $e");
      return false;
    }
  }

  Future<bool> deleteBorrower(String id) async {
    try {
      await supabase.from(tableName).delete().eq('id', id);
      internalItems.removeWhere((b) => b.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Erro ao deletar mutuário: $e");
      return false;
    }
  }

  Borrower? getBorrowerById(String id) {
    try {
      return internalItems.firstWhere((borrower) => borrower.id == id);
    } catch (_) {
      return null;
    }
  }
}
