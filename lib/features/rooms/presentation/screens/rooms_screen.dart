import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/enums.dart';
import '../../providers/room_provider.dart';
import 'room_form_sheet.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
      case RoomStatus.occupied:
        return Colors.green; // Paid/Available/Active -> Hijau
      case RoomStatus.inactive:
        return Colors.grey; // Inactive -> Abu-abu
    }
  }

  String _getStatusText(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return 'Tersedia';
      case RoomStatus.occupied:
        return 'Terisi';
      case RoomStatus.inactive:
        return 'Tidak Aktif';
    }
  }

  void _showAddRoomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const RoomFormSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kamar'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari kamar...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) => ref.read(roomSearchQueryProvider.notifier).state = value,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<RoomStatus?>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (status) => ref.read(roomStatusFilterProvider.notifier).state = status,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: null, child: Text('Semua')),
                    const PopupMenuItem(value: RoomStatus.available, child: Text('Tersedia')),
                    const PopupMenuItem(value: RoomStatus.occupied, child: Text('Terisi')),
                    const PopupMenuItem(value: RoomStatus.inactive, child: Text('Tidak Aktif')),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
      body: roomsAsync.when(
        data: (rooms) {
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.meeting_room, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Belum ada kamar'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddRoomSheet(context),
                    child: const Text('Tambah Kamar'),
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text('Kamar ${room.roomNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Lantai ${room.floor} • Rp ${room.monthlyRentPrice.toInt()}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(room.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(room.status)),
                    ),
                    child: Text(
                      _getStatusText(room.status),
                      style: TextStyle(color: _getStatusColor(room.status), fontSize: 12),
                    ),
                  ),
                  onTap: () {
                    // TODO: Open Room Detail
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRoomSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
