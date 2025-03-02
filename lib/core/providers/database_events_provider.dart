import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Типы событий базы данных
enum DatabaseEventType {
  /// База данных была очищена
  cleared,
  
  /// Данные были сброшены к начальному состоянию
  reset,
  
  /// Данные были импортированы
  imported,
}

/// Класс события базы данных
class DatabaseEvent {
  final DatabaseEventType type;
  final DateTime timestamp;
  
  DatabaseEvent(this.type) : timestamp = DateTime.now();
}

/// Провайдер для событий базы данных
final databaseEventProvider = StateProvider<DatabaseEvent?>((ref) => null);
