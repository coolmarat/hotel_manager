import 'dart:convert';
import 'package:hotel_manager/database/models/room.dart';
import 'package:hotel_manager/database/models/booking.dart';
import 'package:hotel_manager/database/models/client.dart';

/// Модель для экспорта/импорта данных базы
class DatabaseExport {
  final String version;
  final DateTime exportDate;
  final List<RoomExport> rooms;
  final List<BookingExport> bookings;
  final List<ClientExport> clients;

  DatabaseExport({
    required this.version,
    required this.exportDate,
    required this.rooms,
    required this.bookings,
    required this.clients,
  });

  /// Создает объект из JSON
  factory DatabaseExport.fromJson(Map<String, dynamic> json) {
    return DatabaseExport(
      version: json['version'] as String,
      exportDate: DateTime.parse(json['exportDate'] as String),
      rooms: (json['rooms'] as List)
          .map((e) => RoomExport.fromJson(e as Map<String, dynamic>))
          .toList(),
      bookings: (json['bookings'] as List)
          .map((e) => BookingExport.fromJson(e as Map<String, dynamic>))
          .toList(),
      clients: (json['clients'] as List)
          .map((e) => ClientExport.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Преобразует объект в JSON
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'exportDate': exportDate.toIso8601String(),
      'rooms': rooms.map((e) => e.toJson()).toList(),
      'bookings': bookings.map((e) => e.toJson()).toList(),
      'clients': clients.map((e) => e.toJson()).toList(),
    };
  }

  /// Преобразует объект в строку JSON
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Создает объект из строки JSON
  static DatabaseExport fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return DatabaseExport.fromJson(json);
  }
}

/// Модель для экспорта/импорта данных комнаты
class RoomExport {
  final String uuid;
  final String name;
  final String type;
  final int capacity;
  final double basePrice;
  final String? description;
  final int statusIndex;

  RoomExport({
    required this.uuid,
    required this.name,
    required this.type,
    required this.capacity,
    required this.basePrice,
    this.description,
    required this.statusIndex,
  });

  /// Создает объект из модели Room
  factory RoomExport.fromRoom(Room room) {
    return RoomExport(
      uuid: room.uuid,
      name: room.name,
      type: room.type,
      capacity: room.capacity,
      basePrice: room.basePrice,
      description: room.description,
      statusIndex: room.statusIndex,
    );
  }

  /// Создает модель Room из объекта экспорта
  Room toRoom() {
    return Room(
      uuid: uuid,
      name: name,
      type: type,
      capacity: capacity,
      basePrice: basePrice,
      description: description,
      status: RoomStatus.values[statusIndex],
    );
  }

  /// Создает объект из JSON
  factory RoomExport.fromJson(Map<String, dynamic> json) {
    return RoomExport(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      capacity: json['capacity'] as int,
      basePrice: (json['basePrice'] as num).toDouble(),
      description: json['description'] as String?,
      statusIndex: json['statusIndex'] as int,
    );
  }

  /// Преобразует объект в JSON
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'type': type,
      'capacity': capacity,
      'basePrice': basePrice,
      'description': description,
      'statusIndex': statusIndex,
    };
  }
}

/// Модель для экспорта/импорта данных бронирования
class BookingExport {
  final String uuid;
  final String checkIn;
  final String checkOut;
  final String guestName;
  final String guestPhone;
  final double totalPrice;
  final double amountPaid;
  final String? notes;
  final int paymentStatusIndex;
  final String roomUuid;

  BookingExport({
    required this.uuid,
    required this.checkIn,
    required this.checkOut,
    required this.guestName,
    required this.guestPhone,
    required this.totalPrice,
    required this.amountPaid,
    this.notes,
    required this.paymentStatusIndex,
    required this.roomUuid,
  });

  /// Создает объект из модели Booking
  factory BookingExport.fromBooking(Booking booking) {
    return BookingExport(
      uuid: booking.uuid,
      checkIn: booking.checkIn.toIso8601String(),
      checkOut: booking.checkOut.toIso8601String(),
      guestName: booking.guestName,
      guestPhone: booking.guestPhone,
      totalPrice: booking.totalPrice,
      amountPaid: booking.amountPaid,
      notes: booking.notes,
      paymentStatusIndex: booking.paymentStatusIndex,
      roomUuid: booking.room.target?.uuid ?? '',
    );
  }

  /// Создает модель Booking из объекта экспорта
  Booking toBooking() {
    return Booking(
      uuid: uuid,
      checkIn: DateTime.parse(checkIn),
      checkOut: DateTime.parse(checkOut),
      guestName: guestName,
      guestPhone: guestPhone,
      totalPrice: totalPrice,
      amountPaid: amountPaid,
      notes: notes,
      paymentStatus: PaymentStatus.values[paymentStatusIndex],
    );
  }

  /// Создает объект из JSON
  factory BookingExport.fromJson(Map<String, dynamic> json) {
    return BookingExport(
      uuid: json['uuid'] as String,
      checkIn: json['checkIn'] as String,
      checkOut: json['checkOut'] as String,
      guestName: json['guestName'] as String,
      guestPhone: json['guestPhone'] as String,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      amountPaid: (json['amountPaid'] as num).toDouble(),
      notes: json['notes'] as String?,
      paymentStatusIndex: json['paymentStatusIndex'] as int,
      roomUuid: json['roomUuid'] as String,
    );
  }

  /// Преобразует объект в JSON
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'guestName': guestName,
      'guestPhone': guestPhone,
      'totalPrice': totalPrice,
      'amountPaid': amountPaid,
      'notes': notes,
      'paymentStatusIndex': paymentStatusIndex,
      'roomUuid': roomUuid,
    };
  }
}

/// Модель для экспорта/импорта данных клиента
class ClientExport {
  final String name;
  final String phone;
  final String? notes;

  ClientExport({
    required this.name,
    required this.phone,
    this.notes,
  });

  /// Создает объект из модели Client
  factory ClientExport.fromClient(Client client) {
    return ClientExport(
      name: client.name,
      phone: client.phone,
      notes: client.notes,
    );
  }

  /// Создает модель Client из объекта экспорта
  Client toClient() {
    return Client(
      name: name,
      phone: phone,
      notes: notes,
    );
  }

  /// Создает объект из JSON
  factory ClientExport.fromJson(Map<String, dynamic> json) {
    return ClientExport(
      name: json['name'] as String,
      phone: json['phone'] as String,
      notes: json['notes'] as String?,
    );
  }

  /// Преобразует объект в JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'notes': notes,
    };
  }
}
