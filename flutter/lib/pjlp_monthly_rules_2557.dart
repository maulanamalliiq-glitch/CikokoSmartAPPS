/// PJLP monthly scoring rules, release 2557.
/// Server must independently validate attendance, work evidence and authorization.
class PjlpMonthlyMetrics {
  final int scheduledDays, validPresentDays, lateDays;
  final int assignedJobs, completedJobs, documentedJobs;
  const PjlpMonthlyMetrics({
    required this.scheduledDays,
    required this.validPresentDays,
    required this.lateDays,
    required this.assignedJobs,
    required this.completedJobs,
    required this.documentedJobs,
  });
}

class PjlpMonthlyScore {
  final double attendance, work, documentation, total;
  const PjlpMonthlyScore(this.attendance, this.work, this.documentation, this.total);
}

class PjlpScoring {
  static double _ratio(int numerator, int denominator) =>
      denominator <= 0 ? 0 : (numerator.clamp(0, denominator) / denominator);

  /// Illustrative weights until formally approved by the administration:
  /// attendance 30%, completed assignments 50%, complete photo sets 20%.
  /// Missing scheduled days / assigned jobs are not silently awarded full marks.
  static PjlpMonthlyScore calculate(PjlpMonthlyMetrics m, {
    double attendanceWeight = 30,
    double workWeight = 50,
    double documentationWeight = 20,
  }) {
    if (m.scheduledDays < 0 || m.validPresentDays < 0 || m.lateDays < 0 ||
        m.assignedJobs < 0 || m.completedJobs < 0 || m.documentedJobs < 0) {
      throw ArgumentError('Metrics must be nonnegative');
    }
    if (attendanceWeight < 0 || workWeight < 0 || documentationWeight < 0 ||
        (attendanceWeight + workWeight + documentationWeight - 100).abs() > 0.0001) {
      throw ArgumentError('Weights must be nonnegative and total 100');
    }
    final attendance = _ratio(m.validPresentDays - m.lateDays, m.scheduledDays) * 100;
    final work = _ratio(m.completedJobs, m.assignedJobs) * 100;
    final documentation = _ratio(m.documentedJobs, m.assignedJobs) * 100;
    final total = (attendance * attendanceWeight +
        work * workWeight + documentation * documentationWeight) / 100;
    return PjlpMonthlyScore(attendance, work, documentation, total);
  }

  /// Rabu: lokasi fleksibel; GPS and live selfie are still mandatory.
  /// For other weekdays, attendance must be within the office radius.
  /// Weekend attendance requires an explicit admin-issued schedule.
  static bool attendanceLocationAllowed({
    required DateTime localDate,
    required bool scheduled,
    required bool gpsValid,
    required bool liveSelfieProvided,
    required double distanceMeters,
    required double officeRadiusMeters,
  }) {
    if (!scheduled || !gpsValid || !liveSelfieProvided ||
        distanceMeters.isNaN || distanceMeters < 0 ||
        officeRadiusMeters <= 0) return false;
    return localDate.weekday == DateTime.wednesday ||
        distanceMeters <= officeRadiusMeters;
  }
}
