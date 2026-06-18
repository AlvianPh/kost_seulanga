# ARCHITECTURE.md

## Project: Kost Manager — MVP 1.1

### Tujuan Dokumen
Mendefinisikan bagaimana PRD diimplementasikan secara teknis: struktur folder, pattern, layering, dan keputusan arsitektural. Tidak mengulang business rule yang sudah ada di PRD — hanya merujuk baliknya.

## 1. Architecture Pattern

Memakai Layered Architecture sederhana (bukan full Clean Architecture dengan use-case layer terpisah, karena scope MVP single-user dan tidak butuh abstraksi berlebihan):

Presentation (UI + Riverpod Notifiers)
↓
Repository (business logic + validasi)
↓
Data Source (Isar)

Alasan: repository sudah cukup untuk menampung business rule tanpa over-engineering. Jika nanti berkembang (multi-user/sync), baru dipisah lebih dalam.

## 2. Folder Structure

lib/
├── core/
│   ├── constants/
│   ├── extensions/
│   ├── theme/
│   ├── utils/
│   └── router/
├── data/
│   ├── models/
│   ├── repositories/
│   └── isar_service.dart
├── features/
│   ├── dashboard/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── providers/
│   ├── rooms/
│   │   ├── presentation/
│   │   └── providers/
│   ├── tenants/
│   │   ├── presentation/
│   │   └── providers/
│   ├── payments/
│   │   ├── presentation/
│   │   └── providers/
│   ├── expenses/
│   │   ├── presentation/
│   │   └── providers/
│   └── reports/
│       ├── presentation/
│       ├── providers/
│       └── pdf/
├── shared/
│   ├── widgets/
│   └── widgets/dialogs/
└── main.dart

## 3. Data Layer (Isar)

Collections:
RoomCollection
TenantCollection
TenantRoomHistoryCollection
PaymentCollection
ExpenseCategoryCollection
ExpenseCollection

Relasi:
Tenant ↔ Room
Payment ↔ Tenant
Expense ↔ ExpenseCategory

Index:
Room: roomNumber, status
Tenant: fullName, roomId
Payment: tenantId, paymentDate
Expense: expenseDate, categoryId

Migration:
Isar tidak punya migration formal, jadi field baru harus nullable atau punya default value.

## 4. State Management (Riverpod)

Provider types:
- Provider / FutureProvider untuk data read-only
- NotifierProvider / AsyncNotifierProvider untuk CRUD state
- StreamProvider untuk realtime Isar watch

Flow Payment:
PaymentFormNotifier → validate → repository → save Payment → update Tenant.paidUntil → update UI via StreamProvider

Provider diletakkan per feature.

## 5. Repository Layer

Repository menangani CRUD + business rules + validasi.

RoomRepository:
- validasi delete
- status occupied/available

TenantRepository:
- one room one tenant rule
- move/checkout logic

PaymentRepository:
- hitung paidUntil
- update tenant status

ExpenseRepository:
- validasi kategori aktif

Transaction wajib memakai isar.writeTxn() untuk operasi multi-collection.

## 6. Routing (Go Router)

/ dashboard
/ rooms
/ rooms/:id
/ rooms/add
/ rooms/:id/edit
/ tenants
/ tenants/:id
/ tenants/:id/move
/ tenants/:id/checkout
/ payments
/ payments/add
/ expenses
/ expenses/categories
/ reports

Gunakan StatefulShellRoute untuk bottom navigation.

## 7. PDF Export

Folder: features/reports/pdf/

Setiap report punya builder sendiri:
- FinancialSummaryPdfBuilder
- PaymentReportPdfBuilder
- ExpenseReportPdfBuilder

Tidak boleh ada business logic di PDF layer.

## 8. Error Handling

Repository melempar exception.
UI menangkap di Notifier.
Tidak boleh silent failure.
Semua error harus user readable.

## 9. Testing Strategy

Fokus unit test di repository.
UI test opsional.
Tidak perlu integration test untuk MVP.

## 10. Non-goals

Business rules → PRD.md
Field detail → data-model.md
UI design → design.md