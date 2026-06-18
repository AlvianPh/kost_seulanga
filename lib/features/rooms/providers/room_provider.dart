import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/isar_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/room_collection.dart';
import '../../../data/repositories/room_repository.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final db = IsarService().db;
  return RoomRepository(db);
});

// State for search query
final roomSearchQueryProvider = StateProvider<String>((ref) => '');

// State for status filter
final roomStatusFilterProvider = StateProvider<RoomStatus?>((ref) => null);

// StreamProvider for watching rooms with current filters
final roomsStreamProvider = StreamProvider<List<RoomCollection>>((ref) {
  final repository = ref.watch(roomRepositoryProvider);
  final query = ref.watch(roomSearchQueryProvider);
  final status = ref.watch(roomStatusFilterProvider);

  return repository.watchRooms(query: query, status: status);
});
