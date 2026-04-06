import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/transaction_provider.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transactions"),
      ),

      body: transactions.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];

                final isExpense = tx.type == "expense";

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),

                    // 🎨 ICON
                    leading: CircleAvatar(
                      backgroundColor: isExpense
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      child: Icon(
                        isExpense
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color:
                            isExpense ? Colors.red : Colors.green,
                      ),
                    ),

                    // 📌 TITLE
                    title: Text(
                      tx.category,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),

                    // 📅 SUBTITLE
                    subtitle: Text(
                        "${tx.note} • ${tx.date.day}/${tx.date.month}/${tx.date.year}"),

                    // 💰 AMOUNT
                    trailing: Text(
                      "₹${tx.amount}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isExpense
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),

                    // 👉 TAP ACTION
                    onTap: () {
                      _showOptions(context, ref, tx);
                    },
                  ),
                );
              },
            ),

      // ➕ FAB
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        onPressed: () {
          _openAddTransaction(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ❌ EMPTY STATE
  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "No transactions yet",
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  // 📥 ADD TRANSACTION
  void _openAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: const AddTransactionScreen(),
        );
      },
    );
  }

  // ⚙️ OPTIONS SHEET
  void _showOptions(BuildContext context, WidgetRef ref, dynamic tx) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit"),
                onTap: () {
                  Navigator.pop(context);

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: AddTransactionScreen(existingTx: tx),
                      );
                    },
                  );
                },
              ),

              ListTile(
                leading:
                    const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete"),
                onTap: () {
                  ref
                      .read(transactionProvider.notifier)
                      .deleteTransaction(tx.id);

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}