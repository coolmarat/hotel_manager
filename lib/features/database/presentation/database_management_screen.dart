import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_manager/core/localization/strings.dart';
import 'package:hotel_manager/features/database/controllers/database_management_controller.dart';

class DatabaseManagementScreen extends ConsumerStatefulWidget {
  const DatabaseManagementScreen({super.key});

  @override
  ConsumerState<DatabaseManagementScreen> createState() => _DatabaseManagementScreenState();
}

class _DatabaseManagementScreenState extends ConsumerState<DatabaseManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(databaseManagementControllerProvider);
    final controller = ref.read(databaseManagementControllerProvider.notifier);
    
    // Показываем сообщение об успехе
    if (state.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        controller.resetMessages();
      });
    }
    
    // Показываем сообщение об ошибке
    if (state.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        controller.resetMessages();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление базой данных'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Управление базой данных',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Здесь вы можете экспортировать или импортировать базу данных. '
                  'Экспорт создаст файл с данными всех комнат, бронирований и клиентов. '
                  'Импорт заменит все текущие данные на данные из файла.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                _buildFeatureCard(
                  context,
                  title: 'Экспорт базы данных',
                  description: 'Сохраните все данные в файл для резервного копирования или переноса на другое устройство.',
                  icon: Icons.upload_file,
                  onTap: () => controller.exportDatabase(context),
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  context,
                  title: 'Импорт базы данных',
                  description: 'Загрузите данные из файла. Внимание: текущие данные будут заменены!',
                  icon: Icons.download_rounded,
                  onTap: () => _showImportConfirmationDialog(context, controller),
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  context,
                  title: 'Очистить базу данных',
                  description: 'Удалить все данные из базы данных. Внимание: это действие нельзя отменить!',
                  icon: Icons.delete_forever,
                  onTap: () => _showClearDatabaseConfirmationDialog(context, controller),
                  color: Colors.red,
                ),
                // const SizedBox(height: 16),
                // _buildFeatureCard(
                //   context,
                //   title: 'Сбросить базу данных к начальному состоянию',
                //   description: 'Очистить базу данных и добавить стандартные комнаты.',
                //   icon: Icons.restart_alt,
                //   onTap: () => _showResetDatabaseConfirmationDialog(context, controller),
                //   color: Colors.orange,
                // ),
                const SizedBox(height: 32),
                const Text(
                  'Формат данных',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Данные экспортируются в формате JSON, который содержит информацию о комнатах, '
                  'бронированиях и клиентах. Файл можно открыть в любом текстовом редакторе, '
                  'но не рекомендуется вносить изменения вручную, так как это может привести к ошибкам.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          if (state.isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.blue,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportConfirmationDialog(
    BuildContext context,
    DatabaseManagementController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение импорта'),
        content: const Text(
          'Импорт базы данных заменит все текущие данные. '
          'Этот процесс нельзя отменить. Вы уверены, что хотите продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.importDatabase(context);
            },
            child: const Text('Импортировать'),
          ),
        ],
      ),
    );
  }
  
  void _showClearDatabaseConfirmationDialog(
    BuildContext context,
    DatabaseManagementController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение очистки'),
        content: const Text(
          'Очистка базы данных удалит все бронирования, клиентов и комнаты. '
          'Этот процесс нельзя отменить. Вы уверены, что хотите продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              controller.clearDatabase(context);
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  void _showResetDatabaseConfirmationDialog(
    BuildContext context,
    DatabaseManagementController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавление примеров комнат'),
        content: const Text(
          'Эта операция очистит базу данных и добавит примеры комнат. '
          'Все текущие данные будут удалены. '
          'Этот процесс нельзя отменить. Вы уверены, что хотите продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              controller.resetDatabase(context);
            },
            child: const Text('Добавить примеры'),
          ),
        ],
      ),
    );
  }
}
