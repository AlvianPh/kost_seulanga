// lib/data/repositories/tenant_repository.dart

import 'package:isar/isar.dart';
import '../../models/tenant_collection.dart';
import '../../models/room_collection.dart';
import '../../models/tenant_room_history_collection.dart';
import '../../models/payment_collection.dart';
import '../../core/utils/exceptions.dart';
import '../../models/enums.dart';

class TenantRepository {
  final Isar db;
  TenantRepository(this.db);

  // ---------- Create ----------
  Future<int> createTenant({
    required TenantCollection tenant,
    required int roomId,
    required DateTime checkInDate,
  }) async {
    final room = await db.roomCollections.get(roomId);
    if (room == null) {
      throw Exception('Room not found');
    }
    if (await _isRoomOccupied(roomId)) {
      throw RelationConstraintException('Kamar sudah terisi oleh penghuni lain.');
    }
    tenant.currentRoom.value = room;
    tenant.checkInDate = checkInDate;
    tenant.createdAt = DateTime.now();
    tenant.updatedAt = DateTime.now();

    final history = TenantRoomHistoryCollection()
      ..tenant.value = tenant
      ..room.value = room
      ..moveInDate = checkInDate
      ..createdAt = DateTime.now();

    return await db.writeTxn(() async {
      await db.tenantCollections.put(tenant);
      await db.tenantRoomHistoryCollections.put(history);
      room.status = RoomStatus.occupied;
      room.updatedAt = DateTime.now();
      await db.roomCollections.put(room);
      return tenant.id;
    });
  }

  // ---------- Update ----------
  Future<void> updateTenant({
    required TenantCollection tenant,
    String? fullName,
    String? phoneNumber,
    String? notes,
  }) async {
    if (fullName != null) tenant.fullName = fullName;
    if (phoneNumber != null) tenant.phoneNumber = phoneNumber;
    if (notes != null) tenant.notes = notes;
    tenant.updatedAt = DateTime.now();
    await db.writeTxn(() async => await db.tenantCollections.put(tenant));
  }

  // ---------- Move ----------
  Future<void> moveTenant({
    required TenantCollection tenant,
    required int newRoomId,
    required DateTime moveInDate,
  }) async {
    final newRoom = await db.roomCollections.get(newRoomId);
    if (newRoom == null) {
      throw Exception('Destination room not found');
    }
    if (await _isRoomOccupied(newRoomId)) {
      throw RelationConstraintException('Kamar tujuan sudah terisi.');
    }

    // Close current history
    final currentHistory = await db.tenantRoomHistoryCollections
        .filter()
        .tenant((q) => q.idEqualTo(tenant.id))
        .moveOutDateIsNull()
        .findFirst();

    int? oldRoomId;
    if (currentHistory != null) {
      currentHistory.moveOutDate = DateTime.now();
      oldRoomId = currentHistory.room.id;
    }

    // New history
    final newHistory = TenantRoomHistoryCollection()
      ..tenant.value = tenant
      ..room.value = newRoom
      ..moveInDate = moveInDate
      ..createdAt = DateTime.now();

    tenant.currentRoom.value = newRoom;
    tenant.checkInDate = moveInDate;
    tenant.updatedAt = DateTime.now();

    await db.writeTxn(() async {
      if (currentHistory != null) {
        await db.tenantRoomHistoryCollections.put(currentHistory);
      }
      await db.tenantRoomHistoryCollections.put(newHistory);
      await db.tenantCollections.put(tenant);

      if (oldRoomId != null) {
        final oldRoom = await db.roomCollections.get(oldRoomId);
        if (oldRoom != null) {
          oldRoom.status = RoomStatus.available;
          oldRoom.updatedAt = DateTime.now();
          await db.roomCollections.put(oldRoom);
        }
      }

      newRoom.status = RoomStatus.occupied;
      newRoom.updatedAt = DateTime.now();
      await db.roomCollections.put(newRoom);
    });
  }

  // ---------- Checkout ----------
  Future<void> checkoutTenant({
    required TenantCollection tenant,
    required DateTime checkOutDate,
  }) async {
    final activeHistory = await db.tenantRoomHistoryCollections
        .filter()
        .tenant((q) => q.idEqualTo(tenant.id))
        .moveOutDateIsNull()
        .findFirst();
    if (activeHistory != null) {
      activeHistory.moveOutDate = checkOutDate;
    }

    final room = tenant.currentRoom.value;
    tenant.currentRoom.value = null;
    tenant.checkOutDate = checkOutDate;
    tenant.updatedAt = DateTime.now();

    await db.writeTxn(() async {
      if (activeHistory != null) {
        await db.tenantRoomHistoryCollections.put(activeHistory);
      }
      await db.tenantCollections.put(tenant);
      if (room != null) {
        room.status = RoomStatus.available;
        room.updatedAt = DateTime.now();
        await db.roomCollections.put(room);
      }
    });
  }

  // ---------- Delete ----------
  Future<bool> deleteTenant(int tenantId) async {
    final tenant = await db.tenantCollections.get(tenantId);
    if (tenant == null) return false;
    await tenant.payments.load();
    await tenant.roomHistories.load();
    if (tenant.payments.isNotEmpty || tenant.roomHistories.isNotEmpty) {
      throw RelationConstraintException(
          'Tenant memiliki riwayat atau pembayaran. Gunakan Checkout.');
    }
    return await db.writeTxn(() async => await db.tenantCollections.delete(tenantId));
  }

  // ---------- Reads ----------
  Future<List<TenantCollection>> getAllTenants() async =>
      await db.tenantCollections.where().findAll();

  Future<TenantCollection?> getTenantById(int id) async =>
      await db.tenantCollections.get(id);

  Stream<List<TenantCollection>> watchTenants({String? query}) {
    if (query == null || query.isEmpty) {
      return db.tenantCollections.where().watch(initialReturn: true);
    }
    return db.tenantCollections
        .filter()
        .fullNameContains(query, caseSensitive: false)
        .watch(initialReturn: true);
  }

  // ---------- History ----------
  Future<List<TenantRoomHistoryCollection>> getRoomHistoryForTenant(
      int tenantId) async {
    return await db.tenantRoomHistoryCollections
        .filter()
        .tenant((q) => q.idEqualTo(tenantId))
        .findAll();
  }

  Future<List<TenantRoomHistoryCollection>> getTenantHistoryForRoom(
      int roomId) async {
    return await db.tenantRoomHistoryCollections
        .filter()
        .room((q) => q.idEqualTo(roomId))
        .findAll();
  }

  // ---------- Helper ----------
  Future<bool> _isRoomOccupied(int roomId) async {
    final tenant = await db.tenantCollections
        .filter()
        .currentRoom((q) => q.idEqualTo(roomId))
        .checkOutDateIsNull()
        .findFirst();
    return tenant != null;
  }
}
