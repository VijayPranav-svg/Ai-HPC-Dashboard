import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/solver_screen.dart';
import 'screens/ai_hybrid_screen.dart';
import 'screens/graphs_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDark;
    return MaterialApp(
      title: 'AI-HPC Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  late TabController _tabController;

  // Tab definitions
  static const _tabs = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.code_outlined, Icons.code, 'Python'),
    (Icons.speed_outlined, Icons.speed, 'OpenMP'),
    (Icons.device_hub_outlined, Icons.device_hub, 'MPI'),
    (Icons.grid_on_outlined, Icons.grid_on, 'CUDA'),
    (Icons.psychology_outlined, Icons.psychology, 'AI'),
    (Icons.image_outlined, Icons.image, 'Graphs'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: _buildAppBar(context, state),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // prevent accidental swipe
        children: const [
          HomeScreen(),
          SolverScreen(solverKey: 'python'),
          SolverScreen(solverKey: 'openmp'),
          SolverScreen(solverKey: 'mpi'),
          SolverScreen(solverKey: 'cuda'),
          AiHybridScreen(),
          GraphsScreen(),
        ],
      ),
      bottomNavigationBar: _buildTabBar(),
    );
  }

  AppBar _buildAppBar(BuildContext context, AppState state) {
    return AppBar(
      backgroundColor: AppTheme.bgDark,
      elevation: 0,
      title: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: state.backendAlive ? AppTheme.success : AppTheme.error,
          ),
        ),
        const SizedBox(width: 8),
        const Text('AI-HPC SOLVER'),
      ]),
      actions: [
        if (state.isRunning)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.warning),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
        IconButton(
          icon: Icon(
            context.watch<AppState>().isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: AppTheme.textSecondary,
          ),
          onPressed: () => context.read<AppState>().toggleTheme(),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.divider),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: _tabs.map((tab) => Tab(
          height: 52,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(tab.$1, size: 16),
            const SizedBox(width: 6),
            Text(tab.$3, style: const TextStyle(fontSize: 12)),
          ]),
        )).toList(),
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textSecondary,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
          insets: EdgeInsets.symmetric(horizontal: 4),
        ),
        indicatorWeight: 0,
        dividerColor: Colors.transparent,
      ),
    );
  }
}
