# Lessons Learned — June 10, 2026

## DB Migration Checklist (applies to every Phase touching schema)

### Dependency order (strict — don't skip steps)

| Step | Files | Verify |
|------|-------|--------|
| 1. Model | `lib/models/*.dart` | `copyWith`, `toJson`, `fromJson` all include new field |
| 2. Storage read | `storage_service.dart` — `get*()` mapper | Add `map['camelCase'] = m['snake_case']` |
| 3. Storage write | `storage_service.dart` — `add*()` / `update*()` | Add `'snake_case': model.camelCase` |
| 4. `_onCreate` | `database_service.dart` | Gate with `if (version >= N)` for new tables/columns |
| 5. `_onUpgrade` | `database_service.dart` | `oldVersion < N` block with existence check (PRAGMA) |
| 6. Bump version | `static const int kSchemaVersion` | Increment |
| 7. Update test infra | `createTestDatabase` default, `runMigration` target, `db_version_test.dart` | All must reference `kSchemaVersion`, not hardcoded |
| 8. Update mocks | All `_MockStorageService` classes | Must include new methods if repository calls them |

### Test infra invariants (must stay in sync)

- `createTestDatabase` default version → `kSchemaVersion`
- `runMigration` target version → `kSchemaVersion`
- `test/core/db_version_test.dart` assertion → `kSchemaVersion`

### Common footgun: `_onCreate` version gating

`_onCreate(db, int version)` receives a version argument but historically ignores it (always outputs latest schema). For migration tests that create DBs at old versions, new schema must be gated:

```dart
${version >= 17 ? 'new_column TEXT,' : ''}
```

Without this, `createTestDatabase(version: 16)` gets the v17 schema, then the v17 migration `ALTER TABLE ADD COLUMN` fails with duplicate column.
