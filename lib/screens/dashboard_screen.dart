import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/savings_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/savings_model.dart';
import '../core/page_route.dart';
import 'savings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends ConsumerState<DashboardScreen> {
  bool showIncome = true;
  bool showExpense = true;
  bool showSavings = true;

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionProvider);
    final savingsList = ref.watch(savingsProvider);

    double totalSavings = 0;
    for (var s in savingsList) {
      totalSavings +=
          s.type == "deposit" ? s.amount : -s.amount;
    }

    double income = 0;
    double expense = 0;

    for (var tx in transactions) {
      if (tx.type == "income") {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    final balance = income - expense;
    final availableBalance = balance - totalSavings;

    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: 1,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _balanceCard(
                  availableBalance, balance, totalSavings),

              const SizedBox(height: 24),

              const Text("Overview",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 300),
                      child: _buildStatCard(
                          "Income", income, Colors.green),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 300),
                      child: _buildStatCard(
                          "Expense", expense, Colors.red),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text("Weekly Trends",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),

              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          _buildFilterChip("Income", showIncome,
                              Colors.green, () {
                            setState(() =>
                                showIncome = !showIncome);
                          }),
                          _buildFilterChip("Expense", showExpense,
                              Colors.red, () {
                            setState(() =>
                                showExpense = !showExpense);
                          }),
                          _buildFilterChip("Savings", showSavings,
                              Colors.orange, () {
                            setState(() =>
                                showSavings = !showSavings);
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),

                      AnimatedSwitcher(
                        duration:
                            const Duration(milliseconds: 400),
                        child: SizedBox(
                          key: ValueKey(
                              "$showIncome$showExpense$showSavings"),
                          height: 240,
                          child: _buildWeeklyChart(
                              transactions, savingsList),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 🔥 SAVINGS CARD (FIXED)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.savings,
                      color: Colors.orange),
                  title: const Text("Savings"),
                  subtitle: Text("₹$totalSavings"),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      _showSavingsDialog(
                          context, ref, balance, totalSavings);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      FadeRoute(
                          page: const SavingsScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balanceCard(
      double available, double total, double savings) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF007AFF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Available Balance",
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Text("₹$available",
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text("Total: ₹$total | Savings: ₹$savings",
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, double amount, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title),
            const SizedBox(height: 6),
            Text("₹$amount",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color:
                    selected ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget _buildWeeklyChart(transactions, savingsList) {
    final now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    List<double> incomeData = List.filled(7, 0);
    List<double> expenseData = List.filled(7, 0);
    List<double> savingsData = List.filled(7, 0);

    for (var tx in transactions) {
      final diff = today
          .difference(DateTime(tx.date.year, tx.date.month, tx.date.day))
          .inDays;

      if (diff >= 0 && diff < 7) {
        final i = 6 - diff;
        if (tx.type == "income") {
          incomeData[i] += tx.amount;
        } else {
          expenseData[i] += tx.amount;
        }
      }
    }

    for (var s in savingsList) {
      final diff = today
          .difference(DateTime(s.date.year, s.date.month, s.date.day))
          .inDays;

      if (diff >= 0 && diff < 7) {
        final i = 6 - diff;
        savingsData[i] +=
            s.type == "deposit" ? s.amount : -s.amount;
      }
    }

    double maxY = incomeData
        .followedBy(expenseData)
        .followedBy(savingsData)
        .reduce(max);
    maxY *= 1.2;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          if (showIncome)
            LineChartBarData(
              spots: List.generate(
                  7, (i) => FlSpot(i.toDouble(), incomeData[i])),
              isCurved: true,
              color: Colors.green,
            ),
          if (showExpense)
            LineChartBarData(
              spots: List.generate(
                  7, (i) => FlSpot(i.toDouble(), expenseData[i])),
              isCurved: true,
              color: Colors.red,
            ),
          if (showSavings)
            LineChartBarData(
              spots: List.generate(
                  7, (i) => FlSpot(i.toDouble(), savingsData[i])),
              isCurved: true,
              color: Colors.orange,
            ),
        ],
      ),
    );
  }

  void _showSavingsDialog(
    BuildContext context,
    WidgetRef ref,
    double balance,
    double totalSavings,
  ) {
    final controller = TextEditingController();
    String type = "deposit";

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Manage Savings"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: "Amount"),
                ),
                DropdownButtonFormField(
                  value: type,
                  items: const [
                    DropdownMenuItem(
                        value: "deposit", child: Text("Deposit")),
                    DropdownMenuItem(
                        value: "withdraw", child: Text("Withdraw")),
                  ],
                  onChanged: (v) => setState(() => type = v!),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  final amount =
                      double.tryParse(controller.text);
                  if (amount == null) return;

                  await ref
                      .read(savingsProvider.notifier)
                      .addSavings(
                        SavingsModel(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          amount: amount,
                          type: type,
                          date: DateTime.now(),
                        ),
                      );

                  Navigator.pop(context);
                },
                child: const Text("Save"),
              )
            ],
          );
        },
      ),
    );
  }
}