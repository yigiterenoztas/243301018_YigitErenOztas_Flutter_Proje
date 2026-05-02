class ExpenseModel {
  final String id;
  final String userId;
  final String reservationId;
  final String description;
  final double amount;
  final DateTime date;

  const ExpenseModel({
    required this.id,
    required this.userId,
    required this.reservationId,
    required this.description,
    required this.amount,
    required this.date,
  });
}
