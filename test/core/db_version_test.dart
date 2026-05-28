import 'package:flutter_test/flutter_test.dart';
import 'package:micro_habits/core/services/database_service.dart';

void main() {
  test('DatabaseService targets schema version 16', () {
    expect(DatabaseService.kSchemaVersion, 16);
  });
}
