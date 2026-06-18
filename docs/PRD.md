# PRODUCT REQUIREMENTS DOCUMENT (PRD)

## Project Information

| Key | Value |
|---|---|
| Project Name | Kost Manager |
| Version | MVP 1.1 (Revised) |
| Platform | Android Mobile Application |
| Framework | Flutter |
| Related Docs | `architecture.md`, `design.md`, `data-model.md` (to be derived from this PRD) |

### Purpose

Aplikasi untuk membantu pemilik kost mengelola kamar, penghuni, pembayaran sewa, pengeluaran operasional, dan laporan keuangan secara offline tanpa memerlukan server atau biaya langganan.

### Document Scope

Dokumen ini adalah **source of truth untuk requirement bisnis dan functional scope**. Keputusan teknis detail (struktur folder, pattern, dependency injection, schema migration strategy) didelegasikan ke `architecture.md`. Keputusan visual/UX detail (komponen, warna, spacing) didelegasikan ke `design.md`. PRD ini hanya mendefinisikan **apa** yang harus dilakukan sistem dan **aturan bisnis** di baliknya, bukan **bagaimana** mengimplementasikannya secara teknis.

---

# 1. Business Goals

Aplikasi harus mampu:

1. Mengelola data kamar kost.
2. Mengelola data penghuni, termasuk riwayat penghunian kamar (multi-kamar sepanjang waktu).
3. Mencatat pembayaran sewa.
4. Menghitung status lunas dan tunggakan penghuni.
5. Mencatat seluruh pengeluaran operasional kost.
6. Menampilkan laporan keuangan sederhana.
7. Berjalan sepenuhnya secara offline.

---

# 2. Target User

- Pemilik kost pribadi (single user, bukan admin/staff terpisah).
- Jumlah kamar sekitar 20–50 kamar.
- Tidak membutuhkan multi-user pada versi pertama.
- Asumsi: pengguna tidak terlalu teknis, jadi alur CRUD harus minim friction (sedikit tap, validasi jelas).

---

# 3. Technical Requirements (Constraints, not Architecture)

> Detail implementasi dari constraint ini akan diuraikan di `architecture.md`. Bagian ini hanya menetapkan **batasan non-negotiable**.

- Offline-first, tidak ada backend, tidak ada Firebase, tidak ada subscription service, tidak butuh server.
- Flutter (versi stable terbaru saat development dimulai).
- State Management: Riverpod.
- Local Database: Isar.
- Routing: Go Router.
- UI: Material 3.
- Reporting: PDF Export.

---

# 4. Functional Requirements

## 4.1 Module: Dashboard

### Purpose
Menampilkan ringkasan kondisi kost saat aplikasi dibuka.

### Dashboard Cards
- Jumlah Kamar
- Jumlah Kamar Terisi
- Jumlah Kamar Kosong
- Pemasukan Bulan Ini
- Pengeluaran Bulan Ini
- Laba Bersih Bulan Ini
- Jumlah Penghuni Menunggak

### Dashboard Statistics
- Persentase okupansi kamar
- Total pemasukan tahun berjalan
- Total pengeluaran tahun berjalan

### Notes
Semua angka dashboard dihitung dari data **aktif** (bukan soft-deleted/inactive), kecuali dinyatakan lain.

---

## 4.2 Module: Room Management

### Room Entity (Conceptual Fields)
- id
- roomNumber
- floor
- monthlyRentPrice
- status (`Available` / `Occupied` / `Inactive`)
- createdAt
- updatedAt

> Skema teknis lengkap (tipe data, index, relasi Isar Link) didefinisikan di `data-model.md`.

### Features
- View Room List
- Add Room
- Edit Room
- Deactivate Room (mengubah status jadi `Inactive`, room tidak hilang dari database)
- Delete Room (lihat **Business Rule: Deletion Policy**, Bagian 6.4)
- Search Room
- Filter By Status

### Business Rule
- Room dengan status `Inactive` tidak muncul sebagai opsi saat assign tenant baru.
- Room tidak bisa di-set `Available` secara manual jika masih ada tenant aktif terhubung (status `Occupied` adalah derived state, bukan diset manual oleh user — lihat Bagian 6.1).

---

## 4.3 Module: Tenant Management

### Tenant Entity (Conceptual Fields)
- id
- fullName
- phoneNumber
- currentRoomId (nullable — null jika tenant sudah checkout dan belum diassign ulang)
- checkInDate (tanggal masuk pada penempatan **saat ini**)
- checkOutDate (nullable — diisi saat tenant pindah kost/keluar permanen)
- notes
- createdAt
- updatedAt

### Tenant Room History Entity (New — Conceptual Fields)
- id
- tenantId
- roomId
- moveInDate
- moveOutDate (nullable — null berarti masih berlangsung)
- createdAt

> Setiap kali tenant pertama kali diassign ke kamar, atau dipindah kamar, atau checkout, sistem membuat/menutup satu record `TenantRoomHistory`. Ini menjawab kebutuhan riwayat penghunian per kamar dan per tenant secara penuh, terlepas dari riwayat pembayaran.

