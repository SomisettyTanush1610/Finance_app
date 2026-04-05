import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalNotifier extends StateNotifier<double> {
  GoalNotifier() : super(5000) {
    loadGoal();
  }

  Future<void> loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble("monthly_goal") ?? 5000;
  }

  Future<void> setGoal(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("monthly_goal", value);
    state = value;
  }
}

final goalProvider =
    StateNotifierProvider<GoalNotifier, double>(
        (ref) => GoalNotifier());