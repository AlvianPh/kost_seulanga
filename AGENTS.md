# AGENTS.md

> File ini dibaca otomatis oleh AI agent (Antigravity dan tool kompatibel lain) di setiap sesi kerja pada project ini. Tujuannya: pointer cepat + guardrail untuk hal-hal yang paling rawan dilanggar saat coding berjalan panjang. Detail lengkap selalu ada di `docs/`.

## 1. Project Context

Kost Manager — aplikasi Flutter offline-first untuk manajemen kost (kamar, penghuni, pembayaran, pengeluaran, laporan). Single-user, tidak ada backend/server/Firebase.

Dokumen wajib dibaca sebelum mengerjakan task apa pun:

- `docs/PRD.md`
- `docs/architecture.md`
- `docs/data-model.md`
- `docs/design.md`

Jangan menebak keputusan yang sudah ada di dokumen ini. Kalau ragu field/rule tertentu, baca dokumen relevan dulu sebelum menulis kode.

---

## 2. Non-Negotiable Rules (Guardrail Kritis)

### 2.1 Payment.paidUntil adalah SNAPSHOT

- Dihitung sekali saat payment dibuat.
- Disimpan sebagai field.
- Tidak pernah direcalculate otomatis saat field lain diedit.
- Jika `amount` atau `monthsPaid` berubah, perlakukan sebagai delete + create.
- `Tenant.cachedPaidUntil` hanya direcalculate saat payment dibuat atau payment dihapus.
- Referensi: `docs/PRD.md` Bagian 6.2.

### 2.2 Deletion Policy — Cek Relasi SEBELUM Hard Delete

Room:
- Hard delete hanya jika tidak punya relasi TenantRoomHistory maupun Payment.
- Jika ada relasi → tolak → arahkan ke Deactivate.

Tenant:
- Hard delete hanya jika tidak punya relasi Payment maupun TenantRoomHistory.
- Jika ada relasi → tolak → arahkan ke Checkout.

ExpenseCategory:
- Tidak bisa hard delete jika pernah dipakai Expense.
- Gunakan Disable.

Payment dan Expense:
- Boleh hard delete.

Semua validasi wajib ada di Repository Layer.

Referensi:
`docs/PRD.md` Bagian 6.4.

### 2.3 Derived State — Jangan Dijadikan Editable Field

Derived value:

- `Room.status`
- `PaymentStatus`

Tidak boleh menjadi input user.

Referensi:
`docs/data-model.md` Bagian 9.

### 2.4 TenantRoomHistory Bersifat Append Only

- Tidak ada edit history.
- Tidak ada delete history.
- Move Tenant dan Checkout hanya menutup history lama lalu membuat history baru.

Referensi:
`docs/PRD.md` Bagian 6.5.

### 2.5 Multi Collection Operation Harus Atomic

Semua operasi yang menyentuh lebih dari satu collection harus menggunakan:

`isar.writeTxn()`

Contoh:

- Create Payment
- Update cachedPaidUntil
- Update Room Status

Referensi:
`docs/architecture.md` Bagian 5.

---

## 3. Struktur dan Pattern

- Layered Architecture
- Presentation → Repository → Data Source
- Jangan tambahkan UseCase Layer
- Jangan ubah ke Clean Architecture penuh

Folder:
- Feature First

Business Logic:
- Repository

State Management:
- Riverpod

Database:
- Isar

Relasi:
- IsarLink
- IsarLinks

Cache field harus diawali prefix:

`cached*`

Contoh:

`cachedPaidUntil`

Referensi:

- `docs/architecture.md`
- `docs/data-model.md`

---

## 4. UI dan UX

Bottom Navigation hanya:

1. Dashboard
2. Kamar & Penghuni
3. Keuangan
4. Laporan

Jangan membuat tab terpisah:

- Rooms
- Tenants
- Payments
- Expenses

Delete yang gagal harus menampilkan dialog bahasa manusia.

Jangan tampilkan exception mentah.

Semua empty state harus memiliki:

- icon atau ilustrasi
- deskripsi
- CTA

Referensi:
`docs/design.md`

---

## 5. Saat Mengerjakan Task

1. Baca dokumen terkait terlebih dahulu.
2. Jangan mengasumsikan business rule yang belum ada.
3. Jika perlu keputusan baru:
   - tanyakan ke user
   - sarankan update docs
4. Sebelum selesai:
   - cek ulang seluruh Non Negotiable Rules.

---

## 6. Out of Scope

Jangan implementasikan tanpa instruksi user:

- Google Drive Backup
- Multi User
- Cloud Sync
- WhatsApp Notification
- Push Notification
- Inventory Management
- Receipt Scanner
- Multi Property
- Web Dashboard
- Edit TenantRoomHistory
- Delete TenantRoomHistory

Jika diperlukan, hanya catat sebagai future enhancement.

Sumber kebenaran utama project ini adalah:

- `docs/PRD.md`
- `docs/architecture.md`
- `docs/data-model.md`
- `docs/design.md`

Kode harus mengikuti dokumen tersebut, bukan sebaliknya.

## 7. Efisiensi Token (Baca Sebelum Membaca Dokumen Lain)

File ini (`AGENTS.md`) dimuat penuh di setiap sesi — jaga tetap ringkas, jangan diisi ulang isi `docs/` secara verbatim.

- Jangan baca seluruh isi `docs/PRD.md`, `architecture.md`, `data-model.md`, `design.md` di setiap task. Baca hanya bagian atau section yang relevan dengan task yang sedang dikerjakan (lihat referensi section spesifik di Bagian 2 di atas sebagai contoh, misal "PRD Bagian 6.2" bukan seluruh PRD).
- Kalau task kecil dan tidak menyentuh business rule baru (contoh: ubah warna, ubah teks, styling kecil), tidak perlu baca dokumen `docs/` sama sekali — cukup ikuti konvensi yang sudah terlihat di kode existing.
- Kalau nanti ada file tambahan di `docs/features/*.md` (untuk fitur besar di luar MVP, lihat PRD Bagian 8), file-file itu bukan wajib dibaca di setiap sesi — hanya dibaca kalau task secara eksplisit menyentuh fitur tersebut.
- Untuk task atau fitur baru yang besar, sebaiknya dikerjakan di sesi chat baru, bukan melanjutkan sesi yang sudah sangat panjang — riwayat percakapan ikut terhitung di setiap balasan, jadi sesi panjang lebih boros dibanding sesi baru yang fokus.
- Kalau ragu apakah suatu informasi perlu dibaca dari `docs/` atau cukup dari kode yang sudah ada, prioritaskan baca kode aktual dulu (source of truth yang sudah berjalan), baru cek dokumen kalau ada ambiguitas.

---

### Catatan Repository

File dan folder berikut bukan sumber kebenaran bisnis aplikasi dan tidak perlu diprioritaskan untuk dibaca:

- `build/`
- `.dart_tool/`
- `android/.gradle/`
- `ios/Pods/`
- `*.g.dart`

Khusus file `*.g.dart` (hasil generate Isar), gunakan hanya jika diperlukan untuk debugging hasil generate. Source of truth tetap berada pada model asli di `lib/data/models/` dan dokumentasi di folder `docs/`.