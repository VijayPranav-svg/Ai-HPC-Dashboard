import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  bool _testing = false;
  bool? _testResult;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiService.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() { _testing = true; _testResult = null; });
    ApiService.setBaseUrl(_urlController.text.trim());
    final ok = await ApiService.ping();
    setState(() { _testing = false; _testResult = ok; });
    if (mounted) context.read<AppState>().checkBackend();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Backend config
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionHeader(
                    title: 'Backend URL',
                    subtitle: 'WSL Flask server address'),
                const SizedBox(height: 14),
                TextField(
                  controller: _urlController,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'http://172.x.x.x:5000',
                    hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    filled: true,
                    fillColor: AppTheme.bgCardLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  GlowButton(
                    label: _testing ? 'Testing...' : 'Test Connection',
                    icon: Icons.wifi_tethering,
                    loading: _testing,
                    onPressed: _testConnection,
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      _testResult! ? Icons.check_circle : Icons.cancel,
                      color: _testResult! ? AppTheme.success : AppTheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _testResult! ? 'Connected!' : 'Failed',
                      style: TextStyle(
                          color: _testResult! ? AppTheme.success : AppTheme.error,
                          fontSize: 12),
                    ),
                  ],
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Theme toggle
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Icon(Icons.dark_mode, color: AppTheme.primary, size: 20),
                const SizedBox(width: 12),
                const Expanded(child: Text('Dark Mode', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14))),
                Switch(
                  value: state.isDark,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (_) => context.read<AppState>().toggleTheme(),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // WSL Setup Guide
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionHeader(title: 'WSL Setup Guide', subtitle: 'How to connect from Android'),
                const SizedBox(height: 14),
                _guideStep('1', 'Find your WSL IP',
                    'In PowerShell, run:\nwsl hostname -I\nCopy the first IP address.'),
                _guideStep('2', 'Start the Flask backend',
                    'In WSL terminal:\ncd /path/to/your/project\npython backend.py'),
                _guideStep('3', 'Set the URL above',
                    'Enter: http://<WSL-IP>:5000\nand tap Test Connection.'),
                _guideStep('4', 'For physical Android device',
                    'Make sure your phone and PC are on the same WiFi network. Use your PC\'s LAN IP instead of WSL IP.', isLast: true),
              ]),
            ),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _guideStep(String step, String title, String body, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
          ),
          child: Center(
            child: Text(step, style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(body, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.5)),
        ])),
      ]),
    );
  }
}
