import '../core/app_theme.dart';

class DemandForecast {
  final DateTime date;
  final String lineId;
  final int predictedRiders;
  final int baselineRiders;
  final double trendFactor;
  final double holidayFactor;
  final double percentOfMax;
  final double deviationFromBaseline;
  final double relativeToTypical;
  final DemandBand band;
  final bool hasEnoughHistory;
  final String? holidayName;

  const DemandForecast({
    required this.date,
    required this.lineId,
    required this.predictedRiders,
    required this.baselineRiders,
    required this.trendFactor,
    required this.holidayFactor,
    required this.percentOfMax,
    required this.deviationFromBaseline,
    required this.relativeToTypical,
    required this.band,
    required this.hasEnoughHistory,
    this.holidayName,
  });

  bool get isHoliday => holidayName != null;

  factory DemandForecast.insufficient(DateTime date, String lineId) {
    return DemandForecast(
      date: date,
      lineId: lineId,
      predictedRiders: 0,
      baselineRiders: 0,
      trendFactor: 1,
      holidayFactor: 1,
      percentOfMax: 0,
      deviationFromBaseline: 0,
      relativeToTypical: 0,
      band: DemandBand.unknown,
      hasEnoughHistory: false,
    );
  }
}

class ValidationMetrics {
  final String lineId;
  final double meanAbsoluteError;
  final double meanAbsolutePercentageError;
  final double classificationAccuracy;
  final int sampleSize;
  final int holdOutDays;

  const ValidationMetrics({
    required this.lineId,
    required this.meanAbsoluteError,
    required this.meanAbsolutePercentageError,
    required this.classificationAccuracy,
    required this.sampleSize,
    required this.holdOutDays,
  });

  bool get isReliable => sampleSize >= 14;
}

class LineOutlook {
  final String lineId;
  final DemandForecast today;
  final DemandForecast tomorrow;
  final List<RidershipPoint> recentTrend;

  const LineOutlook({
    required this.lineId,
    required this.today,
    required this.tomorrow,
    required this.recentTrend,
  });
}

class RidershipPoint {
  final DateTime date;
  final int riders;
  final bool isActual;

  const RidershipPoint({
    required this.date,
    required this.riders,
    required this.isActual,
  });
}

class NetworkOutlook {
  final DemandBand band;
  final String headline;
  final String detail;
  final DateTime generatedAt;
  final List<LineOutlook> lines;

  const NetworkOutlook({
    required this.band,
    required this.headline,
    required this.detail,
    required this.generatedAt,
    required this.lines,
  });
}
