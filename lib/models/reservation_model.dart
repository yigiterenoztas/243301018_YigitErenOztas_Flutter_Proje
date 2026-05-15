class ReservationModel {
  final String id;
  final String userId;
  final String roomId;
  final DateTime checkIn;
  final DateTime checkOut;
  final String status;

  const ReservationModel({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.checkIn,
    required this.checkOut,
    required this.status,
  });
}
