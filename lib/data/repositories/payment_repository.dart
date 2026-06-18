// lib/data/repositories/payment_repository.dart

import 'package:isar/isar.dart';
import '../../models/payment_collection.dart';
import '../../models/tenant_collection.dart';
import '../../models/room_collection.dart';
import '../../core/utils/exceptions.dart';
import '../../models/enums.dart';

class PaymentRepository {
  final Isar db;
  PaymentRepository(this.db);

  // ---------- Create ----------
  Future<int> createPayment({
    required TenantCollection tenant,
    required RoomCollection room,
    required double amount,
    required int monthsPaid,
    required DateTime paymentDate,
    required PaymentMethod method,
    String? notes,
  }) async {
    // Calculate paidUntil snapshot
    final paidUntil = DateTime(
      paymentDate.year,
      paymentDate.month + monthsPaid,
      paymentDate.day,
    );

    final payment = PaymentCollection()
      ..tenant.value = tenant
      ..room.value = room
      ..amount = amount
      ..monthsPaid = monthsPaid
      ..paymentDate = paymentDate
      ..paymentMethod = method
      ..notes = notes
      ..paidUntil = paidUntil
      ..createdAt = DateTime.now();

    // Update tenant cachedPaidUntil (snapshot) inside transaction
    return await db.writeTxn(() async {
      await db.paymentCollections.put(payment);
      // Update tenant's cachedPaidUntil only if this payment extends it
      if (tenant.cachedPaidUntil == null || tenant.cachedPaidUntil!.isBefore(paidUntil)) {
        tenant.cachedPaidUntil = paidUntil;
        await db.tenantCollections.put(tenant);
      }
      return payment.id;
    });
  }

  // ---------- Delete ----------
  Future<void> deletePayment(int paymentId) async {
    final payment = await db.paymentCollections.get(paymentId);
    if (payment == null) return;
    final tenant = await payment.tenant.load();
    // Deleting payment may affect tenant.cachedPaidUntil; recalc from remaining payments
    return await db.writeTxn(() async {
      await db.paymentCollections.delete(paymentId);
      if (tenant != null) {
        await tenant.payments.load();
        DateTime? maxPaidUntil;
        for (final p in tenant.payments) {
          if (maxPaidUntil == null || p.paidUntil.isAfter(maxPaidUntil)) {
            maxPaidUntil = p.paidUntil;
          }
        }
        tenant.cachedPaidUntil = maxPaidUntil;
        await db.tenantCollections.put(tenant);
      }
    });
  }

  // ---------- Edit (notes & method) ----------
  Future<void> editPayment({
    required int paymentId,
    PaymentMethod? method,
    String? notes,
  }) async {
    final payment = await db.paymentCollections.get(paymentId);
    if (payment == null) throw Exception('Payment not found');
    if (method != null) payment.paymentMethod = method;
    if (notes != null) payment.notes = notes;
    await db.writeTxn(() async => await db.paymentCollections.put(payment));
  }

  // ---------- Reads ----------
  Future<List<PaymentCollection>> getPaymentsForTenant(int tenantId) async {
    return await db.paymentCollections
        .filter()
        .tenant((q) => q.idEqualTo(tenantId))
        .findAll();
  }

  Future<List<PaymentCollection>> getPaymentsByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1).subtract(const Duration(seconds: 1));
    return await db.paymentCollections
        .filter()
        .paymentDateBetween(start, end)
        .findAll();
  }

  Stream<List<PaymentCollection>> watchPaymentsForTenant(int tenantId) {
    return db.paymentCollections
        .filter()
        .tenant((q) => q.idEqualTo(tenantId))
        .watch(initialReturn: true);
  }

  // ---------- Derived State ----------
  PaymentStatus derivePaymentStatus(PaymentCollection payment) {
    final now = DateTime.now();
    if (payment.paidUntil.isBefore(now)) {
      return PaymentStatus.overdue;
    }
    final diff = payment.paidUntil.difference(now).inDays;
    if (diff <= 7) {
      return PaymentStatus.upcomingDue;
    }
    return PaymentStatus.paid;
  }
}
