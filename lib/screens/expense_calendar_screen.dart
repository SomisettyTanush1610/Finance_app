import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../providers/expense_goal_provider.dart';

class ExpenseCalendarScreen extends ConsumerWidget {
  const ExpenseCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);
    final goal = ref.watch(expenseGoalProvider);

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(
        now.year, now.month);

    return Scaffold(
      appBar: AppBar(title: const Text("Expense Calendar")),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: daysInMonth,
        itemBuilder: (context, index) {
          int day = index + 1;

          double dailyExpense = 0;

          for (var tx in transactions) {
            if (tx.type == "expense" &&
                tx.date.year == now.year &&
                tx.date.month == now.month &&
                tx.date.day == day) {
              dailyExpense += tx.amount;
            }
          }

          bool withinGoal = dailyExpense <= goal;

          return Container(
            decoration: BoxDecoration(
              color: withinGoal
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                "$day",
                style: const TextStyle(
                    fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}