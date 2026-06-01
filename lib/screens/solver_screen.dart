import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

// Solver metadata
class SolverConfig {
  final String name;
  final String module;
  final String description;
  final String details;
  final Color color;
  final IconData icon;
  final List<String> features;

  const SolverConfig({
    required this.name,
    required this.module,
    required this.description,
    required this.details,
    required this.color,
    required this.icon,
    required this.features,
  });
}

final solverConfigs = {
  'python': const SolverConfig(
    name: 'Python CG Solver',
    module: 'python',
    description: 'Pure Python Conjugate Gradient solver for the Poisson system.',
    details:
        'The Conjugate Gradient (CG) method is an iterative algorithm for solving symmetric positive-definite linear systems Ax = b. '
        'This Python implementation serves as the baseline reference with no hardware acceleration, '
        'making it ideal for correctness verification and algorithm validation.',
    color: AppTheme.primary,
    icon: Icons.code,
    features: [
      'Reference implementation',
      'Numpy-based matrix ops',
      'Residual convergence tracking',
      'Easy to debug and profile',
    ],
  ),
  'openmp': const SolverConfig(
    name: 'OpenMP Solver',
    module: 'openmp',
    description: 'Shared-memory parallel solver using OpenMP threads.',
    details:
        'OpenMP (Open Multi-Processing) enables shared-memory parallelism via compiler directives. '
        'The C implementation distributes inner loop operations across all available CPU cores '
        'on a single node, dramatically reducing wall-clock time for large grids.',
    color: AppTheme.success,
    icon: Icons.speed,
    features: [
      'Pragma-based parallelism',
      'NUMA-aware memory layout',
      'Thread-safe reductions',
      'Auto-tuned thread count',
    ],
  ),
  'mpi': const SolverConfig(
    name: 'MPI Solver',
    module: 'mpi',
    description: 'Distributed-memory solver using MPI message passing.',
    details:
        'MPI (Message Passing Interface) distributes the Poisson grid across multiple processes, '
        'each owning a subdomain. Halo exchanges synchronize boundary values between neighbors. '
        'This scales to multiple nodes and is the backbone of modern HPC clusters.',
    color: AppTheme.warning,
    icon: Icons.device_hub,
    features: [
      'Domain decomposition',
      'Halo ghost cell exchange',
      'Non-blocking communication',
      'Multi-node scalability',
    ],
  ),
  'cuda': const SolverConfig(
    name: 'CUDA Solver',
    module: 'cuda',
    description: 'GPU-accelerated solver leveraging NVIDIA CUDA cores.',
    details:
        'CUDA maps the Poisson grid to GPU threads, exploiting thousands of cores for massive '
        'data parallelism. Sparse matrix-vector products and dot products are executed on-device, '
        'with cuSPARSE and cuBLAS primitives for peak throughput.',
    color: AppTheme.secondary,
    icon: Icons.grid_on,
    features: [
      'cuSPARSE SpMV',
      'cuBLAS dot products',
      'Unified Memory support',
      'Multi-GPU capable',
    ],
  ),
};

class SolverScreen extends StatelessWidget {
  final String solverKey;

  const SolverScreen({super.key, required this.solverKey});

  @override
  Widget build(BuildContext context) {
    final config = solverConfigs[solverKey]!;
    final state = context.watch<AppState>();
    final result = state.result;

    double? time;
    int? iterations;
    double? residual;

    switch (solverKey) {
      case 'python':
        time = result.pythonTime;
        iterations = result.pythonIterations;
        residual = result.pythonResidual;
        break;
      case 'openmp':
        time = result.openmpTime;
        iterations = result.openmpIterations;
        residual = result.openmpResidual;
        break;
      case 'mpi':
        time = result.mpiTime;
        iterations = result.mpiIterations;
        residual = result.mpiResidual;
        break;
      case 'cuda':
        time = result.cudaTime;
        iterations = result.cudaIterations;
        residual = result.cudaResidual;
        break;
    }

    final status = result.status == 'idle'
        ? 'not_run'
        : time != null
            ? 'completed'
            : 'not_run';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                config.color.withOpacity(0.15),
                AppTheme.bgCard,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: config.color.withOpacity(0.3)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: config.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(config.icon, color: config.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(config.name,
                  style: TextStyle(color: config.color, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(config.description,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),

        // Status + Run button
        Row(children: [
          StatusBadge(status: status),
          const Spacer(),
          GlowButton(
            label: 'Re-run',
            icon: Icons.play_arrow,
            color: config.color,
            loading: state.isRunning,
            onPressed: () => context.read<AppState>().runModule(solverKey),
          ),
        ]),
        const SizedBox(height: 16),

        // Stats Cards
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.3,
          children: [
            StatCard(
              label: 'Time',
              value: time != null ? time.toStringAsFixed(3) : '—',
              unit: 's',
              color: config.color,
              icon: Icons.timer_outlined,
            ),
            StatCard(
              label: 'Iterations',
              value: iterations?.toString() ?? '—',
              color: config.color,
              icon: Icons.loop,
            ),
            StatCard(
              label: 'Residual',
              value: residual != null ? residual.toStringAsExponential(2) : '—',
              color: config.color,
              icon: Icons.show_chart,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Description Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionHeader(title: 'How it Works'),
              const SizedBox(height: 12),
              Text(config.details,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13, height: 1.6)),
            ]),
          ),
        ),
        const SizedBox(height: 12),

        // Features Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionHeader(title: 'Key Features'),
              const SizedBox(height: 12),
              ...config.features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, color: config.color),
                      ),
                      const SizedBox(width: 10),
                      Text(f,
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 13)),
                    ]),
                  )),
            ]),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}
