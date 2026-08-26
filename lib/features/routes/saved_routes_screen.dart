import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/user_profile.dart';
import '../../widgets/band_badge.dart';
import '../../widgets/state_views.dart';
import '../auth/auth_provider.dart';
import 'route_planner_provider.dart';

class SavedRoutesScreen extends StatefulWidget {
  const SavedRoutesScreen({super.key});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      if (userId != null) {
        context.read<RoutePlannerProvider>().loadSavedRoutes(userId);
      }
    });
  }

  Future<void> _confirmDelete(SavedRoute route) async {
    final provider = context.read<RoutePlannerProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete route'),
        content: Text('Remove "${route.label}" from your saved routes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteSavedRoute(route.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutePlannerProvider>();
    final routes = provider.savedRoutes;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved routes')),
      body: provider.loadingSaved
          ? const LoadingView(message: 'Loading your routes')
          : routes.isEmpty
              ? const EmptyView(
                  message: 'No saved routes yet.\nPlan a journey and tap the '
                      'bookmark to keep it here.',
                  icon: Icons.bookmark_border,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            provider.applySavedRoute(route);
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(route.label,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${provider.network.stationName(route.originStationId)}'
                                        '  →  '
                                        '${provider.network.stationName(route.destinationStationId)}',
                                        style: AppTheme.mono(
                                          size: 11.5,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 9),
                                      StatusPill(
                                        label: route.preference.label
                                            .toUpperCase(),
                                        colour: AppTheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => _confirmDelete(route),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
