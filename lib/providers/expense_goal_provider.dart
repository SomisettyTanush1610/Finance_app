import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpenseGoalNotifier extends StateNotifier<double> {
  ExpenseGoalNotifier() : super(500) {
    loadGoal();
  }

  Future<void> loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble("daily_expense_goal") ?? 500;
  }

  Future<void> setGoal(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("daily_expense_goal", value);
    state = value;
  }
}

final expenseGoalProvider =
    StateNotifierProvider<ExpenseGoalNotifier, double>(
        (ref) => ExpenseGoalNotifier());