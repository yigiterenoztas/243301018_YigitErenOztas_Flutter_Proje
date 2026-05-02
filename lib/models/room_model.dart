class RoomModel {
  final String id;
  final String name;
  final double pricePerNight;
  final bool isAvailable;

  const RoomModel({
    required this.id,
    required this.name,
    required this.pricePerNight,
    required this.isAvailable,
  });
}
