enum RoomStatus { available, occupied, inactive }

enum PaymentMethod { cash, transfer, qris, other }

// Derived saat runtime, TIDAK disimpan sebagai field - dihitung dari paidUntil vs DateTime.now()
// Lihat PRD 6.2
enum PaymentStatus { paid, overdue, upcomingDue }
