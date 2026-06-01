class SolverResult {
  final double? pythonTime;
  final double? openmpTime;
  final double? mpiTime;
  final double? cudaTime;
  final double? aiHybridTime;
  final int? pythonIterations;
  final int? openmpIterations;
  final int? mpiIterations;
  final int? cudaIterations;
  final double? pythonResidual;
  final double? openmpResidual;
  final double? mpiResidual;
  final double? cudaResidual;
  final String? aiCheckpoint;
  final int? aiStartIteration;
  final double? aiResidual;
  final String status;
  final String? error;
  final Map<String, dynamic>? raw;

  SolverResult({
    this.pythonTime,
    this.openmpTime,
    this.mpiTime,
    this.cudaTime,
    this.aiHybridTime,
    this.pythonIterations,
    this.openmpIterations,
    this.mpiIterations,
    this.cudaIterations,
    this.pythonResidual,
    this.openmpResidual,
    this.mpiResidual,
    this.cudaResidual,
    this.aiCheckpoint,
    this.aiStartIteration,
    this.aiResidual,
    this.status = 'idle',
    this.error,
    this.raw,
  });

  factory SolverResult.fromJson(Map<String, dynamic> json) {
    return SolverResult(
      pythonTime: (json['python_time'] as num?)?.toDouble(),
      openmpTime: (json['openmp_time'] as num?)?.toDouble(),
      mpiTime: (json['mpi_time'] as num?)?.toDouble(),
      cudaTime: (json['cuda_time'] as num?)?.toDouble(),
      aiHybridTime: (json['ai_hybrid_time'] as num?)?.toDouble(),
      pythonIterations: json['python_iterations'] as int?,
      openmpIterations: json['openmp_iterations'] as int?,
      mpiIterations: json['mpi_iterations'] as int?,
      cudaIterations: json['cuda_iterations'] as int?,
      pythonResidual: (json['python_residual'] as num?)?.toDouble(),
      openmpResidual: (json['openmp_residual'] as num?)?.toDouble(),
      mpiResidual: (json['mpi_residual'] as num?)?.toDouble(),
      cudaResidual: (json['cuda_residual'] as num?)?.toDouble(),
      aiCheckpoint: json['ai_checkpoint'] as String?,
      aiStartIteration: json['ai_start_iteration'] as int?,
      aiResidual: (json['ai_residual'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'completed',
      error: json['error'] as String?,
      raw: json,
    );
  }

  static SolverResult empty() => SolverResult(status: 'idle');
}

class PipelineStatus {
  final bool isRunning;
  final String message;
  final double progress;

  PipelineStatus({
    this.isRunning = false,
    this.message = '',
    this.progress = 0.0,
  });
}
