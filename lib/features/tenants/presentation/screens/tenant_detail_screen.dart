import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/tenant_collection.dart';
import '../../../../data/models/tenant_room_history_collection.dart';
import '../../providers/tenant_provider.dart';

class TenantDetailScreen extends ConsumerStatefulWidget {
  final int tenantId;
  const TenantDetailScreen({Key? key, required this.tenantId}) : super(key: key);

  @override
  ConsumerState<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends ConsumerState<TenantDetailScreen> {
  TenantCollection? _tenant;
  List<TenantRoomHistoryCollection> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final repo = ref.read(tenantRepositoryProvider);
    final tenant = await repo.getTenantById(widget.tenantId);
    if (tenant != null) {
      await tenant.roomHistories.load();
      final histories = await repo.getRoomHistoryForTenant(widget.tenantId);
      setState(() {
        _tenant = tenant;
        _history = histories;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  void _showCheckoutDialog() async {
    DateTime selectedDate = DateTime.now();
    final result = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pilih tanggal checkout untuk ${_tenant?.fullName ?? ''}'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  selectedDate = picked;
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(selectedDate.toHumanReadable()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(selectedDate),
            child: const Text('Checkout'),
          ),
        ],
      ),
    );
    if (result != null && _tenant != null) {
      final notifier = ref.read(tenantAsyncNotifierProvider.notifier);
      await notifier.checkoutTenant(tenant: _tenant!, checkOutDate: result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checkout berhasil')));
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _deleteTenant() async {
    final notifier = ref.read(tenantAsyncNotifierProvider.notifier);
    try {
      await notifier.deleteTenant(_tenant!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penghuni dihapus')));
        Navigator.of(context).pop();
      }
    } on RelationConstraintException catch (_) {
      // Show human‑friendly dialog directing to checkout
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tidak dapat menghapus'),
          content: const Text('Penghuni memiliki histori atau pembayaran. Lakukan checkout terlebih dahulu.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_tenant == null) {
      return Scaffold(appBar: AppBar(title: const Text('Detail Penghuni')), body: const Center(child: Text('Penghuni tidak ditemukan')));
    }
    final roomNumber = _tenant!.currentRoom.value?.roomNumber ?? '-';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Penghuni'),
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteTenant),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(title: const Text('Nama'), subtitle: Text(_tenant!.fullName)),
            ListTile(title: const Text('Nomor HP'), subtitle: Text(_tenant!.phoneNumber ?? '-')),
            ListTile(title: const Text('Kamar Aktif'), subtitle: Text(roomNumber)),
            ListTile(title: const Text('Tanggal Masuk'), subtitle: Text(_tenant!.checkInDate.toHumanReadable())),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.go('/rooms/tenants/${_tenant!.id}/edit'),
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => context.go('/rooms/tenants/${_tenant!.id}/move'),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Pindah Kamar'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showCheckoutDialog,
              icon: const Icon(Icons.logout),
              label: const Text('Checkout'),
            ),
            const SizedBox(height: 8),
            // Disabled payment button with TODO comment
            ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.attach_money),
              label: const Text('Catat Pembayaran'),
            ),
            const SizedBox(height: 24),
            Text('Riwayat Kamar', style: theme.textTheme.titleMedium),
            const Divider(),
            ..._history.map((h) {
              final moveOut = h.moveOutDate?.toHumanReadable() ?? 'Sekarang';
              final moveIn = h.moveInDate.toHumanReadable();
              final roomNum = h.room.value?.roomNumber ?? '-';
              return ListTile(
                title: Text('Kamar $roomNum'),
                subtitle: Text('Masuk: $moveIn  -  Keluar: $moveOut'),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
