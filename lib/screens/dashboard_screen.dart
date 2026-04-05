import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/savings_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/savings_model.dart';
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

    // 💰 Total Savings
    double totalSavings = 0;
    for (var s in savingsList) {
      totalSavings +=
          s.type == "deposit" ? s.amount : -s.amount;
    }

    // 📊 Income & Expense
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _balanceCard(availableBalance, balance, totalSavings),

          const SizedBox(height: 20),

          // 📊 Stats
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      "Income", income, Colors.green)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildStatCard(
                      "Expense", expense, Colors.red)),
            ],
          ),

          const SizedBox(height: 20),

          // 📈 Weekly Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Weekly Trends",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                    children: [
                      _buildFilterChip(
                          "Income", showIncome, Colors.green, () {
                        setState(() => showIncome = !showIncome);
                      }),
                      _buildFilterChip(
                          "Expense", showExpense, Colors.red, () {
                        setState(() => showExpense = !showExpense);
                      }),
                      _buildFilterChip(
                          "Savings", showSavings, Colors.orange,
                          () {
                        setState(
                            () => showSavings = !showSavings);
                      }),
                    ],
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 240,
                    child: _buildWeeklyChart(
                        transactions, savingsList),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 💰 Savings Tile
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.savings, color: Colors.orange),
              title: const Text("Savings"),
              subtitle: Text("₹$totalSavings"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SavingsScreen()),
                );
              },
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  _showSavingsDialog(
                      context, ref, balance, totalSavings);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 💳 Balance Card
  Widget _balanceCard(double available, double total, double savings) {
    return Container(
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
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text("Total: ₹$total | Savings: ₹$savings",
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // 📊 Stat Card
  Widget _buildStatCard(
      String title, double amount, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title),
            const SizedBox(height: 5),
            Text(
              "₹$amount",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // 🎛 Filter Chip
  Widget _buildFilterChip(
      String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.black)),
      ),
    );
  }

  // 📈 Weekly Chart
  Widget _buildWeeklyChart(transactions, savingsList) {
    final now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    List<double> incomeData = List.filled(7, 0);
    List<double> expenseData = List.filled(7, 0);
    List<double> savingsData = List.filled(7, 0);

    for (var tx in transactions) {
      DateTime txDate =
          DateTime(tx.date.year, tx.date.month, tx.date.day);
      final diff = today.difference(txDate).inDays;

      if (diff >= 0 && diff < 7) {
        final index = 6 - diff;
        if (tx.type == "income") {
          incomeData[index] += tx.amount;
        } else {
          expenseData[index] += tx.amount;
        }
      }
    }

    for (var s in savingsList) {
      DateTime sDate =
          DateTime(s.date.year, s.date.month, s.date.day);
      final diff = today.difference(sDate).inDays;

      if (diff >= 0 && diff < 7) {
        final index = 6 - diff;
        savingsData[index] +=
            s.type == "deposit" ? s.amount : -s.amount;
      }
    }

    double maxY = 0;
    for (int i = 0; i < 7; i++) {
      maxY = max(maxY,
          max(incomeData[i], max(expenseData[i], savingsData[i])));
    }
    maxY *= 1.2;

    List<LineChartBarData> lines = [];

    if (showIncome) {
      lines.add(LineChartBarData(
        spots: List.generate(
            7, (i) => FlSpot(i.toDouble(), incomeData[i])),
        isCurved: true,
        color: Colors.green,
      ));
    }

    if (showExpense) {
      lines.add(LineChartBarData(
        spots: List.generate(
            7, (i) => FlSpot(i.toDouble(), expenseData[i])),
        isCurved: true,
        color: Colors.red,
      ));
    }

    if (showSavings) {
      lines.add(LineChartBarData(
        spots: List.generate(
            7, (i) => FlSpot(i.toDouble(), savingsData[i])),
        isCurved: true,
        color: Colors.orange,
      ));
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: maxY,
        lineBarsData: lines,
      ),
    );
  }

  // 💰 Savings Dialog (FINAL)
  void _showSavingsDialog(
    BuildContext context,
    WidgetRef ref,
    double balance,
    double totalSavings,
  ) {
    final controller = TextEditingController();
    DateTime selectedDate = DateTime.now();
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

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(
                        value: "deposit",
                        child: Text("Deposit")),
                    DropdownMenuItem(
                        value: "withdraw",
                        child: Text("Withdraw")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => type = val);
                    }
                  },
                  decoration:
                      const InputDecoration(labelText: "Type"),
                ),

                const SizedBox(height: 10),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  final amount =
                      double.tryParse(controller.text.trim());

                  if (amount == null || amount <= 0) return;

                  if (type == "withdraw" &&
                      amount > totalSavings) return;

                  if (type == "deposit" &&
                      amount > balance - totalSavings) return;

                  await ref
                      .read(savingsProvider.notifier)
                      .addSavings(
                        SavingsModel(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          amount: amount,
                          type: type,
                          date: selectedDate,
                        ),
                      );

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }
}