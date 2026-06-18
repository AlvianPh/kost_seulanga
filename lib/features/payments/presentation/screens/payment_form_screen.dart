import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/tenant_collection.dart';
import '../../../data/models/room_collection.dart';
import '../../../data/models/enums.dart';
import '../../tenants/providers/tenant_provider.dart';
import '../providers/payment_provider.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  final int? tenantId;
  const PaymentFormScreen({super.key, this.tenantId});

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  List<TenantCollection> _tenants = [];
  TenantCollection? _selectedTenant;
  RoomCollection? _selectedRoom;
  double? _amount;
  int _monthsPaid = 1;
  DateTime _paymentDate = DateTime.now();
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  String? _notes;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    final repo = ref.read(tenantRepositoryProvider);
    final all = await repo.getAllTenants();
    final active = all.where((t) => t.checkOutDate == null).toList();
    setState(() {
      _tenants = active;
      if (widget.tenantId != null) {
        _selectedTenant = _tenants.firstWhere((t) => t.id == widget.tenantId, orElse: () => active.isNotEmpty ? active.first : null);
        _selectedRoom = _selectedTenant?.currentRoom.value;
      }
    });
  }

  String _previewPaidUntil() {
    if (_selectedTenant == null) return '-';
    final basis = _selectedTenant!.cachedPaidUntil ?? _selectedTenant!.checkInDate;
    final paidUntil = DateTime(basis.year, basis.month + _monthsPaid, basis.day);
    return paidUntil.toHumanReadable();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedTenant == null) return;
    _formKey.currentState!.save();
    final room = _selectedTenant!.currentRoom.value;
    if (room == null) {
      // Should never happen because tenant must have a room
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tenant belum memiliki kamar.')));
      return;
    }
    final notifier = ref.read(paymentCrudProvider.notifier);
    try {
      await notifier.createPayment(
        tenant: _selectedTenant!,
        room: room,
        amount: _amount!,
        monthsPaid: _monthsPaid,
        paymentDate: _paymentDate,
        method: _selectedMethod,
        notes: _notes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran berhasil dicatat')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.statusColors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Pembayaran'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Tenant dropdown
              DropdownButtonFormField<TenantCollection>(
                decoration: const InputDecoration(labelText: 'Penghuni'),
                value: _selectedTenant,
                items: _tenants.map((t) {
                  final roomNum = t.currentRoom.value?.roomNumber ?? '-';
                  return DropdownMenuItem(
                    value: t,
                    child: Text('\${t.fullName} - Kamar \${roomNum}'),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedTenant = v;
                    _selectedRoom = v?.currentRoom.value;
                  });
                },
                validator: (v) => v == null ? 'Pilih penghuni' : null,
              ),
              const SizedBox(height: 12),
              // Read‑only room
              TextFormField(
                decoration: const InputDecoration(labelText: 'Kamar'),
                readOnly: true,
                controller: TextEditingController(text: _selectedRoom?.roomNumber ?? '-'),
              ),
              const SizedBox(height: 12),
              // Amount
              TextFormField(
                decoration: const InputDecoration(labelText: 'Jumlah'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null || val <= 0) return 'Masukkan jumlah valid';
                  return null;
                },
                onSaved: (v) => _amount = double.tryParse(v ?? ''),
              ),
              const SizedBox(height: 12),
              // Months paid
              TextFormField(
                decoration: const InputDecoration(labelText: 'Bulan Dibayar'),
                initialValue: '1',
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                validator: (v) {
                  final val = int.tryParse(v ?? '');
                  if (val == null || val < 1) return 'Minimal 1 bulan';
                  return null;
                },
                onChanged: (v) {
                  final val = int.tryParse(v);
                  setState(() {
                    _monthsPaid = val ?? 1;
                  });
                },
                onSaved: (v) => _monthsPaid = int.tryParse(v ?? '1') ?? 1,
              ),
              const SizedBox(height: 8),
              // Preview paid until
              Text('Lunas sampai: \${_previewPaidUntil()}'),
              const SizedBox(height: 12),
              // Payment date picker
              ListTile(
                title: const Text('Tanggal Pembayaran'),
                subtitle: Text(_paymentDate.toHumanReadable()),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _paymentDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _paymentDate = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              // Method dropdown
              DropdownButtonFormField<PaymentMethod>(
                decoration: const InputDecoration(labelText: 'Metode'),
                value: _selectedMethod,
                items: PaymentMethod.values.map((m) {
                  String label;
                  switch (m) {
                    case PaymentMethod.cash:
                      label = 'Cash';
                      break;
                    case PaymentMethod.transfer:
                      label = 'Transfer';
                      break;
                    case PaymentMethod.qris:
                      label = 'QRIS';
                      break;
                    default:
                      label = 'Lainnya';
                  }
                  return DropdownMenuItem(value: m, child: Text(label));
                }).toList(),
                onChanged: (v) => setState(() => _selectedMethod = v ?? PaymentMethod.cash),
              ),
              const SizedBox(height: 12),
              // Notes
              TextFormField(
                decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                maxLines: 3,
                onSaved: (v) => _notes = v,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
