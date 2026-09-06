import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../widgets/section_card.dart';
import '../auth/auth_provider.dart';
import '../forecast/forecast_provider.dart';
import '../routes/station_picker_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final forecast = context.watch<ForecastProvider>();
    final profile = auth.profile;
    final homeStationId = profile?.homeStationId;
    final homeStation =
        homeStationId == null ? null : forecast.network.station(homeStationId);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          SectionCard(
            title: 'Account',
            icon: Icons.person_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.displayName,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 3),
                Text(auth.email, style: AppTheme.mono(size: 12)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Home station',
            icon: Icons.home_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homeStation?.name ?? 'Not set',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Used as the default starting point in the route planner.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final selected = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StationPickerScreen(
                              network: forecast.network,
                              title: 'Select home station',
                            ),
                          ),
                        );
                        if (selected == null || !context.mounted) return;
                        await context
                            .read<AuthProvider>()
                            .updateProfile(homeStationId: selected);
                      },
                      icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                      label: const Text('Change'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Offline data',
            icon: Icons.storage_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  forecast.syncedAt == null
                      ? 'No local copy stored yet'
                      : 'Last synced ${Formatters.dayMonth(forecast.syncedAt!)} '
                          'at ${Formatters.clock(forecast.syncedAt!)}',
                  style: AppTheme.mono(size: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stations, schedules and ridership are mirrored into an on-device '
                  'SQLite database so the app still works without a connection.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context
                      .read<ForecastProvider>()
                      .load(forceRefresh: true),
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Refresh now'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppTheme.primary),
              title: const Text('About & data'),
              subtitle: const Text('Sources, methods and citations'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              ),
            ),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: DemandPalette.busy,
              side: const BorderSide(color: DemandPalette.busy),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Sign out'),
                  content: const Text('You will need to sign in again to see '
                      'your saved routes.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !context.mounted) return;
              await context.read<AuthProvider>().signOut();
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.logout, size: 19),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
