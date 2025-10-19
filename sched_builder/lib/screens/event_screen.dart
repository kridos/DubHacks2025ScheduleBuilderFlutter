import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // For BackdropFilter
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../models/event.dart'; // Make sure your Event model allows null for optional fields

// --- Light Gradient Background Colors ---
const Color kBgGradientTop = Color(0xFFF0ECFF); // very light purple
const Color kBgGradientBottom = Color(0xFFFDE6F3); // very light pink/lavender
const Color kGradientStart = Color(0xFF7250E8);
const Color kGradientEnd = Color(0xFFE1306C);

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventsScreen> with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final TextEditingController _quickEventController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  late AnimationController _shakeController;
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat();

    _gradientController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EventProvider>().fetchEventsForDate(DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quickEventController.dispose();
    _shakeController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventProvider = context.watch<EventProvider>();
    final events = eventProvider.events;
    final isLoading = eventProvider.isLoading;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Light vertical gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kBgGradientTop, kBgGradientBottom],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- UNIFIED SCHEDULE CARD ---
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Today's Events Header with Animated Gradient Background ---
                          Transform.translate(
                            offset: const Offset(0, -1.5),
                            child: Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFDE6F3),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20.0),
                                  topRight: Radius.circular(20.0),
                                ),
                              ),
                              padding: const EdgeInsets.only(
                                left: 1.5,
                                right: 1.5,
                                top: 17.5,
                                bottom: 16,
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: -0),
                              child: Center(
                                child: AnimatedBuilder(
                                animation: _gradientController,
                                builder: (context, child) {
                                  return ShaderMask(
                                    shaderCallback: (bounds) {
                                      final progress = _gradientController.value;
                                      final mappedProgress = progress * 2.0 - 0.5;
                                      return LinearGradient(
                                        colors: [
                                          kGradientStart,
                                          kGradientEnd,
                                          kGradientStart
                                        ],
                                        stops: [
                                          mappedProgress - 0.5,
                                          mappedProgress,
                                          mappedProgress + 0.5,
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ).createShader(bounds);
                                    },
                                    child: Text(
                                      'Today\'s Events',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: isLoading
                                    ? const Center(
                                        key: ValueKey('loading'),
                                        child: CircularProgressIndicator(),
                                      )
                                    : events.isEmpty
                                        ? _buildEmptyState(theme)
                                        : _buildEventsList(theme, events),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
  
            // --- Bouncing Daily Briefing Button OVERLAY ---
            Positioned(
              bottom: 24,
              right: 24,
              child: AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  double offset = 0.0;
                  final progress = _shakeController.value;
                  if (progress < 0.35) {
                    offset = Tween<double>(begin: 0.0, end: -8.0)
                        .evaluate(CurvedAnimation(
                            parent: AlwaysStoppedAnimation(progress / 0.35),
                            curve: Curves.easeInOutCubic));
                  } else if (progress < 0.65) {
                    offset = Tween<double>(begin: -8.0, end: 0.0)
                        .evaluate(CurvedAnimation(
                            parent: AlwaysStoppedAnimation((progress - 0.35) / 0.3),
                            curve: Curves.easeInOutCubic));
                  }
                  return Transform.translate(
                    offset: Offset(0, offset),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7250E8), Color(0xFFE1306C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: FloatingActionButton(
                          heroTag: 'briefingBtnEvents',
                          onPressed: () {
                            context.read<EventProvider>().fetchBriefing(_selectedDate);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Loading daily briefing...')),
                            );
                          },
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          child: const Icon(Icons.speaker, color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Reusable Glass Card ---
  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // --- Helper: Empty State ---
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      key: const ValueKey('empty'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          children: [
            Icon(Icons.celebration_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('You\'re all clear! ✨',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('No events scheduled.', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // --- Helper: Events List ---
  Widget _buildEventsList(ThemeData theme, List<Event> events) {
    return ListView.builder(
      key: const ValueKey('list'),
      itemCount: events.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final event = events[index];
        final formattedDate = DateFormat('EEE, MMM d').format(event.startTime);
        final descriptionText = event.description ?? '';

        final Widget leadingWidget = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('h:mm').format(event.startTime),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              DateFormat('a').format(event.startTime),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 10.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          shadowColor: theme.colorScheme.primary.withOpacity(0.1),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            leading: leadingWidget,
            title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                '${descriptionText.isEmpty ? '' : '$descriptionText · '} $formattedDate'),
            onTap: () {
              // Handle event tap
            },
          ),
        );
      },
    );
  }
}