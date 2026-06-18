import 'package:isar/isar.dart';
import 'expense_category_collection.dart';

part 'expense_collection.g.dart';

@collection
class ExpenseCollection {
  Id id = Isar.autoIncrement;

  final category = IsarLink<ExpenseCategoryCollection>();

  @Index()
  late DateTime expenseDate;

  late double amount;

  String? description;

  late DateTime createdAt;
}