### Features
- View Tenant List
- Add Tenant (sekaligus assign ke Room → membuka record history baru)
- Edit Tenant (data pribadi saja; tidak mengubah roomId langsung — lihat Move Tenant)
- Delete Tenant (lihat **Business Rule: Deletion Policy**, Bagian 6.4)
- Assign Room (saat tenant baru/tidak punya kamar aktif)
- Move Tenant To Another Room (menutup history record lama dengan `moveOutDate`, membuka history record baru, **tidak mengubah/menghapus data payment lama**)
- Checkout Tenant (set `checkOutDate`, set `currentRoomId` ke null, menutup history record aktif, mengubah Room jadi `Available`)
- View Tenant Payment History
- View Tenant Room History (riwayat kamar yang pernah ditempati)
- Search Tenant

### Business Rule
- One room can only have one active tenant (validasi: cek tidak ada tenant lain dengan `currentRoomId` sama dan `checkOutDate` null).
- One tenant can only occupy one active room at a time.
- Move Tenant dan Checkout adalah operasi yang **mempengaruhi Tenant Room History**, bukan menghapus data tenant atau payment.

---

## 4.4 Module: Rental Payments

### Payment Entity (Conceptual Fields)
- id
- tenantId
- roomId *(baru — disimpan eksplisit di payment agar laporan pembayaran tetap akurat secara historis walau tenant sudah pindah kamar)*
- paymentDate
- monthsPaid
- amount
- paidUntil *(snapshot, dihitung saat payment dibuat — lihat Bagian 6.2)*
- paymentMethod (`Cash` / `Transfer` / `QRIS` / `Other`)
- notes
- createdAt

### Payment Methods
- Cash
- Transfer
- QRIS
- Other

### Features
- Record Payment
- Support Multi-Month Payment (contoh: 1 / 3 / 6 / 12 bulan)
- Automatically Calculate:
  - Paid Until Date (snapshot per record)
  - Remaining Arrears (derived, dihitung saat ditampilkan, bukan disimpan)
  - Current Payment Status (derived)
- Edit Payment (hanya field non-kritis: notes, paymentMethod — lihat Bagian 6.2 untuk batasan edit)
- Delete Payment (memicu recalculation `Tenant.paidUntil` — lihat Bagian 6.2)

### Payment Status (Derived, dihitung real-time, tidak disimpan di DB)
- Paid
- Overdue
- Upcoming Due

### Validation
- Tenant must have active room assignment (currentRoomId tidak null, checkOutDate null).
- Payment amount must be greater than zero.
- monthsPaid harus berupa bilangan bulat positif.

---

## 4.5 Module: Expense Categories

### Expense Category Entity (Conceptual Fields)
- id
- name
- isActive
- createdAt

### Features
- Add Category
- Edit Category
- Disable Category (soft toggle, bukan delete — kategori yang sudah dipakai expense tidak boleh dihapus permanen, lihat Bagian 6.4)
- View Category List

### Default Categories (Seed Data)
- Listrik Umum Lt 1
- Listrik Umum Lt 2
- Air
- Internet
- Galon
- Gas LPG
- Sampah
- Pewangi
- Cairan Pel
- Perbaikan
- Lainnya

---

## 4.6 Module: Expense Management

### Expense Entity (Conceptual Fields)
- id
- categoryId
- expenseDate
- amount
- description
- createdAt

### Features
- Add Expense
- Edit Expense
- Delete Expense (lihat **Business Rule: Deletion Policy**, Bagian 6.4)
- Filter By Date
- Filter By Category
- Search Expense

### Validation
- Amount must be greater than zero.
- Category is required dan harus berstatus aktif saat input baru (kategori nonaktif tetap valid untuk expense lama yang sudah tercatat).

---

## 4.7 Module: Reports

### 4.7.1 Financial Summary Report
Menampilkan: Total Income, Total Expense, Net Profit.
Filter: Monthly / Yearly / Custom Date Range.

### 4.7.2 Payment Report
Menampilkan: Tenant Name, Room Number (saat pembayaran dilakukan — dari field `roomId` di Payment, bukan room tenant saat ini), Payment Date, Amount, Paid Period.
Filter: Month / Year / Tenant.

### 4.7.3 Expense Report
Menampilkan: Expense Date, Category, Amount, Description.
Filter: Month / Year / Category.

### 4.7.4 Export
Semua report dapat di-export ke PDF.

---

# 5. User Interface Requirements

- Bottom Navigation: Dashboard, Rooms, Tenants, Payments, Expenses, Reports.
- Material 3 Design.
- Responsive Layout.
- Light Theme saja (No Dark Mode untuk MVP).

> Detail visual (warna, tipografi, komponen, spacing, state empty/error/loading) didefinisikan di `design.md`.

---

# 6. Business Rules (Consolidated)

