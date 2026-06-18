# DATA-MODEL.md

## Project: Kost Manager — MVP 1.1

### Tujuan Dokumen
Mendefinisikan skema Isar secara konkret: tipe data, anotasi (@collection, @Index, Id), relasi (IsarLink/IsarLinks), dan enum. Ini turunan teknis dari PRD Bagian 4 & 6, dan mengikuti folder structure di architecture.md Bagian 3 (lib/data/models/).

## 1. Enums

enum RoomStatus { available, occupied, inactive }

enum PaymentMethod { cash, transfer, qris, other }

// Derived saat runtime, TIDAK disimpan sebagai field — dihitung dari paidUntil vs DateTime.now()
// Lihat PRD 6.2
enum PaymentStatus { paid, overdue, upcomingDue }

PaymentStatus tidak disimpan di database, hanya derived value di repository/provider.

## 2. Room Collection

import 'package:isar/isar.dart';

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

Catatan:
status disimpan karena dipakai untuk filter cepat
roomNumber harus unique

## 3. Tenant Collection

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

  DateTime? cachedPaidUntil;

  late DateTime createdAt;
  late DateTime updatedAt;

  @Backlink(to: 'tenant')
  final payments = IsarLinks<PaymentCollection>();

  @Backlink(to: 'tenant')
  final roomHistories = IsarLinks<TenantRoomHistoryCollection>();
}

Catatan:
cachedPaidUntil adalah cache, bukan source of truth

## 4. TenantRoomHistory Collection

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

## 5. Payment Collection

@collection
class PaymentCollection {
  Id id = Isar.autoIncrement;

  final tenant = IsarLink<TenantCollection>();
  final room = IsarLink<RoomCollection>();

  @Index()
  late DateTime paymentDate;

  late int monthsPaid;

  late double amount;

  late DateTime paidUntil;

  @Enumerated(EnumType.name)
  late PaymentMethod paymentMethod;

  String? notes;

  late DateTime createdAt;
}

## 6. ExpenseCategory Collection

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

## 7. Expense Collection

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

## 8. Seed Data

final defaultCategories = [
  'Listrik',
  'Air',
  'Internet',
  'Gas',
  'Sampah',
  'Kebersihan',
  'Perbaikan',
  'Lainnya',
];

## 9. Derived Values

Room.status dihitung dari tenant aktif
PaymentStatus dihitung dari paidUntil vs sekarang
Remaining arrears dihitung dari cachedPaidUntil vs sekarang
Income dan expense bulanan hasil agregasi

## 10. Relasi

Room ← Tenant
Tenant → Payment
Tenant → TenantRoomHistory
Payment → Room
ExpenseCategory → Expense

## 11. Non-goals

Business rules ada di PRD
Logic ada di architecture
UI ada di design