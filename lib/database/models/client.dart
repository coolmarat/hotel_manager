import 'package:objectbox/objectbox.dart';

@Entity()
class Client {
  @Id()
  int id;
  
  String name;
  String phone;
  String? notes;

  Client({
    this.id = 0,
    required this.name,
    required this.phone,
    this.notes,
  });

  // Helper method to get clean phone number (digits only)
  String get cleanPhone => phone.replaceAll(RegExp(r'[^\d]'), '');
}
