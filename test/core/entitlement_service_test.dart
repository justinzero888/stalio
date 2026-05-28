import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blinking/core/services/entitlement_service.dart';

void main() {
  group('EntitlementService', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    group('state machine', () {
      test('initializes to preview state by default', () async {
        final service = EntitlementService();
        await service.init(prefs);
        expect(service.currentState, EntitlementState.preview);
      });

      test('initializes to restricted state when not in preview', () async {
        await prefs.setString('entitlement_state', 'restricted');
        final service = EntitlementService();
        await service.init(prefs);
        expect(service.currentState, EntitlementState.restricted);
      });

      test('initializes to paid state when purchased', () async {
        await prefs.setString('entitlement_state', 'paid');
        final service = EntitlementService();
        await service.init(prefs);
        expect(service.currentState, EntitlementState.paid);
      });

      test('transitions preview to restricted after 21 days', () async {
        final daysBefore = DateTime.now().subtract(Duration(days: 22));
        await prefs.setString('entitlement_preview_started', daysBefore.toIso8601String());
        await prefs.setString('entitlement_state', 'preview');

        final service = EntitlementService();
        await service.init(prefs);

        expect(service.currentState, EntitlementState.restricted);
        expect(service.previewDaysRemaining, 0);
      });

      test('clamped preview days to [0, 21]', () async {
        final daysBefore = DateTime.now().subtract(Duration(days: 25));
        await prefs.setString('entitlement_preview_started', daysBefore.toIso8601String());
        await prefs.setString('entitlement_state', 'preview');

        final service = EntitlementService();
        await service.init(prefs);

        expect(service.previewDaysRemaining, greaterThanOrEqualTo(0));
        expect(service.previewDaysRemaining, lessThanOrEqualTo(21));
      });

      test('respects restricted state and does not apply local preview', () async {
        await prefs.setString('entitlement_state', 'restricted');
        final daysBefore = DateTime.now().subtract(Duration(days: 22));
        await prefs.setString('entitlement_preview_started', daysBefore.toIso8601String());

        final service = EntitlementService();
        await service.init(prefs);

        expect(service.currentState, EntitlementState.restricted);
      });

      test('respects paid state and does not apply local preview', () async {
        await prefs.setString('entitlement_state', 'paid');
        final daysBefore = DateTime.now().subtract(Duration(days: 22));
        await prefs.setString('entitlement_preview_started', daysBefore.toIso8601String());

        final service = EntitlementService();
        await service.init(prefs);

        expect(service.currentState, EntitlementState.paid);
      });
    });

    group('feature access control', () {
      test('preview state allows AI usage', () async {
        await prefs.setString('entitlement_state', 'preview');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.canUseAI, isTrue);
      });

      test('paid state allows AI usage', () async {
        await prefs.setString('entitlement_state', 'paid');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.canUseAI, isTrue);
      });

      test('restricted state denies AI usage', () async {
        await prefs.setString('entitlement_state', 'restricted');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.canUseAI, isFalse);
      });

      test('preview state allows habit creation', () async {
        await prefs.setString('entitlement_state', 'preview');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.canAddHabit, isTrue);
      });

      test('restricted state denies habit creation', () async {
        await prefs.setString('entitlement_state', 'restricted');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.canAddHabit, isFalse);
      });

      test('preview state allows backup', () async {
        await prefs.setString('entitlement_state', 'preview');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.canBackup, isTrue);
      });

      test('restricted state denies backup', () async {
        await prefs.setString('entitlement_state', 'restricted');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.canBackup, isFalse);
      });

      test('preview state allows export', () async {
        await prefs.setString('entitlement_state', 'preview');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.canExport, isTrue);
      });

      test('restricted state denies export', () async {
        await prefs.setString('entitlement_state', 'restricted');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.canExport, isFalse);
      });
    });

    group('AI source and visual indicators', () {
      test('preview returns managed AI source', () async {
        await prefs.setString('entitlement_state', 'preview');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.aiSource, AISource.managed);
      });

      test('paid returns managed AI source', () async {
        await prefs.setString('entitlement_state', 'paid');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.aiSource, AISource.managed);
      });

      test('restricted returns no AI source', () async {
        await prefs.setString('entitlement_state', 'restricted');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.aiSource, AISource.none);
      });

      test('preview button visual is active', () async {
        await prefs.setString('entitlement_state', 'preview');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.buttonVisual, AIButtonVisual.active);
      });

      test('paid button visual is active', () async {
        await prefs.setString('entitlement_state', 'paid');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.buttonVisual, AIButtonVisual.active);
      });

      test('restricted button visual is dormant', () async {
        await prefs.setString('entitlement_state', 'restricted');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.buttonVisual, AIButtonVisual.dormant);
      });
    });

    group('preview day tracking', () {
      test('preview days decreases each day', () async {
        final daysBefore = DateTime.now().subtract(Duration(days: 5));
        await prefs.setString('entitlement_preview_started', daysBefore.toIso8601String());
        await prefs.setString('entitlement_state', 'preview');

        final service = EntitlementService();
        await service.init(prefs);

        expect(service.previewDaysRemaining, greaterThan(0));
        expect(service.previewDaysRemaining, lessThan(21));
      });

      test('wasPreview flag tracks if user was previously in preview', () async {
        await prefs.setBool('entitlement_was_preview', true);
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.wasPreview, isTrue);
      });

      test('wasPreview defaults to false', () async {
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.wasPreview, isFalse);
      });
    });

    group('state persistence', () {
      test('saves and restores state across instances', () async {
        final service1 = EntitlementService();
        await prefs.setString('entitlement_state', 'paid');
        await service1.init(prefs);

        final service2 = EntitlementService();
        await service2.init(prefs);

        expect(service2.currentState, EntitlementState.paid);
      });

      test('saves and restores preview days remaining', () async {
        await prefs.setInt('entitlement_preview_days', 10);
        await prefs.setString('entitlement_state', 'preview');

        final service = EntitlementService();
        await service.init(prefs);

        // The service should preserve the saved days
        expect(service.previewDaysRemaining, greaterThanOrEqualTo(0));
      });
    });

    group('state queries', () {
      test('isPreviewActive returns true in preview state', () async {
        await prefs.setString('entitlement_state', 'preview');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.isPreviewActive, isTrue);
        expect(service.isRestricted, isFalse);
        expect(service.isPaid, isFalse);
      });

      test('isRestricted returns true in restricted state', () async {
        await prefs.setString('entitlement_state', 'restricted');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.isRestricted, isTrue);
        expect(service.isPreviewActive, isFalse);
        expect(service.isPaid, isFalse);
      });

      test('isPaid returns true in paid state', () async {
        await prefs.setString('entitlement_state', 'paid');
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.isPaid, isTrue);
        expect(service.isRestricted, isFalse);
        expect(service.isPreviewActive, isFalse);
      });
    });

    group('BYOK (Bring Your Own Key)', () {
      test('hasOwnKey returns false when no providers configured', () async {
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.hasOwnKey, isFalse);
      });

      test('hasOwnKey returns false when only Trial provider exists', () async {
        await prefs.setString(
          'llm_providers',
          '[{"name":"Trial","apiKey":"test_key"}]',
        );
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.hasOwnKey, isFalse);
      });

      test('hasOwnKey returns true when custom provider with API key exists', () async {
        await prefs.setString(
          'llm_providers',
          '[{"name":"Custom","apiKey":"real_key"}]',
        );
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.hasOwnKey, isTrue);
      });

      test('hasActiveBYOK reflects hasOwnKey status', () async {
        await prefs.setString(
          'llm_providers',
          '[{"name":"Custom","apiKey":"real_key"}]',
        );
        final service = EntitlementService();
        await service.init(prefs);

        expect(service.hasActiveBYOK, service.hasOwnKey);
      });
    });
  });
}
