import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/room_collection.dart';
import '../../providers/room_provider.dart';

class RoomFormSheet extends ConsumerStatefulWidget {
  final RoomCollection? room;
  const RoomFormSheet({super.key, this.room});

  @override
  ConsumerState<RoomFormSheet> createState() => _RoomFormSheetState();
}

class _RoomFormSheetState extends ConsumerState<RoomFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _roomNumberCtrl;
  late TextEditingController _floorCtrl;
  late TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _roomNumberCtrl = TextEditingController(text: widget.room?.roomNumber ?? '');
    _floorCtrl = TextEditingController(text: widget.room?.floor.toString() ?? '');
    _priceCtrl = TextEditingController(text: widget.room?.monthlyRentPrice.toInt().toString() ?? '');
  }

  @override
  void dispose() {
    _roomNumberCtrl.dispose();
    _floorCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final repo = ref.read(roomRepositoryProvider);
      try {
        if (widget.room == null) {
          final newRoom = RoomCollection()
            ..roomNumber = _roomNumberCtrl.text
            ..floor = int.parse(_floorCtrl.text)
            ..monthlyRentPrice = double.parse(_priceCtrl.text);
          await repo.createRoom(newRoom);
        } else {
          final updatedRoom = widget.room!
            ..roomNumber = _roomNumberCtrl.text
            ..floor = int.parse(_floorCtrl.text)
            ..monthlyRentPrice = double.parse(_priceCtrl.text);
          await repo.updateRoom(updatedRoom);
        }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset, left: 16, right: 16, top: 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.room == null ? 'Tambah Kamar' : 'Edit Kamar', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roomNumberCtrl,
              decoration: const InputDecoration(labelText: 'Nomor Kamar', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _floorCtrl,
              decoration: const InputDecoration(labelText: 'Lantai', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: 'Harga Sewa (Rp)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Simpan'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
