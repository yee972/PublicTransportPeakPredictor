enum DemandBand { quiet, baseline, moderate, busy, unknown }

class DemandBands {
  static const double quietBelow = 0.80;
  static const double baselineBelow = 1.00;
  static const double moderateBelow = 1.07;

  static DemandBand fromRelative(double relativeToTypical) {
    if (relativeToTypical < quietBelow) return DemandBand.quiet;
    if (relativeToTypical < baselineBelow) return DemandBand.baseline;
    if (relativeToTypical < moderateBelow) return DemandBand.moderate;
    return DemandBand.busy;
  }
}
