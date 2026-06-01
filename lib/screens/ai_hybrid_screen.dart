import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class AiHybridScreen extends StatefulWidget {
  const AiHybridScreen({super.key});

  @override
  State<AiHybridScreen> createState() => _AiHybridScreenState();
}

class _AiHybridScreenState extends State<AiHybridScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final r = state.result;
    final hasData = r.aiCheckpoint != null || r.aiStartIteration != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── AI Hero Banner ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C4DFF).withOpacity(0.2),
                  const Color(0xFF00E5FF).withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF7C4DFF).withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.psychology,
                      color: AppTheme.secondary, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Hybrid Solver',
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Combines neural network predictions with HPC solvers. '
                        'A trained model checkpoints the solution at an intermediate '
                        'iteration, allowing the HPC solver to warm-start and converge faster.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── How it Works ─────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'How AI Accelerates Convergence'),
                  const SizedBox(height: 14),
                  _StepRow(
                    step: '1',
                    title: 'Train the Model',
                    body:
                        'A neural network is trained on solutions from the HPC solver at various problem sizes and boundary conditions.',
                    color: AppTheme.primary,
                  ),
                  _StepRow(
                    step: '2',
                    title: 'Checkpoint Prediction',
                    body:
                        'At runtime, the AI predicts an approximate solution, skipping early slow-convergence iterations.',
                    color: AppTheme.secondary,
                  ),
                  _StepRow(
                    step: '3',
                    title: 'HPC Refinement',
                    body:
                        'The HPC solver (CG) starts from the AI prediction as initial guess and converges in far fewer iterations.',
                    color: AppTheme.success,
                  ),
                  _StepRow(
                    step: '4',
                    title: 'Net Speedup',
                    body:
                        'Total wall-clock time is reduced because the AI eliminates the slow initial phase of convergence.',
                    color: AppTheme.warning,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Run Info Card ────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Expanded(
                        child: SectionHeader(title: 'Last Run Info')),
                    StatusBadge(status: hasData ? 'completed' : 'not_run'),
                  ]),
                  const SizedBox(height: 14),
                  if (!hasData)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Column(children: [
                          Icon(Icons.info_outline,
                              color: AppTheme.textSecondary, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'No results yet.\nRun the full pipeline from the Home tab.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ]),
                      ),
                    )
                  else ...[
                    InfoRow(
                      label: 'Checkpoint Used',
                      value: r.aiCheckpoint ?? '—',
                    ),
                    const Divider(height: 16),
                    InfoRow(
                      label: 'AI Start Iteration',
                      value: r.aiStartIteration?.toString() ?? '—',
                    ),
                    const Divider(height: 16),
                    InfoRow(
                      label: 'Final Residual',
                      value: r.aiResidual != null
                          ? r.aiResidual!.toStringAsExponential(4)
                          : '—',
                    ),
                    const Divider(height: 16),
                    InfoRow(
                      label: 'AI Hybrid Time',
                      value: r.aiHybridTime != null
                          ? '${r.aiHybridTime!.toStringAsFixed(3)} s'
                          : '—',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Stats Grid ───────────────────────────────────────────────────
          if (hasData) ...[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.8,
              children: [
                StatCard(
                  label: 'Checkpoint',
                  value: r.aiCheckpoint?.replaceAll('.pth', '') ?? '—',
                  color: AppTheme.secondary,
                  icon: Icons.save_outlined,
                ),
                StatCard(
                  label: 'Start Iteration',
                  value: r.aiStartIteration?.toString() ?? '—',
                  color: AppTheme.primary,
                  icon: Icons.skip_next_outlined,
                ),
                StatCard(
                  label: 'Final Residual',
                  value: r.aiResidual != null
                      ? r.aiResidual!.toStringAsExponential(2)
                      : '—',
                  color: AppTheme.success,
                  icon: Icons.show_chart,
                ),
                StatCard(
                  label: 'AI Hybrid Time',
                  value: r.aiHybridTime != null
                      ? r.aiHybridTime!.toStringAsFixed(3)
                      : '—',
                  unit: 's',
                  color: AppTheme.warning,
                  icon: Icons.timer_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ── Comparison Card ──────────────────────────────────────────────
          if (hasData) _ComparisonCard(state: state),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Step Row ──────────────────────────────────────────────────────────────────
class _StepRow extends StatelessWidget {
  final String step;
  final String title;
  final String body;
  final Color color;
  final bool isLast;

  const _StepRow({
    required this.step,
    required this.title,
    required this.body,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Center(
                child: Text(step,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  width: 1.5,
                  color: AppTheme.divider,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
              ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(body,
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Comparison Card ───────────────────────────────────────────────────────────
class _ComparisonCard extends StatelessWidget {
  final AppState state;
  const _ComparisonCard({required this.state});

  double? _minHpcTime() {
    final r = state.result;
    final times = [r.openmpTime, r.mpiTime, r.cudaTime]
        .where((t) => t != null)
        .cast<double>()
        .toList();
    if (times.isEmpty) return null;
    return times.reduce((a, b) => a < b ? a : b);
  }

  double _maxTime() {
    final r = state.result;
    final times = [
      r.pythonTime,
      r.openmpTime,
      r.mpiTime,
      r.cudaTime,
      r.aiHybridTime,
    ].where((t) => t != null).cast<double>().toList();
    if (times.isEmpty) return 1;
    return times.reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final r = state.result;
    final maxTime = _maxTime();

    final rows = [
      ('Python CG', r.pythonTime, AppTheme.primary),
      ('Best HPC', _minHpcTime(), AppTheme.success),
      ('AI Hybrid', r.aiHybridTime, AppTheme.secondary),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'AI vs HPC Comparison'),
            const SizedBox(height: 14),
            ...rows.map((row) {
              final label = row.$1;
              final time = row.$2;
              final color = row.$3;
              final barVal =
                  (time != null && maxTime > 0) ? (time / maxTime) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(label,
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(
                        time != null ? '${time.toStringAsFixed(3)} s' : '—',
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 12),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: barVal.toDouble(),
                          backgroundColor: AppTheme.bgCardLight,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
