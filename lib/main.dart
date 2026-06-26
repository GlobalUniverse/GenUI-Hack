import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/advisor_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/login_screen.dart';
import 'services/chat_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(const FinPilotApp());
}

class FinPilotApp extends StatelessWidget {
  const FinPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: MaterialApp(
        title: 'FinPilot',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'SF Pro Display',
          scaffoldBackgroundColor: AppColors.bg,
          colorScheme: const ColorScheme.light(
            primary: AppColors.ink,
            secondary: AppColors.green,
            surface: AppColors.card,
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: AppColors.card,
            indicatorColor: AppColors.divider,
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.inkMid),
            ),
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final snap = context.watch<ChatProvider>().snapshot;
    final tabs = snap?.tabs ?? ['dashboard', 'advisor', 'goals'];

    final destinations = <_TabDef>[
      if (tabs.contains('dashboard'))
        const _TabDef(
          screen: DashboardScreen(),
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
      if (tabs.contains('advisor'))
        const _TabDef(
          screen: AdvisorScreen(),
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: 'Advisor',
        ),
      if (tabs.contains('goals'))
        const _TabDef(
          screen: GoalsScreen(),
          icon: Icon(Icons.flag_outlined),
          selectedIcon: Icon(Icons.flag),
          label: 'Goals',
        ),
    ];

    // Clamp index when tab count shrinks (e.g. no goals tab)
    final clampedIndex = _index.clamp(0, destinations.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: clampedIndex,
        children: destinations.map((d) => d.screen).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.card,
          elevation: 0,
          indicatorColor: AppColors.divider,
          selectedIndex: clampedIndex,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: destinations
              .map((d) => NavigationDestination(
                    icon: IconTheme(
                      data: const IconThemeData(color: AppColors.inkLight),
                      child: d.icon,
                    ),
                    selectedIcon: IconTheme(
                      data: const IconThemeData(color: AppColors.ink),
                      child: d.selectedIcon,
                    ),
                    label: d.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _TabDef {
  final Widget screen;
  final Widget icon;
  final Widget selectedIcon;
  final String label;

  const _TabDef({
    required this.screen,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class AppColors {
  AppColors._();

  static const bg = Color(0xFFF7F7F7);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFEAEAEA);
  static const divider = Color(0xFFF0F0F0);
  static const ink = Color(0xFF0A0A0A);
  static const inkMid = Color(0xFF6B7280);
  static const inkLight = Color(0xFFB0B0B0);
  static const green = Color(0xFF16A34A);
  static const red = Color(0xFFDC2626);
  static const amber = Color(0xFFF59E0B);
}
