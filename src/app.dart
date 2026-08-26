import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
import 'data/local/app_database.dart';
import 'data/local/preferences_service.dart';
import 'data/remote/account_api.dart';
import 'data/remote/reference_api.dart';
import 'data/remote/ridership_api.dart';
import 'data/repositories/account_repository.dart';
import 'data/repositories/network_repository.dart';
import 'data/repositories/ridership_repository.dart';
import 'features/auth/auth_gate.dart';
import 'features/auth/auth_provider.dart';
import 'features/busytimes/busy_times_provider.dart';
import 'features/forecast/forecast_provider.dart';
import 'features/routes/route_planner_provider.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';

class PeakPredictorApp extends StatelessWidget {
  const PeakPredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    final database = AppDatabase.instance;
    final preferences = PreferencesService();

    final networkRepository = NetworkRepository(ReferenceApi(client), database);
    final ridershipRepository = RidershipRepository(RidershipApi(client), database);
    final accountRepository = AccountRepository(AccountApi(client), preferences);

    return MultiProvider(
      providers: [
        Provider<PreferencesService>.value(value: preferences),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<AccountRepository>.value(value: accountRepository),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(client, accountRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ForecastProvider(networkRepository, ridershipRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => BusyTimesProvider(
            networkRepository,
            ridershipRepository,
            LocationService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => RoutePlannerProvider(
            networkRepository,
            accountRepository,
            LocationService(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Peak Predictor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const AuthGate(),
      ),
    );
  }
}
