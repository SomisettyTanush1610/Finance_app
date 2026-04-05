import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? existingTx;

  const AddTransactionScreen({super.key, this.existingTx});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends ConsumerState<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _customCategoryController = TextEditingController();

  String _type = "expense";
  String _category = "Food";
  DateTime _selectedDate = DateTime.now();

  bool isLoading = false;

  final List<String> incomeCategories = [
    "Salary",
    "Freelance",
    "Gift",
    "Other"
  ];

  final List<String> expenseCategories = [
    "Food",
    "Travel",
    "Shopping",
    "Bills",
    "Other"
  ];

  @override
  void initState() {
    super.initState();

    final tx = widget.existingTx;
    if (tx != null) {
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note;
      _type = tx.type;
      _selectedDate = tx.date;

      if ((_type == "income" &&
              !incomeCategories.contains(tx.category)) ||
          (_type == "expense" &&
              !expenseCategories.contains(tx.category))) {
        _category = "Other";
        _customCategoryController.text = tx.category;
      } else {
        _category = tx.category;
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Future<void> _submit() async {
    try {
      final text = _amountController.text.trim();

      if (text.isEmpty) {
        _showError("Enter amount");
        return;
      }

      final amount = double.tryParse(text);
      if (amount == null || amount <= 0) {
        _showError("Invalid amount");
        return;
      }

      final finalCategory = _category == "Other"
          ? _customCategoryController.text.trim()
          : _category;

      if (finalCategory.isEmpty) {
        _showError("Enter category");
        return;
      }

      final tx = TransactionModel(
        id: widget.existingTx?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        type: _type,
        category: finalCategory,
        date: _selectedDate,
        note: _noteController.text.trim(),
      );

      setState(() => isLoading = true);

      if (widget.existingTx != null) {
        await ref
            .read(transactionProvider.notifier)
            .updateTransaction(tx);
      } else {
        await ref
            .read(transactionProvider.notifier)
            .addTransaction(tx);
      }

      setState(() => isLoading = false);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError("Something went wrong: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingTx != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 💰 Amount
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: "Amount",
                    prefixText: "₹ ",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 📂 Type + Category
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField(
                      value: _type,
                      items: const [
                        DropdownMenuItem(
                            value: "income", child: Text("Income")),
                        DropdownMenuItem(
                            value: "expense", child: Text("Expense")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _type = value!;
                          _category = (_type == "income")
                              ? incomeCategories[0]
                              : expenseCategories[0];
                        });
                      },
                      decoration:
                          const InputDecoration(labelText: "Type"),
                    ),

                    const SizedBox(height: 10),

                    DropdownButtonFormField(
                      value: _category,
                      items: (_type == "income"
                              ? incomeCategories
                              : expenseCategories)
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _category = value!;
                        });
                      },
                      decoration:
                          const InputDecoration(labelText: "Category"),
                    ),

                    if (_category == "Other") ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _customCategoryController,
                        decoration: const InputDecoration(
                          labelText: "Custom Category",
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 📅 Date
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text("Date"),
                subtitle: Text(
                    "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );

                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
            ),

            const SizedBox(height: 12),

            // 📝 Note
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Note",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🚀 Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit
                        ? "Update Transaction"
                        : "Add Transaction"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}