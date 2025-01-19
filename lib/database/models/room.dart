import 'package:objectbox/objectbox.dart';
import 'booking.dart';

enum RoomStatus {
  available,
  occupied,
  cleaning,
  maintenance,
}

@Entity()
class Room {
  @Id()
  int id;
  
  @Unique()
  final String uuid;
  
  String name;
  String type;
  int capacity;
  double basePrice;
  String? description;
  
  @Transient()
  RoomStatus _status = RoomStatus.available;

  RoomStatus get status => _status;
  
  set status(RoomStatus value) {
    _status = value;
    statusIndex = value.index;
  }

  @Property()
  int statusIndex = 0;

  @Backlink('room')
  final bookings = ToMany<Booking>();

  Room({
    this.id = 0,
    required this.uuid,
    required this.name,
    required this.type,
    required this.capacity,
    required this.basePrice,
    this.description,
    RoomStatus status = RoomStatus.available,
  }) {
    this.status = status;
  }

  Room copyWith({
    String? name,
    String? type,
    int? capacity,
    double? basePrice,
    String? description,
    RoomStatus? status,
  }) {
    return Room(
      id: id,
      uuid: uuid,
      name: name ?? this.name,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      basePrice: basePrice ?? this.basePrice,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }
}
