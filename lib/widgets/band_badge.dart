import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/demand_band.dart';

class BandBadge extends StatelessWidget {
  final DemandBand band;
  final String? overrideLabel;

  const BandBadge({super.key, required this.band, this.overrideLabel});

  @override
  Widget build(BuildContext context) {
    final colour = DemandPalette.of(band);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        overrideLabel ?? DemandPalette.shortLabel(band),
        style: AppTheme.mono(size: 10.5, color: colour, weight: FontWeight.w700),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color colour;

  const StatusPill({super.key, required this.label, required this.colour});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTheme.mono(size: 10.5, color: colour, weight: FontWeight.w700),
      ),
    );
  }
}

class LineDot extends StatelessWidget {
  final Color colour;
  final String code;

  const LineDot({super.key, required this.colour, required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
      child: Text(
        code,
        style: AppTheme.mono(size: 11, color: Colors.white, weight: FontWeight.w700),
      ),
    );
  }
}
