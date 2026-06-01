import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().checkBackend();
      context.read<AppState>().fetchResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero Banner ────────────────────────────────────────────────
          _HeroBanner(backendAlive: state.backendAlive),
          const SizedBox(height: 20),

          // ── Run Pipeline Button ────────────────────────────────────────
          _PipelineController(state: state),
          const SizedBox(height: 16),

          // ── Progress ───────────────────────────────────────────────────
          if (state.isRunning) ...[
            _ProgressSection(state: state),
            const SizedBox(height: 16),
          ],
          if (state.errorMessage.isNotEmpty) ...[
            _ErrorBanner(message: state.errorMessage),
            const SizedBox(height: 16),
          ],

          // ── Summary Table ──────────────────────────────────────────────
          Row(children: [
            const Expanded(
              child: SectionHeader(
                title: 'Execution Times',
                subtitle: 'Comparison across all solvers',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh,
                  color: AppTheme.textSecondary, size: 18),
              onPressed: () => context.read<AppState>().fetchResults(),
            ),
          ]),
          const SizedBox(height: 12),
          _ExecutionSummaryTable(state: state),
          const SizedBox(height: 20),

          // ── Quick Stats Grid ───────────────────────────────────────────
          const SectionHeader(
              title: 'Quick Stats', subtitle: 'Latest pipeline run'),
          const SizedBox(height: 12),
          _QuickStatsGrid(state: state),
          const SizedBox(height: 20),

          // ── About Section ──────────────────────────────────────────────
          _AboutSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Hero Banner ───────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final bool backendAlive;
  const _HeroBanner({required this.backendAlive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.15),
            AppTheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.memory, color: AppTheme.primary, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AI-HPC SOLVER DASHBOARD',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: backendAlive
                  ? AppTheme.success.withOpacity(0.15)
                  : AppTheme.error.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      backendAlive ? AppTheme.success : AppTheme.error,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                backendAlive ? 'Backend Online' : 'Backend Offline',
                style: TextStyle(
                  color: backendAlive ? AppTheme.success : AppTheme.error,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        const Text(
          'Poisson System Hybrid Solver',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'HPC + AI convergence acceleration for large-scale linear systems '
          'using CG, OpenMP, MPI, CUDA, and neural network checkpointing.',
          style: TextStyle(
              color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
        ),
      ]),
    );
  }
}

// ── Pipeline Controller ───────────────────────────────────────────────────────
class _PipelineController extends StatelessWidget {
  final AppState state;
  const _PipelineController({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      GlowButton(
        label:
            state.isRunning ? 'Pipeline Running...' : 'Run Full Pipeline',
        icon: state.isRunning ? null : Icons.play_arrow_rounded,
        loading: state.isRunning,
        onPressed: () => context.read<AppState>().runPipeline(),
      ),
      const SizedBox(width: 12),
      OutlinedButton.icon(
        onPressed: () => context.read<AppState>().fetchResults(),
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('Refresh'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textSecondary,
          side: const BorderSide(color: AppTheme.divider),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ]);
  }
}

// ── Progress Section ──────────────────────────────────────────────────────────
class _ProgressSection extends StatelessWidget {
  final AppState state;
  const _ProgressSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.warning),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              state.statusMessage,
              style: const TextStyle(
                  color: AppTheme.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progress,
              backgroundColor: AppTheme.bgCardLight,
              valueColor:
                  const AlwaysStoppedAnimation(AppTheme.warning),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(state.progress * 100).toInt()}% complete',
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 11),
        ),
      ]),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.error.withOpacity(0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppTheme.error, fontSize: 12),
          ),
        ),
      ]),
    );
  }
}

// ── Execution Summary Table ───────────────────────────────────────────────────
class _ExecutionSummaryTable extends StatelessWidget {
  final AppState state;
  const _ExecutionSummaryTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final r = state.result;

    final rows = [
      {'name': 'Python CG', 'time': r.pythonTime, 'iters': r.pythonIterations, 'color': AppTheme.primary},
      {'name': 'OpenMP', 'time': r.openmpTime, 'iters': r.openmpIterations, 'color': AppTheme.success},
      {'name': 'MPI', 'time': r.mpiTime, 'iters': r.mpiIterations, 'color': AppTheme.warning},
      {'name': 'CUDA', 'time': r.cudaTime, 'iters': r.cudaIterations, 'color': AppTheme.secondary},
    ];

    final maxTime = rows
        .map((r) => (r['time'] as double?) ?? 0.0)
        .fold(0.0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            _tableHeader('Solver', flex: 2),
            _tableHeader('Time (s)', flex: 2),
            _tableHeader('Iterations', flex: 2),
            _tableHeader('Speed', flex: 3),
          ]),
          const Divider(height: 16),
          ...rows.map((row) {
            final time = row['time'] as double?;
            final iters = row['iters'] as int?;
            final color = row['color'] as Color;
            final barWidth =
                (maxTime > 0 && time != null) ? (time / maxTime) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    row['name'] as String,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    time != null ? time.toStringAsFixed(3) : '—',
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    iters?.toString() ?? '—',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: barWidth.toDouble(),
                        backgroundColor: AppTheme.bgCardLight,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                ),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  Widget _tableHeader(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Quick Stats Grid ──────────────────────────────────────────────────────────
class _QuickStatsGrid extends StatelessWidget {
  final AppState state;
  const _QuickStatsGrid({required this.state});

  String _fmt(double? v) => v != null ? v.toStringAsFixed(3) : '—';

  @override
  Widget build(BuildContext context) {
    final r = state.result;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: [
        StatCard(
            label: 'Python Time',
            value: _fmt(r.pythonTime),
            unit: 's',
            color: AppTheme.primary,
            icon: Icons.code),
        StatCard(
            label: 'OpenMP Time',
            value: _fmt(r.openmpTime),
            unit: 's',
            color: AppTheme.success,
            icon: Icons.speed),
        StatCard(
            label: 'MPI Time',
            value: _fmt(r.mpiTime),
            unit: 's',
            color: AppTheme.warning,
            icon: Icons.device_hub),
        StatCard(
            label: 'CUDA Time',
            value: _fmt(r.cudaTime),
            unit: 's',
            color: AppTheme.secondary,
            icon: Icons.grid_on),
      ],
    );
  }
}

// ── About Section ─────────────────────────────────────────────────────────────
class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.functions_outlined, 'Python CG',
          'Pure Python conjugate gradient solver — baseline reference'),
      (Icons.speed_outlined, 'OpenMP',
          'Shared-memory parallelism for multi-core CPU acceleration'),
      (Icons.device_hub_outlined, 'MPI',
          'Distributed memory across multiple processes / nodes'),
      (Icons.grid_4x4_outlined, 'CUDA',
          'GPU-accelerated solver with massive parallelism'),
      (Icons.psychology_outlined, 'AI Hybrid',
          'Neural network checkpointing to accelerate convergence'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
                title: 'About This Project',
                subtitle: 'Poisson system hybrid solver'),
            const SizedBox(height: 14),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item.$1,
                            color: AppTheme.primary, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.$2,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            Text(item.$3,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                    height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
