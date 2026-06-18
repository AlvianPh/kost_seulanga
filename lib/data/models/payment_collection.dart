import 'package:isar/isar.dart';
import 'enums.dart';
import 'tenant_collection.dart';
import 'room_collection.dart';

part 'payment_collection.g.dart';

@collection
class PaymentCollection {
  Id id = Isar.autoIncrement;

  final tenant = IsarLink<TenantCollection>();
  final room = IsarLink<RoomCollection>();

  @Index()
  late DateTime paymentDate;

  late int monthsPaid;

  late double amount;

  // paidUntil is a snapshot:
  // Dihitung sekali saat payment dibuat. Disimpan sebagai field.
  late DateTime paidUntil;

  @Enumerated(EnumType.name)
  late PaymentMethod paymentMethod;

  String? notes;

  late DateTime createdAt;
}
