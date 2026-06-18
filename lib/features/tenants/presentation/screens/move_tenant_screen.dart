import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Removed unused app_theme import
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/room_collection.dart';
import '../../../../data/models/tenant_collection.dart';

import '../../providers/tenant_provider.dart';
import '../../../../features/rooms/providers/room_provider.dart';

/// Screen to move a tenant to a different room.
class MoveTenantScreen extends ConsumerStatefulWidget {
  final int tenantId;
  const MoveTenantScreen({Key? key, required this.tenantId}) : super(key: key);

  @override
  ConsumerState<MoveTenantScreen> createState() => _MoveTenantScreenState();
}

class _MoveTenantScreenState extends ConsumerState<MoveTenantScreen> {
  TenantCollection? _tenant;
  RoomCollection? _selectedRoom;
  DateTime _moveInDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTenant();
  }

  Future<void> _loadTenant() async {
    final repo = ref.read(tenantRepositoryProvider);
    final tenant = await repo.getTenantById(widget.tenantId);
    if (tenant != null) {
      setState(() {
        _tenant = tenant;
        // current room is shown as read‑only; selection starts as null
      });
    } else {
      // tenant not found – show dialog and pop
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penghuni tidak ditemukan')),
        );
        context.pop();
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _moveInDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _moveInDate = picked);
    }
  }

  Future<void> _move() async {
    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kamar tujuan')),
      );
      return;
    }
    if (_tenant == null) return;
    setState(() => _isLoading = true);
    final notifier = ref.read(tenantAsyncNotifierProvider.notifier);
    try {
      await notifier.moveTenant(
        tenant: _tenant!,
        newRoomId: _selectedRoom!.id,
        moveInDate: _moveInDate,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penghuni berhasil dipindahkan')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsStreamProvider);
    final isLoading = _isLoading || _tenant == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Pindah Penghuni')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Current room (read‑only)
                  ListTile(
                    title: const Text('Kamar Saat Ini'),
                    subtitle: Text(_tenant?.currentRoom.value?.roomNumber ?? '-'),
                  ),
                  const SizedBox(height: 12),
                  // Destination room dropdown (available only)
                  roomsAsync.when(
                    data: (rooms) {
                      final available = rooms
                          .where((r) => r.status == RoomStatus.available)
                          .toList();
                      return DropdownButtonFormField<RoomCollection>(
                        decoration: const InputDecoration(labelText: 'Kamar Tujuan'),
                        items: available
                            .map((room) => DropdownMenuItem(
                                  value: room,
                                  child: Text('Kamar ${room.roomNumber}'),
                                ))
                            .toList(),
                        value: _selectedRoom,
                        onChanged: (v) => setState(() => _selectedRoom = v),
                        validator: (_) => _selectedRoom == null ? 'Pilih kamar' : null,
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Gagal muat kamar: $e'),
                  ),
                  const SizedBox(height: 12),
                  // Move‑in date picker
                  ListTile(
                    title: const Text('Tanggal Pindah'),
                    subtitle: Text(_moveInDate.toHumanReadable()),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _move,
                    child: const Text('Pindahkan'),
                  ),
                ],
              ),
            ),
    );
  }
}
