import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:objectbox/objectbox.dart';
import '../objectbox.g.dart';
import 'models/room.dart';
import 'models/booking.dart';

class ObjectBox {
  late final Store store;
  late final Box<Room> roomBox;
  late final Box<Booking> bookingBox;

  ObjectBox._create(this.store) {
    roomBox = Box<Room>(store);
    bookingBox = Box<Booking>(store);

    // Add initial data if the database is empty
    if (roomBox.isEmpty()) {
      _addInitialData();
    }
  }

  void _addInitialData() {
    // Add some sample rooms
    final rooms = [
      Room(
        id: 0,
        uuid: '1',
        name: 'Room 101',
        type: 'Standard',
        capacity: 2,
        basePrice: 100.0,
        status: RoomStatus.available,
      ),
      Room(
        id: 0,
        uuid: '2',
        name: 'Room 102',
        type: 'Deluxe',
        capacity: 3,
        basePrice: 150.0,
        status: RoomStatus.available,
      ),
      Room(
        id: 0,
        uuid: '3',
        name: 'Suite 201',
        type: 'Suite',
        capacity: 4,
        basePrice: 250.0,
        status: RoomStatus.available,
      ),
    ];

    roomBox.putMany(rooms);
  }

  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbDirectory = path.join(docsDir.path, 'objectbox');
    
    final store = await openStore(
      directory: dbDirectory,
    );
    
    return ObjectBox._create(store);
  }

  void dispose() {
    store.close();
  }
}
