import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/goal_provider.dart';
import '../providers/expense_goal_provider.dart';
import '../providers/savings_provider.dart';
import '../providers/transaction_provider.dart';
import 'expense_calendar_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(goalProvider);
    final expenseGoal = ref.watch(expenseGoalProvider);
    final savingsList = ref.watch(savingsProvider);
    final transactions = ref.watch(transactionProvider);

    final now = DateTime.now();

    // 🎯 Monthly Savings
    double monthlySavings = 0;
    for (var s in savingsList) {
      if (s.date.month == now.month &&
          s.date.year == now.year) {
        monthlySavings +=
            s.type == "deposit" ? s.amount : -s.amount;
      }
    }

    double savingsProgress =
        goal == 0 ? 0 : (monthlySavings / goal).clamp(0, 1);

    // 🔥 Today Expense
    double todayExpense = 0;
    for (var tx in transactions) {
      if (tx.type == "expense" &&
          tx.date.day == now.day &&
          tx.date.month == now.month &&
          tx.date.year == now.year) {
        todayExpense += tx.amount;
      }
    }

    double expenseProgress =
        (todayExpense / expenseGoal).clamp(0, 1);

    // 🔥 STREAK LOGIC
    int streak = 0;
    DateTime checkDay =
        DateTime(now.year, now.month, now.day);

    while (true) {
      double dailyExpense = 0;

      for (var tx in transactions) {
        if (tx.type == "expense" &&
            tx.date.year == checkDay.year &&
            tx.date.month == checkDay.month &&
            tx.date.day == checkDay.day) {
          dailyExpense += tx.amount;
        }
      }

      if (dailyExpense <= expenseGoal) {
        streak++;
        checkDay =
            checkDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Goals & Challenges")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🎯 SAVINGS GOAL
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading:
                    const Icon(Icons.flag, color: Colors.blue),
                title: const Text("Monthly Savings Goal"),
                subtitle: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text("₹$monthlySavings / ₹$goal"),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: savingsProgress,
                      minHeight: 6,
                    ),
                  ],
                ),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  _showGoalDialog(context, ref, goal);
                },
              ),
            ),

            const SizedBox(height: 16),

            // 🔥 EXPENSE GOAL (EDITABLE)
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: expenseProgress,
                        strokeWidth: 6,
                        color: expenseProgress > 1
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    const Icon(Icons.local_fire_department),
                  ],
                ),
                title: const Text("Daily Expense Goal"),
                subtitle:
                    Text("₹$todayExpense / ₹$expenseGoal"),
                trailing: const Icon(Icons.edit),

                // 👉 TAP = EDIT
                onTap: () {
                  _showExpenseGoalDialog(
                      context, ref, expenseGoal);
                },

                // 👉 LONG PRESS = CALENDAR
                onLongPress: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ExpenseCalendarScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 🔥 STREAK CARD
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                ),
                title: const Text("Spending Discipline"),
                subtitle: Text("$streak day streak"),

                trailing: streak >= 7
                    ? const Icon(Icons.emoji_events,
                        color: Colors.amber)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 EDIT SAVINGS GOAL
  void _showGoalDialog(
      BuildContext context, WidgetRef ref, double goal) {
    final controller =
        TextEditingController(text: goal.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Set Monthly Goal"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(labelText: "Amount"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final value =
                  double.tryParse(controller.text.trim());

              if (value == null || value <= 0) return;

              await ref
                  .read(goalProvider.notifier)
                  .setGoal(value);

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // 🔥 EDIT EXPENSE GOAL
  void _showExpenseGoalDialog(
      BuildContext context,
      WidgetRef ref,
      double currentGoal) {
    final controller =
        TextEditingController(text: currentGoal.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Set Daily Expense Goal"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(labelText: "Amount"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final value =
                  double.tryParse(controller.text.trim());

              if (value == null || value <= 0) return;

              await ref
                  .read(expenseGoalProvider.notifier)
                  .setGoal(value);

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}