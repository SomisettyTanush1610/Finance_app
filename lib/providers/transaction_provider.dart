import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService();
});

class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  final TransactionService service;

  TransactionNotifier(this.service) : super([]) {
    loadTransactions();
  }

  // 🔄 LOAD FROM DB
  Future<void> loadTransactions() async {
    final data = await service.getTransactions();
    state = data;
  }

  // ➕ ADD
  Future<void> addTransaction(TransactionModel tx) async {
    await service.insertTransaction(tx);
    await loadTransactions();
  }

  // ❌ DELETE
  Future<void> deleteTransaction(String id) async {
    await service.deleteTransaction(id);
    await loadTransactions();
  }

  // ✏️ UPDATE
  Future<void> updateTransaction(TransactionModel updatedTx) async {
    await service.updateTransaction(updatedTx);
    await loadTransactions();
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<TransactionModel>>(
  (ref) {
    final service = ref.read(transactionServiceProvider);
    return TransactionNotifier(service);
  },
);