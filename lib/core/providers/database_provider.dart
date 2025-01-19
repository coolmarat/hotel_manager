import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/objectbox.dart';
import '../../database/repositories/booking_repository.dart';
import '../../database/repositories/room_repository.dart';

final objectBoxInitializerProvider = FutureProvider<ObjectBox>((ref) async {
  final objectBox = await ObjectBox.create();
  return objectBox;
});

final objectBoxProvider = Provider<ObjectBox>((ref) {
  return ref.watch(objectBoxInitializerProvider).value!;
});

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final objectBox = ref.watch(objectBoxProvider);
  return RoomRepository(objectBox);
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final objectBox = ref.watch(objectBoxProvider);
  return BookingRepository(objectBox);
});
