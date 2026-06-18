class RelationConstraintException implements Exception {
  final String message;
  RelationConstraintException(this.message);

  @override
  String toString() => message;
}
