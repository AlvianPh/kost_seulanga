import 'package:isar/isar.dart';
import 'expense_collection.dart';

part 'expense_category_collection.g.dart';

@collection
class ExpenseCategoryCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  late bool isActive;

  late DateTime createdAt;

  @Backlink(to: 'category')
  final expenses = IsarLinks<ExpenseCollection>();
}
