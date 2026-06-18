import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/payment_collection.dart';
import '../../payments/providers/payment_provider.dart';

class KeuanganScreen extends ConsumerStatefulWidget {
  const KeuanganScreen({super.key});

  @override
  ConsumerState<KeuanganScreen> createState() => _KeuanganScreenState();
}

class _KeuanganScreenState extends ConsumerState<KeuanganScreen> {
  int _selectedTab = 0; // 0: Pembayaran, 1: Pengeluaran
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  static const List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  List<int> _yearOptions() {
    final now = DateTime.now().year;
    return List.generate(3, (i) => now - 2 + i);
  }

  void _selectMonth(int month) {
    setState(() => _selectedMonth = month);
  }

  void _selectYear(int year) {
    setState(() => _selectedYear = year);
  }

  Future<void> _deletePayment(int paymentId) async {
    final notifier = ref.read(paymentCrudProvider.notifier);
    try {
      await notifier.deletePayment(paymentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran dihapus')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showPaymentDetails(PaymentCollection payment) {
    final tenantName = payment.tenant.value?.fullName ?? '-';
    final roomNumber = payment.room.value?.roomNumber ?? '-';
    final methodLabel = (() {
      switch (payment.paymentMethod) {
        case PaymentMethod.cash:
          return 'Cash';
        case PaymentMethod.transfer:
          return 'Transfer';
        case PaymentMethod.qris:
          return 'QRIS';
        default:
          return 'Lainnya';
      }
    })();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detail Pembayaran', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Penghuni: $tenantName'),
            Text('Kamar: $roomNumber'),
            Text('Jumlah: ${payment.amount.toRupiah()}'),
            Text('Bulan dibayar: ${payment.monthsPaid}'),
            Text('Tanggal: ${payment.paymentDate.toHumanReadable()}'),
            Text('Metode: $methodLabel'),
            if (payment.notes != null && payment.notes!.isNotEmpty) Text('Catatan: ${payment.notes}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Konfirmasi'),
                        content: const Text('Apakah yakin ingin menghapus pembayaran ini?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Batal')),
                          ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Hapus')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      Navigator.of(ctx).pop();
                      await _deletePayment(payment.id);
                    }
                  },
                  child: const Text('Hapus'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.statusColors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Pembayaran'), icon: Icon(Icons.payment_outlined)),
                  ButtonSegment(value: 1, label: Text('Pengeluaran'), icon: Icon(Icons.receipt_long_outlined)),
                ],
                selected: {_selectedTab},
                onSelectionChanged: (s) => setState(() => _selectedTab = s.first),
                showSelectedIcon: false,
              ),
              if (_selectedTab == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Month dropdown
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Bulan'),
                          value: _selectedMonth,
                          items: List.generate(12, (i) => i + 1)
                              .map((m) => DropdownMenuItem(value: m, child: Text(_monthNames[m - 1])))
                              .toList(),
                          onChanged: (v) => _selectMonth(v ?? _selectedMonth),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Year dropdown
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Tahun'),
                          value: _selectedYear,
                          items: _yearOptions()
                              .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                              .toList(),
                          onChanged: (v) => _selectYear(v ?? _selectedYear),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      body: _selectedTab == 0 ? _buildPaymentsList(context, colors) : _buildExpensePlaceholder(context, colors),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: () => context.go('/payments/add'),
              tooltip: 'Catat Pembayaran',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildExpensePlaceholder(BuildContext context, AppThemeColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: colors.active),
            const SizedBox(height: 24),
            Text('Pengeluaran', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Fitur ini akan segera hadir.'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsList(BuildContext context, AppThemeColors colors) {
    final asyncPayments = ref.watch(paymentsByMonthProvider(YearMonth(_selectedYear, _selectedMonth)));
    return asyncPayments.when(
      data: (payments) {
        if (payments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet, size: 64, color: colors.active),
                  const SizedBox(height: 24),
                  Text('Belum ada pembayaran bulan ini', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Tambahkan pembayaran baru untuk melacak arus kas.'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/payments/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Catat Pembayaran'),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: payments.length,
          itemBuilder: (c, i) {
            final p = payments[i];
            final tenantName = p.tenant.value?.fullName ?? '-';
            final roomNum = p.room.value?.roomNumber ?? '-';
            final methodLabel = (() {
              switch (p.paymentMethod) {
                case PaymentMethod.cash:
                  return 'Cash';
                case PaymentMethod.transfer:
                  return 'Transfer';
                case PaymentMethod.qris:
                  return 'QRIS';
                default:
                  return 'Lainnya';
              }
            })();
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showPaymentDetails(p),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(tenantName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                          Text(p.amount.toRupiah(), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Kamar $roomNum', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          const Spacer(),
                          Text(p.paymentDate.toHumanReadable(), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: colors.active.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(methodLabel, style: TextStyle(color: colors.active, fontWeight: FontWeight.bold, fontSize: 12)),
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
      error: (e, _) => Center(child: Text('Gagal memuat pembayaran: $e')),
    );
  }
}

// Helper class for month/year provider argument
class YearMonth {
  final int year;
  final int month;
  const YearMonth(this.year, this.month);
}
