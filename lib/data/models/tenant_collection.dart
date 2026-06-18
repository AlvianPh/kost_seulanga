import 'package:isar/isar.dart';
import 'room_collection.dart';
import 'payment_collection.dart';
import 'tenant_room_history_collection.dart';

part 'tenant_collection.g.dart';

@collection
class TenantCollection {
  Id id = Isar.autoIncrement;

  @Index()
  late String fullName;

  String? phoneNumber;

  final currentRoom = IsarLink<RoomCollection>();

  late DateTime checkInDate;

  DateTime? checkOutDate;

  String? notes;

  // cachedPaidUntil adalah cache, bukan source of truth
  DateTime? cachedPaidUntil;

  late DateTime createdAt;
  late DateTime updatedAt;

  @Backlink(to: 'tenant')
  final payments = IsarLinks<PaymentCollection>();

  @Backlink(to: 'tenant')
  final roomHistories = IsarLinks<TenantRoomHistoryCollection>();
}
