import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/isar_service.dart';
import '../../../data/models/payment_collection.dart';
import '../../../data/models/tenant_collection.dart';
import '../../../data/models/room_collection.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/payment_repository.dart';

// Repository provider
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final db = IsarService().db;
  return PaymentRepository(db);
});

// AsyncNotifier for create/delete payment
class PaymentCrudNotifier extends AsyncNotifier<void> {
  late final PaymentRepository _repo;

  @override
  FutureOr<void> build() {
    _repo = ref.read(paymentRepositoryProvider);
  }

  Future<void> createPayment({
    required TenantCollection tenant,
    required RoomCollection room,
    required double amount,
    required int monthsPaid,
    required DateTime paymentDate,
    required PaymentMethod method,
    String? notes,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.createPayment(
        tenant: tenant,
        room: room,
        amount: amount,
        monthsPaid: monthsPaid,
        paymentDate: paymentDate,
        method: method,
        notes: notes,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deletePayment(int paymentId) async {
    state = const AsyncLoading();
    try {
      await _repo.deletePayment(paymentId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

// Provider for the CRUD notifier
final paymentCrudProvider = AsyncNotifierProvider<PaymentCrudNotifier, void>(
  () => PaymentCrudNotifier(),
);

// Stream of payments for a given tenant
final paymentsForTenantProvider = StreamProvider.family<List<PaymentCollection>, int>((ref, tenantId) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.watchPaymentsForTenant(tenantId);
});

// Future provider for payments by month
final paymentsByMonthProvider = FutureProvider.family<List<PaymentCollection>, ({int year, int month})>((ref, args) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getPaymentsByMonth(args.year, args.month);
});
