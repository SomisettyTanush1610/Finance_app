import '../models/transaction_model.dart';
import 'database_helper.dart';

class TransactionService {
  final dbHelper = DatabaseHelper.instance;

  // ➕ INSERT
  Future<void> insertTransaction(TransactionModel tx) async {
    final db = await dbHelper.database;

    await db.insert('transactions', {
      'id': tx.id,
      'amount': tx.amount,
      'type': tx.type,
      'category': tx.category,
      'note': tx.note, // ✅ FIX
      'date': tx.date.toIso8601String(),
    });
  }

  // 📥 GET ALL
  Future<List<TransactionModel>> getTransactions() async {
    final db = await dbHelper.database;

    final result = await db.query('transactions');

    return result.map<TransactionModel>((e) {
      return TransactionModel(
        id: e['id'] as String,
        amount: (e['amount'] as num).toDouble(),
        type: e['type'] as String,
        category: e['category'] as String,
        note: e['note'] as String, // ✅ FIX
        date: DateTime.parse(e['date'] as String),
      );
    }).toList();
  }

  // ❌ DELETE
  Future<void> deleteTransaction(String id) async {
    final db = await dbHelper.database;

    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ✏️ UPDATE (MISSING BEFORE)
  Future<void> updateTransaction(TransactionModel tx) async {
    final db = await dbHelper.database;

    await db.update(
      'transactions',
      {
        'amount': tx.amount,
        'type': tx.type,
        'category': tx.category,
        'note': tx.note, // ✅ FIX
        'date': tx.date.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }
}