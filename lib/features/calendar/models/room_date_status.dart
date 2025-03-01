enum RoomDateStatus {
  available, // Комната свободна в этот день
  occupied,  // Комната занята в этот день
  checkIn,   // В этот день заезд
  checkOut,  // В этот день выезд
}

class RoomWithStatus {
  final String uuid;
  final String name;
  final String type;
  final RoomDateStatus status;
  final String? guestName;
  final DateTime? checkIn;
  final DateTime? checkOut;

  RoomWithStatus({
    required this.uuid,
    required this.name,
    required this.type,
    required this.status,
    this.guestName,
    this.checkIn,
    this.checkOut,
  });
}
