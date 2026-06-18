import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// Removed unused app_theme import
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/room_collection.dart';
import '../../../../data/models/tenant_collection.dart';
import '../../../../data/repositories/tenant_repository.dart';
import '../../providers/tenant_provider.dart';
import '../../providers/room_provider.dart';

class TenantFormScreen extends ConsumerStatefulWidget {
  final int? tenantId; // null for add mode
  const TenantFormScreen({Key? key, this.tenantId}) : super(key: key);

  @override
  ConsumerState<TenantFormScreen> createState() => _TenantFormScreenState();
}

class _TenantFormScreenState extends ConsumerState<TenantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  RoomCollection? _selectedRoom;
  DateTime _checkInDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.tenantId != null) _loadTenant();
  }

  Future<void> _loadTenant() async {
    final repo = ref.read(tenantRepositoryProvider);
    final tenant = await repo.getTenantById(widget.tenantId!);
    if (tenant != null) {
      setState(() {
        _fullNameController.text = tenant.fullName;
        _phoneController.text = tenant.phoneNumber ?? '';
        _notesController.text = tenant.notes ?? '';
        _selectedRoom = tenant.currentRoom.value;
        _checkInDate = tenant.checkInDate;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final notifier = ref.read(tenantAsyncNotifierProvider.notifier);
    try {
      if (widget.tenantId == null) {
        // Add mode
        if (_selectedRoom == null) throw Exception('Pilih kamar terlebih dahulu');
        final newTenant = TenantCollection()
          ..fullName = _fullNameController.text.trim()
          ..phoneNumber = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim()
          ..notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
        await notifier.createTenant(
          tenant: newTenant,
          roomId: _selectedRoom!.id,
          checkInDate: _checkInDate,
        );
      } else {
        // Edit mode
        final repo = ref.read(tenantRepositoryProvider);
        final tenant = await repo.getTenantById(widget.tenantId!);
        if (tenant == null) throw Exception('Penghuni tidak ditemukan');
        await notifier.updateTenant(
          tenant: tenant,
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _checkInDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isAdd = widget.tenantId == null;
    final roomsAsync = ref.watch(roomsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdd ? 'Tambah Penghuni' : 'Ubah Penghuni'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Nomor HP'),
                    ),
                    const SizedBox(height: 12),
                    if (isAdd) ...[
                      // Room dropdown
                      roomsAsync.when(
                        data: (rooms) {
                          final availableRooms = rooms.where((r) => r.status == RoomStatus.available).toList();
                          return DropdownButtonFormField<RoomCollection>(
                            decoration: const InputDecoration(labelText: 'Kamar'),
                            items: availableRooms
                                .map((room) => DropdownMenuItem(value: room, child: Text('Kamar ${room.roomNumber}')))
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
                      // Check-in date picker
                      ListTile(
                        title: const Text('Tanggal Masuk'),
                        subtitle: Text(_checkInDate.toHumanReadable()),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _pickDate,
                      ),
                    ] else ...[
                      // Read‑only room & date
                      ListTile(
                        title: const Text('Kamar'),
                        subtitle: Text(_selectedRoom?.roomNumber ?? '-'),
                      ),
                      ListTile(
                        title: const Text('Tanggal Masuk'),
                        subtitle: Text(_checkInDate.toHumanReadable()),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Catatan'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _save,
                      child: Text(isAdd ? 'Simpan' : 'Update'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
