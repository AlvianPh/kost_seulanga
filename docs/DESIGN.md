# DESIGN.md

## Project: Kost Manager — MVP 1.1

### Tujuan Dokumen
Mendefinisikan keputusan visual/UX: komponen, layout, state (empty/error/loading), dan UX copy. Merujuk balik ke PRD.md (Bagian 5 & 6) dan architecture.md (Bagian 6, routing) tanpa mengulang business rule atau struktur teknis.

## 1. Design Principles

Karena target user adalah pemilik kost yang tidak terlalu teknis (PRD Bagian 2), prinsip desainnya:

- Sedikit tap, langsung jelas — form pendek, default value masuk akal, hindari nested dialog berlapis.
- Status selalu terlihat tanpa harus klik — warna jadi sinyal utama (lunas vs nunggak vs hampir jatuh tempo), bukan teks kecil yang harus dibaca.
- Konsekuensi aksi destruktif harus jelas sebelum terjadi — setiap penolakan delete harus muncul sebagai pesan yang dimengerti, bukan jargon teknis.

## 2. Visual Foundation

### 2.1 Theme
- Material 3, Light theme only (PRD 5).
- Seed color: hijau-teal (#0F766E sebagai contoh).
- ColorScheme.fromSeed() untuk konsistensi warna otomatis.

### 2.2 Status Color Mapping

| Status | Warna | Dipakai di |
|---|---|---|
| Paid / Available / Active | Hijau | Tenant list, Room list, Payment |
| Upcoming Due | Amber | Dashboard, Tenant list |
| Overdue | Merah | Dashboard, Tenant list |
| Inactive | Abu-abu | Room list |

### 2.3 Typography
- Material 3 default type scale
- Angka uang lebih tebal (FontWeight.w600)

### 2.4 Currency & Date Format
- Rp 700.000 (ID format, tanpa desimal)
- 17 Jun 2026 (format human readable)

## 3. Navigation Shell

Bottom Navigation 5–6 item dari PRD.
Jika terlalu penuh, Expenses bisa diakses dari Reports atau Dashboard quick action.

## 4. Screen: Dashboard

### Layout
- App bar tanpa back button
- Quick action chips (+ Payment, + Expense)
- Summary cards grid:
  - Jumlah kamar
  - Pemasukan bulan ini
  - Pengeluaran bulan ini
  - Laba bersih
- Card: Penghuni menunggak (highlight)
- Statistik tahunan (collapsible)

### Empty State
- Jika belum ada kamar: hanya CTA “Tambah Kamar”

### Loading
- Skeleton per card (bukan global spinner)

## 5. Screen: Kamar & Penghuni

### Layout
- Segmented control: Kamar | Penghuni
- Search bar contextual
- Filter chips per tab
- List card item

### Room Card
- Nomor kamar
- Lantai
- Harga
- Status badge

### Room Detail
- Info kamar
- Current tenant
- History tenant
- Action: edit / deactivate / delete (conditional)

### Tenant Card
- Nama + kamar
- Status payment badge
- Tap → detail

### Tenant Detail
- Status pembayaran besar
- CTA:
  - Catat pembayaran
  - Pindah kamar
  - Checkout
- Tab: Payment history | Room history

## 6. Screen: Keuangan

### Layout
- Segmented: Payment | Expense
- FAB context-aware
- Filter bulan/tahun
- List transaksi

### Payment Item
- Tenant + kamar
- Months paid
- Amount

### Expense Item
- Category + description
- Amount

## 7. Screen: Laporan

- 3 kartu utama:
  - Ringkasan
  - Payment report
  - Expense report
- Filter: monthly/yearly/custom
- Preview tabel sebelum export PDF
- Sticky export button

## 8. Forms & Input Patterns

### Bottom Sheet Form
- Room, Expense, Category

### Full Screen Form
- Tenant
- Payment (karena ada preview kalkulasi)

### Payment Preview
- Total amount
- Paid until preview

### Move Tenant Flow
- Pilih room available
- Konfirmasi
- Ringkasan perubahan history

### Checkout Flow
- Dialog konfirmasi sederhana

## 9. States

### Empty State
- Selalu ada CTA

### Error State
- Human readable message, bukan error teknis

### Delete Blocked
- Jelaskan kenapa tidak bisa dihapus
- Beri alternatif (Deactivate)

## 10. Accessibility & Polish

- Semua status tidak hanya warna (selalu ada teks)
- Minimum touch target 48dp
- Input currency auto-format
- Konsisten spacing Material 3

## 11. Non-goals

- Business rules → PRD.md
- Data structure → data-model.md
- Technical routing → architecture.md