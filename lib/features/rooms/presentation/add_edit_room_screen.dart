import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/models/room.dart';
import '../controllers/room_controller.dart';

class AddEditRoomScreen extends ConsumerStatefulWidget {
  final Room? room;

  const AddEditRoomScreen({super.key, this.room});

  @override
  ConsumerState<AddEditRoomScreen> createState() => _AddEditRoomScreenState();
}

class _AddEditRoomScreenState extends ConsumerState<AddEditRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _capacityController;
  late TextEditingController _basePriceController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.room?.name);
    _typeController = TextEditingController(text: widget.room?.type);
    _capacityController = TextEditingController(
      text: widget.room?.capacity.toString(),
    );
    _basePriceController = TextEditingController(
      text: widget.room?.basePrice.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.room?.description,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _capacityController.dispose();
    _basePriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (widget.room == null) {
        // Add new room
        await ref.read(roomsProvider.notifier).addRoom(
          name: _nameController.text,
          type: _typeController.text,
          capacity: int.parse(_capacityController.text),
          basePrice: double.parse(_basePriceController.text),
          description: _descriptionController.text.isEmpty 
            ? null 
            : _descriptionController.text,
        );
      } else {
        // Update existing room
        final updatedRoom = widget.room!.copyWith(
          name: _nameController.text,
          type: _typeController.text,
          capacity: int.parse(_capacityController.text),
          basePrice: double.parse(_basePriceController.text),
          description: _descriptionController.text.isEmpty 
            ? null 
            : _descriptionController.text,
        );
        await ref.read(roomsProvider.notifier).updateRoom(updatedRoom);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room == null ? 'Add Room' : 'Edit Room'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Room Name',
                hintText: 'Enter room name or number',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter room name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Room Type',
                hintText: 'e.g., Standard, Deluxe, Suite',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter room type';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _capacityController,
              decoration: const InputDecoration(
                labelText: 'Capacity',
                hintText: 'Enter maximum number of guests',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter capacity';
                }
                final capacity = int.tryParse(value);
                if (capacity == null || capacity <= 0) {
                  return 'Please enter a valid capacity';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _basePriceController,
              decoration: const InputDecoration(
                labelText: 'Base Price',
                hintText: 'Enter price per night',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter base price';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter room description',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveRoom,
        icon: const Icon(Icons.save),
        label: const Text('Save Room'),
      ),
    );
  }
}
