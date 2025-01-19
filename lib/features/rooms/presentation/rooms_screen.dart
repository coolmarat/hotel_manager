import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/strings.dart';
import '../../../database/models/room.dart';
import '../controllers/room_controller.dart';
import 'add_edit_room_dialog.dart';
import 'room_details_screen.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.rooms),
        actions: [
          PopupMenuButton<RoomStatus>(
            icon: const Icon(Icons.filter_list),
            onSelected: (RoomStatus status) {
              // TODO: Implement filter
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: null,
                  child: Text(Strings.allRooms),
                ),
                ...RoomStatus.values.map((status) {
                  return PopupMenuItem(
                    value: status,
                    child: Text(Strings.roomStatuses[status.name] ?? status.name),
                  );
                }),
              ];
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddEditRoomDialog(),
              );
            },
          ),
        ],
      ),
      body: roomsAsync.when(
        data: (rooms) {
          if (rooms.isEmpty) {
            return Center(
              child: Text(
                Strings.noRooms,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Dismissible(
                key: Key(room.uuid),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text(Strings.delete),
                      content: const Text(Strings.deleteRoomConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text(Strings.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(Strings.delete),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    await ref.read(roomsProvider.notifier).deleteRoom(room.uuid);
                  }
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16.0),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(room.status),
                    child: const Icon(Icons.hotel, color: Colors.white),
                  ),
                  title: Text(room.name),
                  subtitle: Text('${room.type} - ${room.capacity} ${Strings.guests}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(
                          Strings.roomStatuses[room.status.name] ?? room.status.name,
                        ),
                        backgroundColor: _getStatusColor(room.status).withOpacity(0.2),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AddEditRoomDialog(room: room),
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RoomDetailsScreen(room: room),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('${Strings.error}: $error'),
        ),
      ),
    );
  }

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return Colors.green;
      case RoomStatus.occupied:
        return Colors.red;
      case RoomStatus.cleaning:
        return Colors.orange;
      case RoomStatus.maintenance:
        return Colors.grey;
    }
  }
}