## 6.1 Room Occupancy
- One room can only have one active tenant.
- One tenant can only occupy one room secara aktif pada satu waktu.
- Room.status `Occupied`/`Available` adalah **derived state** dari ada/tidaknya tenant aktif di kamar tersebut, bukan field yang diubah manual oleh user (kecuali `Inactive`, yang murni keputusan owner, misal kamar direnovasi).

## 6.2 Payment & Arrears Logic
- Payment dapat dilakukan untuk multiple bulan sekaligus.
- `paidUntil` dihitung otomatis saat payment dibuat, **disimpan sebagai snapshot** pada record payment tersebut (tidak direcalculate ulang saat field lain di payment itu diedit).
- Contoh: Monthly Rent = 700.000, Months Paid = 12 → Total = 8.400.000, Paid Until = 12 bulan setelah due date saat ini.
- `Tenant.paidUntil` (field cache di level Tenant untuk kebutuhan dashboard/list cepat) di-**recalculate ulang dari seluruh payment history milik tenant tersebut** hanya pada dua kondisi:
  1. Saat payment baru dibuat (paidUntil baru = max antara paidUntil lama dan hasil perhitungan payment baru).
  2. Saat payment dihapus (paidUntil di-recalculate dari sisa payment yang ada, untuk mencegah data tunggakan jadi salah).
- Edit payment **tidak** memicu recalculation kecuali field yang diedit adalah `amount` atau `monthsPaid` (dianggap setara dengan delete + create ulang secara logic).
- Tenant is considered overdue if: Current Date > Tenant.paidUntil.

## 6.3 Financial Logic
- Net Profit = Total Income − Total Expense.
- Dashboard harus selalu menampilkan kalkulasi terbaru (real-time query, tidak ada cache yang stale).

## 6.4 Deletion Policy (New — Consolidated)

| Entity | Delete Behavior |
|---|---|
| Room | Hard-delete **hanya jika** tidak punya relasi ke Tenant Room History maupun Payment. Jika punya relasi, delete ditolak — arahkan user ke "Deactivate" sebagai gantinya. |
| Tenant | Hard-delete **hanya jika** tidak punya relasi ke Payment maupun Tenant Room History. Jika punya relasi (riwayat apa pun), delete ditolak — arahkan user ke "Checkout" sebagai gantinya. |
| Expense Category | Tidak bisa di-hard-delete jika sudah dipakai oleh Expense manapun. Gunakan "Disable" sebagai gantinya. Kategori yang belum pernah dipakai boleh di-hard-delete. |
| Payment | Hard-delete diperbolehkan (lihat Bagian 6.2 untuk efek samping ke `Tenant.paidUntil`). Sebaiknya ada konfirmasi dialog karena ini mengubah status tunggakan. |
| Expense | Hard-delete diperbolehkan, tidak ada efek samping ke entity lain. |

> Prinsip umum: **data finansial historis (Payment, Expense) tidak boleh hilang diam-diam akibat delete di entity lain.** Validasi relasi harus dicek di repository layer sebelum delete dieksekusi.

## 6.5 Tenant Room History
- Setiap perpindahan kamar (assign awal, move, checkout) tercatat sebagai satu baris di Tenant Room History.
- History bersifat append-only dari sisi user — tidak ada fitur "Edit History" di MVP. Jika user salah input, perbaikan dilakukan dengan Move Tenant lagi atau (kasus jarang) lewat akses data langsung di luar UI MVP.

---

# 7. Non-Functional Requirements

- Application Startup < 3 Seconds.
- Works fully offline, no internet required.
- Data stored locally.
- Smooth performance for 1000+ records (termasuk dengan tambahan tabel Tenant Room History).

---

# 8. Out of Scope for MVP (Future Features)

- Google Drive Backup / Restore Backup
- Multi User
- Cloud Synchronization
- WhatsApp Reminder / Push Notification
- Inventory Management / Stock Tracking / Supplier Management
- Receipt Scanner / Photo Attachments
- Multi Property Support
- Web Dashboard
- Edit/Undo pada Tenant Room History

---

# 9. Deliverables

1. Flutter Project Structure (detail di `architecture.md`)
2. Isar Database Models, termasuk entity baru `TenantRoomHistory` dan field tambahan (`checkOutDate`, `roomId` di Payment) — detail skema di `data-model.md`
3. Riverpod Providers
4. Repository Layer (termasuk validasi Deletion Policy, Bagian 6.4)
5. Go Router Navigation
6. Material 3 UI Screens (detail di `design.md`)
7. CRUD Operations
8. Dashboard Statistics
9. Report Generation
10. PDF Export

Application must be production-ready, clean, modular, maintainable, and scalable.

---

# 10. Changelog

| Version | Perubahan |
|---|---|
| 1.0 | Draft awal |
| 1.1 | Menambahkan entity `TenantRoomHistory`; field `checkOutDate` (Tenant) dan `roomId` (Payment); konsolidasi Business Rules termasuk Deletion Policy (6.4) dan Payment recalculation policy (6.2); memperjelas derived vs stored state; menambahkan referensi ke dokumen turunan (architecture.md, design.md, data-model.md). |