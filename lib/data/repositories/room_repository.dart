import 'package:isar/isar.dart';
import '../models/enums.dart';
import '../models/room_collection.dart';
import '../../core/utils/exceptions.dart';

class RoomRepository {
  final Isar db;

  RoomRepository(this.db);

  Future<int> createRoom(RoomCollection room) async {
    room.createdAt = DateTime.now();
    room.updatedAt = DateTime.now();
    // Default to available when creating
    room.status = RoomStatus.available;

    return await db.writeTxn(() async {
      return await db.roomCollections.put(room);
    });
  }

  Future<int> updateRoom(RoomCollection room) async {
    room.updatedAt = DateTime.now();
    return await db.writeTxn(() async {
      return await db.roomCollections.put(room);
    });
  }

  Future<RoomCollection?> getRoomById(int id) async {
    return await db.roomCollections.get(id);
  }

  Future<List<RoomCollection>> getAllRooms() async {
    return await db.roomCollections.where().findAll();
  }

  Stream<List<RoomCollection>> watchRooms({String? query, RoomStatus? status}) {
    if ((query == null || query.isEmpty) && status == null) {
      return db.roomCollections.where().watch(fireImmediately: true);
    }

    QueryBuilder<RoomCollection, RoomCollection, QAfterFilterCondition>? queryBuilder;

    if (query != null && query.isNotEmpty) {
      queryBuilder = db.roomCollections.filter().roomNumberContains(query, caseSensitive: false);
    }

    if (status != null) {
      if (queryBuilder != null) {
        queryBuilder = queryBuilder.statusEqualTo(status);
      } else {
        queryBuilder = db.roomCollections.filter().statusEqualTo(status);
      }
    }

    return queryBuilder!.build().watch(fireImmediately: true);
  }

  Future<void> deactivateRoom(int id) async {
    final room = await getRoomById(id);
    if (room != null) {
      room.status = RoomStatus.inactive;
      room.updatedAt = DateTime.now();
      await db.writeTxn(() async {
        await db.roomCollections.put(room);
      });
    }
  }

  Future<bool> deleteRoom(int id) async {
    final room = await getRoomById(id);
    if (room == null) return false;

    // Load relations to check if we can delete
    await room.roomHistories.load();
    await room.payments.load();

    if (room.roomHistories.isNotEmpty || room.payments.isNotEmpty) {
      throw RelationConstraintException('Kamar tidak bisa dihapus karena sudah memiliki histori penghuni atau pembayaran. Gunakan "Deactivate" sebagai gantinya.');
    }

    return await db.writeTxn(() async {
      return await db.roomCollections.delete(id);
    });
  }

  // TODO: Implement actual occupancy check when Tenant module is ready
  Future<RoomStatus> deriveRoomStatus(int id) async {
    // Dummy implementation: returns available.
    // In the future: check if there's an active tenant.
    return RoomStatus.available;
  }
}
