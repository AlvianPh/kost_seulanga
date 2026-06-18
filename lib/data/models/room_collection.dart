import 'package:isar/isar.dart';
import 'enums.dart';
import 'tenant_collection.dart';
import 'tenant_room_history_collection.dart';
import 'payment_collection.dart';

part 'room_collection.g.dart';

@collection
class RoomCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String roomNumber;

  late int floor;

  late double monthlyRentPrice;

  @Enumerated(EnumType.name)
  late RoomStatus status;

  late DateTime createdAt;
  late DateTime updatedAt;

  @Backlink(to: 'currentRoom')
  final tenants = IsarLinks<TenantCollection>();

  @Backlink(to: 'room')
  final roomHistories = IsarLinks<TenantRoomHistoryCollection>();

  @Backlink(to: 'room')
  final payments = IsarLinks<PaymentCollection>();
}
