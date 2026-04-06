import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/transaction_provider.dart';
import '../providers/savings_provider.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen>
    with SingleTickerProviderStateMixin {
  bool showMonthly = true;
  bool showIncome = true;
  bool showExpense = true;
  bool showSavings = true;

  late AnimationController _controller;
  late Animation<double> fadeAnim;
  late Animation<Offset> slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionProvider);
    final savingsList = ref.watch(savingsProvider);

    if (transactions.isEmpty) {
      return const Center(child: Text("No data available"));
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Map<String, double> categoryTotals = {};
    Map<String, int> typeCount = {};

    double thisWeek = 0;
    double lastWeek = 0;

    for (var tx in transactions) {
      final d = DateTime(tx.date.year, tx.date.month, tx.date.day);

      if (tx.type == "expense") {
        categoryTotals[tx.category] =
            (categoryTotals[tx.category] ?? 0) + tx.amount;
      }

      typeCount[tx.type] = (typeCount[tx.type] ?? 0) + 1;

      final diff = today.difference(d).inDays;

      if (tx.type == "expense") {
        if (diff <= 7) {
          thisWeek += tx.amount;
        } else if (diff <= 14) {
          lastWeek += tx.amount;
        }
      }
    }

    String topCategory = "";
    double maxAmount = 0;

    categoryTotals.forEach((k, v) {
      if (v > maxAmount) {
        maxAmount = v;
        topCategory = k;
      }
    });

    String frequentType = "";
    int maxCount = 0;

    typeCount.forEach((k, v) {
      if (v > maxCount) {
        maxCount = v;
        frequentType = k;
      }
    });

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Insights",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              // 🔥 TOP SECTION
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _infoCard(
                          "Top Category",
                          topCategory,
                          Colors.orange,
                          Icons.star,
                        ),
                        const SizedBox(height: 12),
                        _infoCard(
                          "Frequent Type",
                          frequentType,
                          Colors.blue,
                          Icons.repeat,
                        ),
                        const SizedBox(height: 12),
                        _infoCard(
                          "Weekly",
                          "₹${thisWeek.toInt()} vs ₹${lastWeek.toInt()}",
                          Colors.purple,
                          Icons.bar_chart,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _pieChart(categoryTotals, colors)),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                "Trends",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              // 🔘 TOGGLE
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _toggle(
                    "Monthly",
                    showMonthly,
                    () => setState(() => showMonthly = true),
                  ),
                  const SizedBox(width: 10),
                  _toggle(
                    "Yearly",
                    !showMonthly,
                    () => setState(() => showMonthly = false),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 🔘 FILTERS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _filter(
                    "Income",
                    showIncome,
                    Colors.green,
                    () => setState(() => showIncome = !showIncome),
                  ),
                  _filter(
                    "Expense",
                    showExpense,
                    Colors.red,
                    () => setState(() => showExpense = !showExpense),
                  ),
                  _filter(
                    "Savings",
                    showSavings,
                    Colors.orange,
                    () => setState(() => showSavings = !showSavings),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 📈 GRAPH CARD
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  key: ValueKey(showMonthly),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 260,
                      child: showMonthly
                          ? _monthlyChart(transactions, savingsList)
                          : _yearlyChart(transactions, savingsList),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 PIE CHART FIXED
  Widget _pieChart(Map<String, double> categoryTotals, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: SizedBox(
        height: 140,
        child: PieChart(
          PieChartData(
            sections: categoryTotals.entries
                .toList()
                .asMap()
                .entries
                .map<PieChartSectionData>((entry) {
                  int i = entry.key;
                  var e = entry.value;

                  return PieChartSectionData(
                    value: e.value.toDouble(),
                    color: colors[i % colors.length],
                    radius: 45,
                  );
                })
                .toList(),
          ),
        ),
      ),
    );
  }

  // 🔥 LINE CHART FIXED
  Widget _buildLineChart(
    List<double> income,
    List<double> expense,
    List<double> savings,
  ) {
    List<LineChartBarData> lines = [];

    if (showIncome) {
      lines.add(
        LineChartBarData(
          spots: List<FlSpot>.generate(
            income.length,
            (i) => FlSpot(i.toDouble(), income[i]),
          ),
          isCurved: true,
          color: Colors.green,
        ),
      );
    }

    if (showExpense) {
      lines.add(
        LineChartBarData(
          spots: List<FlSpot>.generate(
            expense.length,
            (i) => FlSpot(i.toDouble(), expense[i]),
          ),
          isCurved: true,
          color: Colors.red,
        ),
      );
    }

    if (showSavings) {
      lines.add(
        LineChartBarData(
          spots: List<FlSpot>.generate(
            savings.length,
            (i) => FlSpot(i.toDouble(), savings[i]),
          ),
          isCurved: true,
          color: Colors.orange,
        ),
      );
    }

    return LineChart(LineChartData(lineBarsData: lines));
  }

  Widget _monthlyChart(transactions, savingsList) {
    List<double> income = List.filled(30, 0);
    List<double> expense = List.filled(30, 0);
    List<double> savings = List.filled(30, 0);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var tx in transactions) {
      final diff = today
          .difference(DateTime(tx.date.year, tx.date.month, tx.date.day))
          .inDays;

      if (diff >= 0 && diff < 30) {
        int i = 29 - diff;
        if (tx.type == "income") {
          income[i] += tx.amount;
        } else {
          expense[i] += tx.amount;
        }
      }
    }

    for (var s in savingsList) {
      final diff = today
          .difference(DateTime(s.date.year, s.date.month, s.date.day))
          .inDays;

      if (diff >= 0 && diff < 30) {
        int i = 29 - diff;
        savings[i] += s.type == "deposit" ? s.amount : -s.amount;
      }
    }

    return _buildLineChart(income, expense, savings);
  }

  Widget _yearlyChart(transactions, savingsList) {
    List<double> income = List.filled(12, 0);
    List<double> expense = List.filled(12, 0);
    List<double> savings = List.filled(12, 0);

    for (var tx in transactions) {
      int m = tx.date.month - 1;
      if (tx.type == "income") {
        income[m] += tx.amount;
      } else {
        expense[m] += tx.amount;
      }
    }

    for (var s in savingsList) {
      int m = s.date.month - 1;
      savings[m] += s.type == "deposit" ? s.amount : -s.amount;
    }

    return _buildLineChart(income, expense, savings);
  }

  // 🎨 UI
  Widget _infoCard(
    String title, String value, Color color, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: _cardDecoration(),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    ),
  );
}

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
      ],
    );
  }

  Widget _toggle(String label, bool selected, VoidCallback f) {
    return GestureDetector(
      onTap: f,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _filter(String label, bool selected, Color color, VoidCallback f) {
    return GestureDetector(
      onTap: f,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
