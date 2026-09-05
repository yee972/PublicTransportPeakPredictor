import '../models/demand_band.dart';
import '../models/demand_forecast.dart';
import '../models/rail_line.dart';

typedef ForecastLookup = DemandForecast Function(String lineId, DateTime date);
typedef HistoryLookup = List<RidershipPoint> Function(String lineId, int days);

class OutlookSynthesis {
  static NetworkOutlook build({
    required List<RailLine> lines,
    required ForecastLookup forecast,
    required HistoryLookup history,
    required DateTime today,
    int trendDays = 30,
  }) {
    final tomorrow = today.add(const Duration(days: 1));
    final outlooks = <LineOutlook>[];

    for (final line in lines) {
      outlooks.add(LineOutlook(
        lineId: line.id,
        today: forecast(line.id, today),
        tomorrow: forecast(line.id, tomorrow),
        recentTrend: history(line.id, trendDays),
      ));
    }

    final scored = outlooks
        .where((outlook) => outlook.today.hasEnoughHistory)
        .toList()
      ..sort((a, b) =>
          b.today.relativeToTypical.compareTo(a.today.relativeToTypical));

    final unscored =
        outlooks.where((outlook) => !outlook.today.hasEnoughHistory).toList();

    final band = _networkBand(scored);
    return NetworkOutlook(
      band: band,
      headline: _headline(band),
      detail: _detail(band, scored, tomorrow),
      generatedAt: DateTime.now(),
      lines: [...scored, ...unscored],
    );
  }

  static DemandBand _networkBand(List<LineOutlook> scored) {
    if (scored.isEmpty) return DemandBand.unknown;
    final total = scored
        .map((outlook) => outlook.today.relativeToTypical)
        .reduce((a, b) => a + b);
    return DemandBands.fromRelative(total / scored.length);
  }

  static String _headline(DemandBand band) {
    switch (band) {
      case DemandBand.quiet:
        return 'Lighter Than Usual';
      case DemandBand.baseline:
        return 'Typical Demand Expected';
      case DemandBand.moderate:
        return 'Busier Than Usual';
      case DemandBand.busy:
        return 'Heavy Demand Expected';
      case DemandBand.unknown:
        return 'Awaiting Data';
    }
  }

  static String _detail(
    DemandBand band,
    List<LineOutlook> scored,
    DateTime tomorrow,
  ) {
    if (scored.isEmpty) {
      return 'Not enough ridership history yet to describe today.';
    }

    final buffer = StringBuffer();
    switch (band) {
      case DemandBand.quiet:
        buffer.write('Network-wide demand is predicted to be below normal today.');
        break;
      case DemandBand.baseline:
        buffer.write('Network-wide demand is predicted to be typical today.');
        break;
      case DemandBand.moderate:
        buffer.write('Network-wide demand is predicted above normal today.');
        break;
      case DemandBand.busy:
        buffer.write('Network-wide demand is predicted well above normal today.');
        break;
      case DemandBand.unknown:
        buffer.write('Network-wide demand cannot be described today.');
        break;
    }

    final holiday = scored.first.today.holidayName;
    if (holiday != null) {
      buffer.write(' $holiday is reducing expected travel.');
    }

    final tomorrowScores = scored
        .map((outlook) => outlook.tomorrow)
        .where((forecast) => forecast.hasEnoughHistory)
        .toList();
    if (tomorrowScores.isNotEmpty) {
      final average = tomorrowScores
              .map((forecast) => forecast.relativeToTypical)
              .reduce((a, b) => a + b) /
          tomorrowScores.length;
      final descriptor = average >= 1.12
          ? 'a busy day'
          : average >= 1.02
              ? 'a moderately busy day'
              : average < 0.80
                  ? 'a quiet day'
                  : 'a typical day';
      buffer.write(' Tomorrow predicted: $descriptor.');
    }
    return buffer.toString();
  }

  static String busiestLineSummary(NetworkOutlook outlook, String Function(String) nameOf) {
    final scored = outlook.lines
        .where((line) => line.today.hasEnoughHistory)
        .toList();
    if (scored.isEmpty) return 'No line-level prediction available.';
    final busiest = scored.first;
    final percent = ((busiest.today.relativeToTypical - 1) * 100).round();
    if (percent <= 0) {
      return '${nameOf(busiest.lineId)} is closest to its normal volume.';
    }
    return '${nameOf(busiest.lineId)} is predicted $percent% above its own norm.';
  }
}
