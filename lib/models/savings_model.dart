class SavingsModel {
  final String id;
  final double amount;
  final String type; // deposit / withdraw
  final DateTime date;

  SavingsModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
  });
}