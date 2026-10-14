import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cosmyra_neet_jee/models/models.dart';
import 'package:cosmyra_neet_jee/features/admin/admin_user_management_screen.dart';

void main() {
  group('User Management Joining & Last Active Date/Time Tests', () {
    test('UserProfileModel parses and serializes createdAt and updatedAt accurately', () {
      final json = {
        'id': 'user_abc_123',
        'email': 'student@neet-jee.in',
        'full_name': 'Test Student',
        'phone_number': '+91 9123456789',
        'role': 'student',
        'target_exam': 'NEET',
        'target_year': 2026,
        'class_level': '12th',
        'created_at': '2026-09-03T17:50:35.890739+00:00',
        'updated_at': '2026-10-14T09:30:00.000000+00:00',
      };

      final profile = UserProfileModel.fromJson(json);

      expect(profile.createdAt, isNotNull);
      expect(profile.createdAt!.year, equals(2026));
      expect(profile.createdAt!.month, equals(9));
      expect(profile.createdAt!.day, equals(3));

      expect(profile.updatedAt, isNotNull);
      expect(profile.updatedAt!.year, equals(2026));
      expect(profile.updatedAt!.month, equals(10));
      expect(profile.updatedAt!.day, equals(14));

      final serialized = profile.toJson();
      expect(serialized['created_at'], isNotNull);
      expect(serialized['updated_at'], isNotNull);
    });

    test('AdminUserModel displays exact Joining Date and Time', () {
      final joinedDt = DateTime(2026, 8, 26, 14, 35); // 26 Aug 2026, 02:35 PM
      final user = AdminUserModel(
        id: 'u1',
        name: 'John Doe',
        email: 'john@example.com',
        userIdCode: '9BA129',
        avatarInitials: 'JD',
        avatarColor: Colors.blue,
        role: 'Student',
        examAccess: ['NEET'],
        status: 'Active',
        lastActive: '26 Aug 2026, 02:35 PM',
        joinedOn: '26 Aug 2026',
        joinedAt: joinedDt,
        lastActiveAt: joinedDt,
      );

      expect(user.joinedDateDisplay, equals('26 Aug 2026'));
      expect(user.joinedTimeDisplay, equals('02:35 PM'));
      expect(user.joinedDateTimeDisplay, equals('26 Aug 2026, 02:35 PM'));
    });

    test('AdminUserModel displays exact Last Active Date and Time', () {
      final pastDate = DateTime(2026, 8, 20, 11, 15);
      final user = AdminUserModel(
        id: 'u2',
        name: 'Jane Smith',
        email: 'jane@example.com',
        userIdCode: '6C9AD0',
        avatarInitials: 'JS',
        avatarColor: Colors.green,
        role: 'Student',
        examAccess: ['NEET'],
        status: 'Active',
        lastActive: '20 Aug 2026, 11:15 AM',
        joinedOn: '01 Aug 2026',
        joinedAt: DateTime(2026, 8, 1, 9, 0),
        lastActiveAt: pastDate,
      );

      expect(user.lastActiveDateDisplay, equals('20 Aug 2026'));
      expect(user.lastActiveTimeDisplay, equals('11:15 AM'));
      expect(user.lastActiveDateTimeDisplay, equals('20 Aug 2026, 11:15 AM'));
      expect(user.isRecentlyActive, isFalse);
    });

    test('AdminUserModel detects recently active sessions (< 5 min)', () {
      final now = DateTime.now();
      final userRecent = AdminUserModel(
        id: 'u3',
        name: 'Mahboob Admin',
        email: 'admin@neet-jee.in',
        userIdCode: 'A558DE',
        avatarInitials: 'MA',
        avatarColor: Colors.purple,
        role: 'Super Administrator',
        examAccess: ['NEET'],
        status: 'Active',
        lastActive: 'Just now',
        joinedOn: '26 Aug 2026',
        joinedAt: DateTime(2026, 8, 26, 10, 0),
        lastActiveAt: now.subtract(const Duration(minutes: 1)),
      );

      expect(userRecent.isRecentlyActive, isTrue);
      expect(userRecent.lastActiveDateDisplay, equals('Today'));
      expect(userRecent.lastActiveTimeDisplay.contains('Active'), isTrue);
    });
  });
}
