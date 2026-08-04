import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/safety_provider.dart';
import 'providers/sos_provider.dart';
import 'providers/weather_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/sos/sos_live_map_screen.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class WeBAlertApp extends StatefulWidget {
  const WeBAlertApp({super.key});

  @override
  State<WeBAlertApp> createState() => _WeBAlertAppState();
}

class _WeBAlertAppState extends State<WeBAlertApp> {
  @override
  void initState() {
    super.initState();
    PushNotificationService.instance.onSosNotificationTapped = (sosId, senderName, lat, lon) {
      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => SosLiveMapScreen(sosId: sosId, senderName: senderName, initialLat: lat, initialLon: lon),
      ));
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => SafetyProvider()),
        ChangeNotifierProvider(create: (_) => SosProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'WeBAlert',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
      ),
    );
  }
}