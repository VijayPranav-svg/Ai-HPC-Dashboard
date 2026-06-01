import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class GraphsScreen extends StatefulWidget {
  const GraphsScreen({super.key});

  @override
  State<GraphsScreen> createState() => _GraphsScreenState();
}

class _GraphsScreenState extends State<GraphsScreen> {
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
    final imageNames = state.imageList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            Expanded(
              child: SectionHeader(
                title: 'Result Graphs',
                subtitle: '${imageNames.length} plot(s) from last run',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
              onPressed: () => context.read<AppState>().fetchResults(),
            ),
          ]),
        ),

        // Body
        Expanded(
          child: imageNames.isEmpty
              ? const _EmptyGraphs()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: imageNames.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final filename = imageNames[index];
                    final title = filename
                        .replaceAll('.png', '')
                        .replaceAll('.jpg', '')
                        .replaceAll('_', ' ')
                        .split(' ')
                        .map((w) => w.isEmpty
                            ? ''
                            : w[0].toUpperCase() + w.substring(1))
                        .join(' ');
                    return _GraphCard(
                      filename: filename,
                      title: title,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _GraphCard extends StatelessWidget {
  final String filename;
  final String title;

  const _GraphCard({required this.filename, required this.title});

  @override
  Widget build(BuildContext context) {
    final url = ApiService.getImageUrl(filename);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(children: [
              const Icon(Icons.bar_chart, color: AppTheme.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                filename,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10),
              ),
            ]),
          ),

          // Image with fixed height
          GestureDetector(
            onTap: () => _openFullScreen(context, url, title),
            child: Container(
              height: 240,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.bgCardLight,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                            color: AppTheme.primary,
                            strokeWidth: 2,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Loading graph...',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image_outlined,
                              color: AppTheme.textSecondary, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'Could not load image',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            url,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 9),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Tap to zoom hint
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Row(children: const [
              Icon(Icons.zoom_in, color: AppTheme.textSecondary, size: 12),
              SizedBox(width: 4),
              Text(
                'Tap image to zoom',
                style:
                    TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  void _openFullScreen(BuildContext context, String url, String title) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullScreenImage(url: url, title: title),
    ));
  }
}

class _FullScreenImage extends StatelessWidget {
  final String url;
  final String title;

  const _FullScreenImage({required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(url),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined,
                  color: Colors.white54, size: 60),
              SizedBox(height: 12),
              Text('Could not load image',
                  style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGraphs extends StatelessWidget {
  const _EmptyGraphs();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.divider),
            ),
            child: const Icon(Icons.image_not_supported_outlined,
                color: AppTheme.textSecondary, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('No Graphs Yet',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text(
            'Run the full pipeline to generate graphs.',
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<AppState>().fetchResults(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
