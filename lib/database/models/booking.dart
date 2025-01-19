import 'package:objectbox/objectbox.dart';
import 'room.dart';

enum PaymentStatus {
  unpaid,
  partiallyPaid,
  paid,
}

@Entity()
class Booking {
  @Id()
  int id;
  
  @Unique()
  final String uuid;
  
  @Property()
  DateTime checkIn;
  
  @Property()
  DateTime checkOut;
  
  String guestName;
  String guestPhone;
  double totalPrice;
  double amountPaid;
  String? notes;
  
  @Transient()
  PaymentStatus _paymentStatus = PaymentStatus.unpaid;

  PaymentStatus get paymentStatus => _paymentStatus;
  
  set paymentStatus(PaymentStatus value) {
    _paymentStatus = value;
    paymentStatusIndex = value.index;
  }

  @Property()
  int paymentStatusIndex = 0;

  final room = ToOne<Room>();

  Booking({
    this.id = 0,
    required this.uuid,
    required this.checkIn,
    required this.checkOut,
    required this.guestName,
    required this.guestPhone,
    required this.totalPrice,
    required this.amountPaid,
    this.notes,
    PaymentStatus paymentStatus = PaymentStatus.unpaid,
  }) {
    this.paymentStatus = paymentStatus;
  }

  Booking copyWith({
    DateTime? checkIn,
    DateTime? checkOut,
    String? guestName,
    String? guestPhone,
    double? totalPrice,
    double? amountPaid,
    String? notes,
    PaymentStatus? paymentStatus,
  }) {
    return Booking(
      id: id,
      uuid: uuid,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      guestName: guestName ?? this.guestName,
      guestPhone: guestPhone ?? this.guestPhone,
      totalPrice: totalPrice ?? this.totalPrice,
      amountPaid: amountPaid ?? this.amountPaid,
      notes: notes ?? this.notes,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}
