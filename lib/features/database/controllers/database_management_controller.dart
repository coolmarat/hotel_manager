import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_manager/core/providers/database_events_provider.dart';
import 'package:hotel_manager/core/providers/database_provider.dart';
import 'package:hotel_manager/features/database/repositories/database_export_repository.dart';

/// Состояние контроллера управления базой данных
class DatabaseManagementState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  DatabaseManagementState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  DatabaseManagementState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return DatabaseManagementState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

/// Провайдер репозитория экспорта базы данных
final databaseExportRepositoryProvider = Provider<DatabaseExportRepository>((ref) {
  final roomRepository = ref.watch(roomRepositoryProvider);
  final bookingRepository = ref.watch(bookingRepositoryProvider);
  final clientRepository = ref.watch(clientRepositoryProvider);
  final objectBox = ref.watch(objectBoxProvider);
  
  return DatabaseExportRepository(
    roomRepository: roomRepository,
    bookingRepository: bookingRepository,
    clientRepository: clientRepository,
    objectBox: objectBox,
  );
});

/// Провайдер контроллера управления базой данных
final databaseManagementControllerProvider =
    StateNotifierProvider<DatabaseManagementController, DatabaseManagementState>(
  (ref) => DatabaseManagementController(
    exportRepository: ref.watch(databaseExportRepositoryProvider),
    ref: ref,
  ),
);

/// Контроллер управления базой данных
class DatabaseManagementController extends StateNotifier<DatabaseManagementState> {
  final DatabaseExportRepository _exportRepository;
  final Ref _ref;

  DatabaseManagementController({
    required DatabaseExportRepository exportRepository,
    required Ref ref,
  })  : _exportRepository = exportRepository,
        _ref = ref,
        super(DatabaseManagementState());

  /// Экспортирует базу данных в файл
  Future<String?> exportDatabase(BuildContext context) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    
    try {
      // Экспортируем данные
      final databaseExport = await _exportRepository.exportDatabase();
      
      // Сохраняем в файл
      final filePath = await _exportRepository.saveExportFile(databaseExport);
      
      if (filePath != null) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'База данных успешно экспортирована в файл',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Экспорт отменен',
        );
      }
      
      return filePath;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка при экспорте базы данных: $e',
      );
      return null;
    }
  }

  /// Импортирует базу данных из файла
  Future<void> importDatabase(BuildContext context) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    
    try {
      // Импортируем данные из файла
      final result = await _exportRepository.importFromFile();
      
      if (result) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'База данных успешно импортирована',
        );
        
        // Отправляем событие об импорте данных
        _ref.read(databaseEventProvider.notifier).state = DatabaseEvent(DatabaseEventType.imported);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Не удалось импортировать базу данных',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка при импорте базы данных: $e',
      );
    }
  }

  /// Очищает базу данных
  Future<void> clearDatabase(BuildContext context) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    
    try {
      // Очищаем базу данных
      final result = await _exportRepository.clearAllData();
      
      if (result) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'База данных успешно очищена',
        );
        
        // Отправляем событие об очистке базы данных
        _ref.read(databaseEventProvider.notifier).state = DatabaseEvent(DatabaseEventType.cleared);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Не удалось очистить базу данных',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка при очистке базы данных: $e',
      );
    }
  }

  /// Очищает базу данных и добавляет примеры комнат
  Future<void> resetDatabase(BuildContext context) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    
    try {
      final result = await _exportRepository.resetToInitialData();
      
      if (result) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Примеры комнат успешно добавлены',
        );
        
        // Отправляем событие о сбросе базы данных
        _ref.read(databaseEventProvider.notifier).state = DatabaseEvent(DatabaseEventType.reset);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Не удалось добавить примеры комнат',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка при добавлении примеров комнат: $e',
      );
    }
  }

  /// Сбрасывает сообщения
  void resetMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}
