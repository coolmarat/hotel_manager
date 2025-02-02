import '../models/client.dart';
import '../objectbox.dart';
import 'package:objectbox/objectbox.dart';

class ClientRepository {
  final Store _store;
  late final Box<Client> _box;

  ClientRepository(this._store) {
    _box = _store.box<Client>();
  }

  Client findByPhone(String phone) {
    // Clean the input phone number
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Query all clients and check their clean phone numbers
    final clients = _box.getAll();
    try {
      return clients.firstWhere(
        (client) => client.cleanPhone.contains(cleanPhone),
      );
    } catch (e) {
      return Client(name: '', phone: '');
    }
  }

  Client createOrFind(String name, String phone, {String? notes}) {
    final existingClient = findByPhone(phone);
    if (existingClient.name.isNotEmpty) {
      // Если у существующего клиента нет заметок, но новые предоставлены,
      // обновляем заметки
      if (existingClient.notes == null && notes != null) {
        existingClient.notes = notes;
        _box.put(existingClient);
      }
      return existingClient;
    }
    
    final newClient = Client(
      name: name,
      phone: phone,
      notes: notes,
    );
    _box.put(newClient);
    return newClient;
  }

  List<Client> searchClients(String query) {
    if (query.isEmpty) {
      return _box.getAll();
    }

    final cleanQuery = query.toLowerCase();
    final clients = _box.getAll();
    
    return clients.where((client) {
      return client.name.toLowerCase().contains(cleanQuery) ||
             client.phone.contains(cleanQuery) ||
             client.cleanPhone.contains(cleanQuery);
    }).toList();
  }
}
