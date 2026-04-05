import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/savings_provider.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsList = ref.watch(savingsProvider);

    if (savingsList.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No savings yet")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Savings History")),
      body: ListView.builder(
        itemCount: savingsList.length,
        itemBuilder: (context, index) {
          final s = savingsList[index];

          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Icon(
                s.type == "deposit"
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: s.type == "deposit"
                    ? Colors.green
                    : Colors.red,
              ),
              title: Text(
                s.type == "deposit"
                    ? "Saved ₹${s.amount}"
                    : "Withdraw ₹${s.amount}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                  "${s.date.day}/${s.date.month}/${s.date.year}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  ref
                      .read(savingsProvider.notifier)
                      .deleteSavings(s.id);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}