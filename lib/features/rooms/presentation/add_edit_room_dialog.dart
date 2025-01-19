import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/strings.dart';
import '../../../database/models/room.dart';
import '../controllers/room_controller.dart';

class AddEditRoomDialog extends ConsumerStatefulWidget {
  final Room? room;

  const AddEditRoomDialog({super.key, this.room});

  @override
  ConsumerState<AddEditRoomDialog> createState() => _AddEditRoomDialogState();
}

class _AddEditRoomDialogState extends ConsumerState<AddEditRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _typeController;
  late final TextEditingController _capacityController;
  late final TextEditingController _basePriceController;
  late final TextEditingController _descriptionController;

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.room == null ? Strings.addRoom : Strings.editRoom),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: Strings.roomName,
                  hintText: Strings.roomNameHint,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return Strings.required;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _typeController,
                decoration: InputDecoration(
                  labelText: Strings.roomType,
                  hintText: Strings.roomTypeHint,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return Strings.required;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _capacityController,
                decoration: InputDecoration(
                  labelText: Strings.capacity,
                  hintText: Strings.capacityHint,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return Strings.required;
                  }
                  final capacity = int.tryParse(value);
                  if (capacity == null || capacity <= 0) {
                    return Strings.invalidCapacity;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _basePriceController,
                decoration: InputDecoration(
                  labelText: Strings.basePrice,
                  hintText: Strings.basePriceHint,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return Strings.required;
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return Strings.invalidPrice;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: Strings.description,
                  hintText: Strings.descriptionHint,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(Strings.cancel),
        ),
        TextButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final controller = ref.read(roomsProvider.notifier);
              
              if (widget.room == null) {
                await controller.addRoom(
                  name: _nameController.text,
                  type: _typeController.text,
                  capacity: int.parse(_capacityController.text),
                  basePrice: double.parse(_basePriceController.text),
                  description: _descriptionController.text,
                );
              } else {
                final updatedRoom = widget.room!.copyWith(
                  name: _nameController.text,
                  type: _typeController.text,
                  capacity: int.parse(_capacityController.text),
                  basePrice: double.parse(_basePriceController.text),
                  description: _descriptionController.text,
                );
                await controller.updateRoom(updatedRoom);
              }
              
              if (mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          child: const Text(Strings.save),
        ),
      ],
    );
  }
}
