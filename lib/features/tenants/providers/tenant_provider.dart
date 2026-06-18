import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/isar_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/tenant_collection.dart';
import '../../../data/repositories/tenant_repository.dart';

// Repository provider
final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  final db = IsarService().db;
  return TenantRepository(db);
});

// Search query state
final tenantSearchQueryProvider = StateProvider<String>((ref) => '');

// Stream provider for tenants with optional search
final tenantsStreamProvider = StreamProvider<List<TenantCollection>>((ref) {
  final repo = ref.watch(tenantRepositoryProvider);
  final query = ref.watch(tenantSearchQueryProvider);
  return repo.watchTenants(query: query);
});

// AsyncNotifier for CRUD operations
class TenantAsyncNotifier extends AsyncNotifier<void> {
  late final TenantRepository _repo;

  @override
  FutureOr<void> build() {
    _repo = ref.read(tenantRepositoryProvider);
  }

  Future<void> createTenant({
    required TenantCollection tenant,
    required int roomId,
    required DateTime checkInDate,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.createTenant(tenant: tenant, roomId: roomId, checkInDate: checkInDate);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateTenant({
    required TenantCollection tenant,
    String? fullName,
    String? phoneNumber,
    String? notes,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.updateTenant(
        tenant: tenant,
        fullName: fullName,
        phoneNumber: phoneNumber,
        notes: notes,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> moveTenant({
    required TenantCollection tenant,
    required int newRoomId,
    required DateTime moveInDate,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.moveTenant(
        tenant: tenant,
        newRoomId: newRoomId,
        moveInDate: moveInDate,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> checkoutTenant({
    required TenantCollection tenant,
    required DateTime checkoutDate,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.checkoutTenant(tenant: tenant, checkOutDate: checkoutDate);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteTenant(int tenantId) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteTenant(tenantId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final tenantAsyncNotifierProvider = AsyncNotifierProvider<TenantAsyncNotifier, void>(TenantAsyncNotifier.new);
