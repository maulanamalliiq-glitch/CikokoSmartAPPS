import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/pjlp_monthly_rules_2557.dart';

void main() {
  group('PJLP monthly scoring 2557', () {
    test('perfect attendance, jobs and evidence gives 100', () {
      final score = PjlpScoring.calculate(const PjlpMonthlyMetrics(
        scheduledDays: 20, validPresentDays: 20, lateDays: 0,
        assignedJobs: 10, completedJobs: 10, documentedJobs: 10,
      ));
      expect(score.total, 100);
    });

    test('weighted score cannot exceed 100', () {
      final score = PjlpScoring.calculate(const PjlpMonthlyMetrics(
        scheduledDays: 20, validPresentDays: 99, lateDays: 0,
        assignedJobs: 10, completedJobs: 99, documentedJobs: 99,
      ));
      expect(score.total, 100);
    });

    test('rejects weights not totaling 100', () {
      expect(() => PjlpScoring.calculate(
        const PjlpMonthlyMetrics(
          scheduledDays: 20, validPresentDays: 20, lateDays: 0,
          assignedJobs: 10, completedJobs: 10, documentedJobs: 10,
        ), attendanceWeight: 40,
      ), throwsArgumentError);
    });

    test('Wednesday may clock in outside office with GPS and selfie', () {
      expect(PjlpScoring.attendanceLocationAllowed(
        localDate: DateTime(2026, 11, 18),
        scheduled: true, gpsValid: true, liveSelfieProvided: true,
        distanceMeters: 2000, officeRadiusMeters: 100,
      ), isTrue);
    });

    test('Tuesday requires office geofence', () {
      expect(PjlpScoring.attendanceLocationAllowed(
        localDate: DateTime(2026, 11, 17),
        scheduled: true, gpsValid: true, liveSelfieProvided: true,
        distanceMeters: 2000, officeRadiusMeters: 100,
      ), isFalse);
    });

    test('Wednesday still requires GPS and selfie', () {
      expect(PjlpScoring.attendanceLocationAllowed(
        localDate: DateTime(2026, 11, 18),
        scheduled: true, gpsValid: false, liveSelfieProvided: true,
        distanceMeters: 2000, officeRadiusMeters: 100,
      ), isFalse);
    });

    test('unscheduled days reject attendance', () {
      expect(PjlpScoring.attendanceLocationAllowed(
        localDate: DateTime(2026, 11, 21),
        scheduled: false, gpsValid: true, liveSelfieProvided: true,
        distanceMeters: 5, officeRadiusMeters: 100,
      ), isFalse);
    });
  });
}
