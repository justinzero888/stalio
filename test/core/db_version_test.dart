import 'package:flutter_test/flutter_test.dart';
import 'package:stalio/core/services/database_service.dart';

void main() {
  test('DatabaseService targets schema version 17', () {
    expect(DatabaseService.kSchemaVersion, 18);
  });
}
