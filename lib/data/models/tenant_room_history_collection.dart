import 'package:isar/isar.dart';
import 'tenant_collection.dart';
import 'room_collection.dart';

part 'tenant_room_history_collection.g.dart';

@collection
class TenantRoomHistoryCollection {
  Id id = Isar.autoIncrement;

  final tenant = IsarLink<TenantCollection>();
  final room = IsarLink<RoomCollection>();

  @Index()
  late DateTime moveInDate;

  DateTime? moveOutDate;

  late DateTime createdAt;
}
