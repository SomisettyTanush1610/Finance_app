import '../models/savings_model.dart';
import 'database_helper.dart';

class SavingsService {
  final dbHelper = DatabaseHelper.instance;

  Future<void> insertSavings(SavingsModel s) async {
    final db = await dbHelper.database;

    await db.insert('savings', {
      'id': s.id,
      'amount': s.amount,
      'type': s.type,
      'date': s.date.toIso8601String(),
    });
  }

  Future<List<SavingsModel>> getSavings() async {
    final db = await dbHelper.database;

    final result = await db.query('savings');

    return result.map<SavingsModel>((e) {
      return SavingsModel(
        id: e['id'] as String,
        amount: (e['amount'] as num).toDouble(),
        type: e['type'] as String,
        date: DateTime.parse(e['date'] as String),
      );
    }).toList();
  }

  Future<void> deleteSavings(String id) async {
    final db = await dbHelper.database;

    await db.delete(
      'savings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}