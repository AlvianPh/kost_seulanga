import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/room_collection.dart';
import 'models/tenant_collection.dart';
import 'models/tenant_room_history_collection.dart';
import 'models/payment_collection.dart';
import 'models/expense_category_collection.dart';
import 'models/expense_collection.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;
  IsarService._internal();

  late Isar db;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    db = await Isar.open(
      [
        RoomCollectionSchema,
        TenantCollectionSchema,
        TenantRoomHistoryCollectionSchema,
        PaymentCollectionSchema,
        ExpenseCategoryCollectionSchema,
        ExpenseCollectionSchema,
      ],
      directory: dir.path,
    );
  }
}
