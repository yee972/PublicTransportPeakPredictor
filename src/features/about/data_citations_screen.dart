import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../widgets/band_badge.dart';
import '../../widgets/section_card.dart';

class DataCitationsScreen extends StatelessWidget {
  const DataCitationsScreen({super.key});

  static const List<_Citation> _citations = [
    _Citation(
      title: 'Daily public transport ridership',
      publisher: 'Ministry of Transport Malaysia, via data.gov.my',
      dataset: 'ridership_headline',
      url: AppConfig.ridershipDatasetUrl,
      licence: 'Open Data Terms of Use',
      usedFor: 'Every daily prediction, the 7-day forecast, hold-out validation '
          'and the holiday factor.',
      official: true,
    ),
    _Citation(
      title: 'Malaysian Open Data Portal',
      publisher: 'MAMPU, Public Sector Open Data Programme (DTSA)',
      dataset: 'Portal home',
      url: AppConfig.openDataPortal,
      licence: 'Open Data Terms of Use',
      usedFor: 'The originating platform for all ridership statistics in this app.',
      official: true,
    ),
    _Citation(
      title: 'Rail station coordinates and line sequences',
      publisher: 'OpenStreetMap contributors',
      dataset: 'Rail route relations, Klang Valley',
      url: 'https://www.openstreetmap.org/copyright',
      licence: 'Open Database Licence (ODbL)',
      usedFor: 'The 153-station network graph, interchange detection and the '
          'map on Busy Times.',
      official: false,
    ),
    _Citation(
      title: 'Map tiles',
      publisher: 'OpenStreetMap Foundation',
      dataset: 'Standard tile layer',
      url: 'https://www.openstreetmap.org/copyright',
      licence: 'Open Database Licence (ODbL)',
      usedFor: 'Base map rendering on the Busy Times screen.',
      official: false,
    ),
    _Citation(
      title: 'Service frequency',
      publisher: 'Prasarana Malaysia and MRT Corp published timetables',
      dataset: 'Operating headways by line',
      url: 'https://myrapid.com.my/',
      licence: 'Published operator information',
      usedFor: 'The hourly Busy Times layer and the crowd term in route planning.',
      official: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data citations')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          const SectionHeading(
            label: 'Where every number comes from',
            caption: 'Each figure this app shows can be traced back to one of '
                'these sources.',
          ),
          const SizedBox(height: 16),
          ..._citations.map(
            (citation) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(citation.title,
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        if (citation.official)
                          const StatusPill(
                            label: 'OFFICIAL',
                            colour: AppTheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(citation.publisher,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    _Field(label: 'DATASET', value: citation.dataset),
                    _Field(label: 'LICENCE', value: citation.licence),
                    _Field(label: 'USED FOR', value: citation.usedFor),
                    const SizedBox(height: 10),
                    SelectableText(
                      citation.url,
                      style: AppTheme.mono(
                        size: 11,
                        color: const Color(0xFF2C4B87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const InfoNote(
            message: 'Data reproduced under the terms of each source. This app is '
                'a student project and is not affiliated with any operator or '
                'government agency.',
          ),
        ],
      ),
    );
  }
}

class _Citation {
  final String title;
  final String publisher;
  final String dataset;
  final String url;
  final String licence;
  final String usedFor;
  final bool official;

  const _Citation({
    required this.title,
    required this.publisher,
    required this.dataset,
    required this.url,
    required this.licence,
    required this.usedFor,
    required this.official,
  });
}

class _Field extends StatelessWidget {
  final String label;
  final String value;

  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 3),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
