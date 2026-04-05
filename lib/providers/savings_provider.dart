import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/savings_model.dart';
import '../services/savings_service.dart';

final savingsServiceProvider = Provider<SavingsService>((ref) {
  return SavingsService();
});

class SavingsNotifier extends StateNotifier<List<SavingsModel>> {
  final SavingsService service;

  SavingsNotifier(this.service) : super([]) {
    loadSavings();
  }

  Future<void> loadSavings() async {
    final data = await service.getSavings();
    state = [...data];
  }

  Future<void> addSavings(SavingsModel s) async {
    await service.insertSavings(s);
    await loadSavings();
  }

  Future<void> deleteSavings(String id) async {
    await service.deleteSavings(id);
    await loadSavings();
  }
}

final savingsProvider =
    StateNotifierProvider<SavingsNotifier, List<SavingsModel>>(
  (ref) {
    final service = ref.read(savingsServiceProvider);
    return SavingsNotifier(service);
  },
);