import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../widgets/stats_panel.dart';
import '../widgets/audio_player.dart';
import '../widgets/loading_indicator.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({Key? key}) : super(key: key);

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EventProvider>();
      provider.fetchBriefing(provider.selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventProvider>(
      builder: (context, provider, _) {
        return LoadingIndicator(
          isLoading: provider.isLoading,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Summary'),
              elevation: 0,
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Stats panel
                  if (provider.stats != null)
                    StatsPanel(stats: provider.stats!),

                  // Audio briefing
                  if (provider.briefing != null)
                    AudioPlayer(),

                  // Error message
                  if (provider.error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        provider.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}