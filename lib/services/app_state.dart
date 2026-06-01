import 'package:flutter/material.dart';
import '../models/solver_result.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  SolverResult _result = SolverResult.empty();
  bool _isRunning = false;
  bool _isDark = true;
  String _statusMessage = '';
  double _progress = 0.0;
  bool _backendAlive = false;
  List<String> _imageList = [];
  String _errorMessage = '';

  SolverResult get result => _result;
  bool get isRunning => _isRunning;
  bool get isDark => _isDark;
  String get statusMessage => _statusMessage;
  double get progress => _progress;
  bool get backendAlive => _backendAlive;
  List<String> get imageList => _imageList;
  String get errorMessage => _errorMessage;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  Future<void> checkBackend() async {
    _backendAlive = await ApiService.ping();
    notifyListeners();
  }

  Future<void> fetchResults() async {
    try {
      _result = await ApiService.getResults();
      _imageList = await ApiService.getImageList();
      _errorMessage = '';
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> runPipeline() async {
    if (_isRunning) return;

    _isRunning = true;
    _progress = 0.0;
    _statusMessage = 'Initializing pipeline...';
    _errorMessage = '';
    notifyListeners();

    try {
      // Simulate progress messages while waiting
      final progressSteps = [
        (0.1, 'Running Python CG Solver...'),
        (0.3, 'Running OpenMP Solver...'),
        (0.5, 'Running MPI Solver...'),
        (0.7, 'Running CUDA Solver...'),
        (0.85, 'Running AI Hybrid Solver...'),
        (0.95, 'Generating graphs...'),
      ];

      int stepIdx = 0;
      final ticker = Stream.periodic(const Duration(seconds: 3), (i) => i);
      final sub = ticker.listen((_) {
        if (stepIdx < progressSteps.length) {
          _progress = progressSteps[stepIdx].$1;
          _statusMessage = progressSteps[stepIdx].$2;
          stepIdx++;
          notifyListeners();
        }
      });

      final data = await ApiService.runPipeline();
      await sub.cancel();

      _progress = 1.0;
      _statusMessage = 'Pipeline completed!';

      if (data['status'] == 'success' || data['status'] == 'completed') {
        _result = SolverResult.fromJson(data);
        _imageList = await ApiService.getImageList();
      } else {
        _errorMessage = data['error']?.toString() ?? 'Unknown error';
      }
    } catch (e) {
      _errorMessage = e.toString();
      _statusMessage = 'Pipeline failed';
    } finally {
      _isRunning = false;
      notifyListeners();
    }
  }

  Future<void> runModule(String module) async {
    if (_isRunning) return;
    _isRunning = true;
    _statusMessage = 'Running $module...';
    _errorMessage = '';
    notifyListeners();

    try {
      final data = await ApiService.runModule(module);
      _result = SolverResult.fromJson({
        ..._result.raw ?? {},
        ...data,
      });
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isRunning = false;
      _statusMessage = '';
      notifyListeners();
    }
  }
}
