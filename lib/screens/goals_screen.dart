import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/goal_provider.dart';
import '../providers/expense_goal_provider.dart';
import '../providers/savings_provider.dart';
import '../providers/transaction_provider.dart';
import '../core/page_route.dart';
import 'expense_calendar_screen.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> fade;
  late Animation<Offset> slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(_controller);

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final goal = ref.watch(goalProvider);
    final expenseGoal = ref.watch(expenseGoalProvider);
    final savingsList = ref.watch(savingsProvider);
    final transactions = ref.watch(transactionProvider);

    final now = DateTime.now();

    double monthlySavings = 0;
    for (var s in savingsList) {
      if (s.date.month == now.month && s.date.year == now.year) {
        monthlySavings += s.type == "deposit" ? s.amount : -s.amount;
      }
    }

    double savingsProgress =
        goal == 0 ? 0 : (monthlySavings / goal).clamp(0, 1);

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

    // 🔥 STREAK
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
      body: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your Goals",
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                // 🎯 SAVINGS GOAL
                _animatedCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor:
                          Colors.blue.withOpacity(0.1),
                      child:
                          const Icon(Icons.flag, color: Colors.blue),
                    ),
                    title: const Text("Monthly Savings Goal"),
                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text("₹$monthlySavings / ₹$goal"),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: savingsProgress,
                          minHeight: 8,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                      _showGoalDialog(context, ref, goal);
                    },
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Daily Discipline",
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                // 🔥 EXPENSE GOAL
                _animatedCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            value: expenseProgress,
                            strokeWidth: 6,
                            backgroundColor:
                                Colors.grey[200],
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
                    onTap: () {
                      _showExpenseGoalDialog(
                          context, ref, expenseGoal);
                    },
                    onLongPress: () {
                      Navigator.push(
                        context,
                        FadeRoute(
                          page: const ExpenseCalendarScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // 🔥 STREAK CARD
                _animatedCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor:
                          Colors.orange.withOpacity(0.1),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                      ),
                    ),
                    title: const Text("Spending Discipline"),
                    subtitle: Text("$streak day streak"),
                    trailing: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        if (streak >= 7)
                          const Icon(Icons.emoji_events,
                              color: Colors.amber),
                        Text(
                          streak >= 5
                              ? "🔥 On Fire"
                              : streak >= 3
                                  ? "💪 Great"
                                  : "",
                          style:
                              const TextStyle(fontSize: 10),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _animatedCard({required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: child,
      ),
    );
  }

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