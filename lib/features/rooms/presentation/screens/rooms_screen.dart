import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/enums.dart';
import '../../providers/room_provider.dart';
import '../../tenants/providers/tenant_provider.dart';
import '../../tenants/providers/tenant_provider.dart';
import 'room_form_sheet.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  int _selectedSegment = 0; // 0: Kamar, 1: Penghuni

  void _showAddRoomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const RoomFormSheet(),
    );
  }

  Widget _buildStatusBadge(BuildContext context, RoomStatus status) {
    final colors = context.statusColors;
    final Color badgeColor;
    final String statusText;

    switch (status) {
      case RoomStatus.available:
        badgeColor = colors.active;
        statusText = 'Tersedia';
        break;
      case RoomStatus.occupied:
        badgeColor = colors.active;
        statusText = 'Terisi';
        break;
      case RoomStatus.inactive:
        badgeColor = colors.inactive;
        statusText = 'Tidak Aktif';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildKamarView(BuildContext context) {
    final roomsAsync = ref.watch(roomsStreamProvider);

    return roomsAsync.when(
      data: (rooms) {
        if (rooms.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.meeting_room,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum Ada Kamar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambahkan kamar baru untuk mulai mengelola kost Anda.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddRoomSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Kamar'),
                  )
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            final theme = Theme.of(context);
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // TODO: Open Room Detail in later phases
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kamar ${room.roomNumber}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.layers_outlined,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Lantai ${room.floor}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '•',
                                  style: TextStyle(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  room.monthlyRentPrice.toRupiah(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  ' / bln',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(context, room.status),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Gagal memuat data kamar: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildPenghuniView(BuildContext context) {
    final tenantsAsync = ref.watch(tenantsStreamProvider);
    final colors = context.statusColors;
    return tenantsAsync.when(
      data: (tenants) {
        if (tenants.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum ada penghuni',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambahkan penghuni baru untuk mulai mengelola kost Anda.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/rooms/tenants/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Penghuni'),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: tenants.length,
          itemBuilder: (context, index) {
            final tenant = tenants[index];
            final roomNumber = tenant.currentRoom.value?.roomNumber ?? '-';
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.go('/rooms/tenants/${tenant.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tenant.fullName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('Kamar $roomNumber'),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.active.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Aktif', style: TextStyle(color: colors.active, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Gagal memuat data penghuni: $e')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kamar & Penghuni'),
        bottom: _selectedSegment == 0
            ? PreferredSize(
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
                        tooltip: 'Filter Status',
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
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                style: const SegmentedButtonThemeData().style,
                segments: const [
                  ButtonSegment<int>(
                    value: 0,
                    label: Text('Kamar'),
                    icon: Icon(Icons.meeting_room_outlined),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    label: Text('Penghuni'),
                    icon: Icon(Icons.people_outline),
                  ),
                ],
                selected: {_selectedSegment},
                onSelectionChanged: (value) {
                  setState(() {
                    _selectedSegment = value.first;
                  });
                },
                showSelectedIcon: false,
              ),
            ),
          ),
          Expanded(
            child: _selectedSegment == 0 ? _buildKamarView(context) : _buildPenghuniView(context),
          ),
        ],
      ),
      floatingActionButton: _selectedSegment == 0
          ? FloatingActionButton(
              onPressed: () => _showAddRoomSheet(context),
              tooltip: 'Tambah Kamar',
              child: const Icon(Icons.add),
            )
          : _selectedSegment == 1
              ? FloatingActionButton(
                  onPressed: () => context.go('/rooms/tenants/add'),
                  tooltip: 'Tambah Penghuni',
                  child: const Icon(Icons.add),
                )
              : null,
    );
  }
}
