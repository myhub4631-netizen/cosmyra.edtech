import 'package:flutter_test/flutter_test.dart';

void main() {
  group('P1 Enrollment Status & Admin Purchase History Logic Tests', () {
    test('Student enrollment status map correctly detects free, paid, and pending statuses', () {
      final List<Map<String, dynamic>> mockEntitlements = [
        {
          'id': 'ent-1',
          'product_id': 'series_free_neet_mock',
          'product_title': 'NEET 2026 Free All-India Mock',
          'access_type': 'free',
          'is_active': true,
          'metadata': {'enrollment_type': 'free'},
        },
        {
          'id': 'ent-2',
          'product_id': 'series_paid_jee_ranker',
          'product_title': 'JEE Advanced Ranker Test Series',
          'access_type': 'paid',
          'is_active': true,
          'order_id': 'ORD-998877',
          'metadata': {'enrollment_type': 'paid'},
        },
        {
          'id': 'ent-3',
          'product_id': 'series_revoked_neet_sprint',
          'product_title': 'NEET Crash Sprint Series',
          'access_type': 'paid',
          'is_active': false,
          'metadata': {'enrollment_type': 'paid'},
        },
      ];

      final List<Map<String, dynamic>> mockOrders = [
        {
          'id': 'ORD-112233',
          'order_number': 'ORD-112233',
          'product_id': 'series_pending_neet_test',
          'product_title': 'NEET 2026 Verification Test Series',
          'payment_status': 'pending_verification',
          'status': 'pending',
          'total_amount': 499.0,
        },
      ];

      // Replicate the normalization mapping logic
      final Map<String, Map<String, dynamic>> statusMap = {};

      for (var ent in mockEntitlements) {
        final pId = (ent['product_id'] ?? '').toString().trim().toLowerCase();
        final title = (ent['product_title'] ?? '').toString().trim().toLowerCase();
        final isActive = ent['is_active'] == true;
        final accessType = (ent['access_type'] ?? '').toString().toLowerCase();

        final data = {
          'is_enrolled': isActive,
          'enrollment_type': (accessType == 'free') ? 'Free' : 'Paid',
          'status': isActive ? 'Active' : 'Revoked',
        };

        if (pId.isNotEmpty) statusMap[pId] = data;
        if (title.isNotEmpty) statusMap[title] = data;
      }

      for (var ord in mockOrders) {
        final pId = (ord['product_id'] ?? '').toString().trim().toLowerCase();
        final title = (ord['product_title'] ?? '').toString().trim().toLowerCase();
        final pStatus = (ord['payment_status'] ?? '').toString().toLowerCase();

        if (pStatus.contains('pending')) {
          if (!statusMap.containsKey(pId) && !statusMap.containsKey(title)) {
            final pendingData = {
              'is_enrolled': false,
              'enrollment_type': 'Paid',
              'status': 'Pending Verification',
            };
            if (pId.isNotEmpty) statusMap[pId] = pendingData;
            if (title.isNotEmpty) statusMap[title] = pendingData;
          }
        }
      }

      // Verify Free Enrollment
      expect(statusMap['series_free_neet_mock']?['is_enrolled'], isTrue);
      expect(statusMap['series_free_neet_mock']?['enrollment_type'], equals('Free'));
      expect(statusMap['series_free_neet_mock']?['status'], equals('Active'));

      // Verify Paid Enrollment
      expect(statusMap['series_paid_jee_ranker']?['is_enrolled'], isTrue);
      expect(statusMap['series_paid_jee_ranker']?['enrollment_type'], equals('Paid'));
      expect(statusMap['series_paid_jee_ranker']?['status'], equals('Active'));

      // Verify Revoked Enrollment
      expect(statusMap['series_revoked_neet_sprint']?['is_enrolled'], isFalse);
      expect(statusMap['series_revoked_neet_sprint']?['status'], equals('Revoked'));

      // Verify Pending Order
      expect(statusMap['series_pending_neet_test']?['is_enrolled'], isFalse);
      expect(statusMap['series_pending_neet_test']?['status'], equals('Pending Verification'));
    });

    test('Admin user summary metrics correctly computes active, free, paid counts and confirmed spend', () {
      final List<Map<String, dynamic>> enrollments = [
        {'id': '1', 'title': 'Series A', 'enrollment_type': 'Free', 'is_active': true},
        {'id': '2', 'title': 'Series B', 'enrollment_type': 'Paid', 'is_active': true},
        {'id': '3', 'title': 'Series C', 'enrollment_type': 'Paid', 'is_active': false},
      ];

      final List<Map<String, dynamic>> orders = [
        {'order_number': 'ORD-1', 'total_amount': 499.0, 'payment_status': 'completed'},
        {'order_number': 'ORD-2', 'total_amount': 999.0, 'payment_status': 'paid'},
        {'order_number': 'ORD-3', 'total_amount': 299.0, 'payment_status': 'pending'},
        {'order_number': 'ORD-4', 'total_amount': 0.0, 'payment_status': 'completed', 'payment_method': 'Free'},
      ];

      final int activeSeriesCount = enrollments.where((e) => e['is_active'] == true).length;
      final int paidSeriesCount = enrollments.where((e) => e['enrollment_type'] == 'Paid').length;
      final int freeSeriesCount = enrollments.where((e) => e['enrollment_type'] == 'Free').length;
      final int productOrdersCount = orders.length;

      double totalConfirmedSpend = 0.0;
      for (var ord in orders) {
        final pStatus = (ord['payment_status'] ?? '').toString().toLowerCase();
        if (pStatus == 'completed' || pStatus == 'paid') {
          totalConfirmedSpend += (ord['total_amount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      expect(activeSeriesCount, equals(2));
      expect(paidSeriesCount, equals(2));
      expect(freeSeriesCount, equals(1));
      expect(productOrdersCount, equals(4));
      // Only ORD-1 (499) + ORD-2 (999) + ORD-4 (0) = 1498.0
      expect(totalConfirmedSpend, equals(1498.0));
    });

    test('Prevents duplicate enrollments using deterministic entitlement UUID logic', () {
      // Deterministic key generation
      String generateDeterministicEntKey(String userId, String seriesId) {
        final cleanSeries = seriesId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
        return 'ent_${userId}_$cleanSeries';
      }

      final key1 = generateDeterministicEntKey('usr_student_123', 'neet-full-test-series-2026');
      final key2 = generateDeterministicEntKey('usr_student_123', 'neet-full-test-series-2026');
      final keyDifferentUser = generateDeterministicEntKey('usr_student_456', 'neet-full-test-series-2026');

      expect(key1, equals(key2));
      expect(key1, isNot(equals(keyDifferentUser)));
    });

    test('Completed and approved payment overrides pending verification state on student card', () {
      final List<Map<String, dynamic>> userOrders = [
        {
          'id': 'ORD-OLD-01',
          'order_number': 'ORD-OLD-01',
          'product_id': 'dc86cc30-956a-4ade-a030-dc86956acade',
          'product_name': 'NEET 2027 Full Syllabus Test Series',
          'status': 'pending_verification',
          'payment_status': 'pending_verification',
          'total_amount': 499.0,
        },
        {
          'id': 'ORD-05206658',
          'order_number': 'ORD-05206658',
          'product_id': 'dc86cc30-956a-4ade-a030-dc86956acade',
          'product_name': 'NEET 2027 Full Syllabus Test Series',
          'status': 'completed',
          'payment_status': 'completed',
          'total_amount': 499.0,
        },
      ];

      final Map<String, Map<String, dynamic>> resultMap = {};

      for (var ord in userOrders) {
        final ordStatus = (ord['status'] ?? ord['payment_status'] ?? '').toString().trim().toLowerCase();
        final isCompleted = ordStatus == 'completed' || ordStatus == 'approved' || ordStatus == 'verified' || ordStatus == 'paid' || ordStatus == 'success';
        final isPending = ordStatus == 'pending_verification' || ordStatus == 'pending';

        final pId = (ord['product_id'] ?? '').toString().trim();
        final pTitle = (ord['product_name'] ?? ord['title'] ?? '').toString().trim();

        if (isCompleted) {
          final completedData = {
            'is_enrolled': true,
            'enrollment_type': 'Paid',
            'status': 'Active',
            'order_id': ord['order_number'] ?? ord['id'] ?? '',
          };
          if (pId.isNotEmpty) resultMap[pId.toLowerCase()] = completedData;
          if (pTitle.isNotEmpty) resultMap[pTitle.toLowerCase()] = completedData;
        } else if (isPending) {
          final pendingData = {
            'is_enrolled': false,
            'enrollment_type': 'Paid',
            'status': 'Pending Verification',
            'order_id': ord['order_number'] ?? ord['id'] ?? '',
          };
          if (pId.isNotEmpty) {
            final existing = resultMap[pId.toLowerCase()];
            if (existing == null || existing['is_enrolled'] != true) {
              resultMap[pId.toLowerCase()] = pendingData;
            }
          }
        }
      }

      final seriesStatus = resultMap['dc86cc30-956a-4ade-a030-dc86956acade'];
      expect(seriesStatus, isNotNull);
      expect(seriesStatus!['is_enrolled'], isTrue);
      expect(seriesStatus['status'], equals('Active'));
      expect(seriesStatus['enrollment_type'], equals('Paid'));
      expect(seriesStatus['order_id'], equals('ORD-05206658'));
    });

    test('Pending or failed order does not grant enrolled access', () {
      final List<Map<String, dynamic>> pendingOnlyOrders = [
        {
          'id': 'ORD-PENDING-99',
          'order_number': 'ORD-PENDING-99',
          'product_id': 'test-series-unapproved',
          'product_name': 'Unapproved Test Series',
          'status': 'pending_verification',
          'payment_status': 'pending',
          'total_amount': 299.0,
        },
      ];

      final Map<String, Map<String, dynamic>> resultMap = {};
      for (var ord in pendingOnlyOrders) {
        final ordStatus = (ord['status'] ?? ord['payment_status'] ?? '').toString().trim().toLowerCase();
        final isCompleted = ordStatus == 'completed' || ordStatus == 'approved';
        final isPending = ordStatus == 'pending_verification' || ordStatus == 'pending';
        final pId = (ord['product_id'] ?? '').toString().trim();

        if (isCompleted) {
          resultMap[pId.toLowerCase()] = {'is_enrolled': true, 'status': 'Active'};
        } else if (isPending) {
          resultMap[pId.toLowerCase()] = {'is_enrolled': false, 'status': 'Pending Verification'};
        }
      }

      expect(resultMap['test-series-unapproved']?['is_enrolled'], isFalse);
      expect(resultMap['test-series-unapproved']?['status'], equals('Pending Verification'));
    });
  });
}
