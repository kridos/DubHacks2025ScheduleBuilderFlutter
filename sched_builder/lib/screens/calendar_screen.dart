import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:ui'; // Required for ImageFilter.blur
import 'dart:math'; // Required for sin and cos

import '../providers/event_provider.dart';
import '../widgets/loading_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../widgets/audio_recorder_button.dart';

// --- Color Palette ---
const Color kPrimaryPurple = Color(0xFF6A5AE0);
const Color kGradientStart = Color(0xFF7250E8);
const Color kGradientEnd = Color(0xFFE1306C);
const Color kSurfaceWhite = Colors.white;
const Color kBackgroundLavender = Color(0xFFF5F4FF);
final Color kTextColor = Colors.grey[800]!;

// --- Light Gradient Background Colors ---
const Color kBgGradientTop = Color(0xFFF0ECFF); // very light purple
const Color kBgGradientBottom = Color(0xFFFDE6F3); // very light pink/lavender

// --- Gradient Decoration ---
final BoxDecoration kGradientDecoration = BoxDecoration(
  gradient: LinearGradient(
    colors: [kGradientStart, kGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  borderRadius: BorderRadius.circular(32),
);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _circleController;
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EventProvider>().fetchEventsForDate(DateTime.now());
      }
    });
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat();

    _circleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _gradientController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _circleController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  // Pick image from gallery and upload
  Future<void> _pickAndUploadImage(EventProvider provider) async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      final XFile? image = await imagePicker.pickImage(source: ImageSource.gallery);
      
      if (image == null) return; // User cancelled
      
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading image...')),
      );
      
      await provider.uploadEventImage(image.path);
      
      if (mounted) {
        if (provider.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${provider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<EventProvider>(
      builder: (context, provider, _) {
        return LoadingIndicator(
          isLoading: provider.isLoading,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: AppBar(
                    backgroundColor: const Color(0xFFFDE6F3),
                    elevation: 0,
                    title: AnimatedBuilder(
                      animation: _gradientController,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            final progress = _gradientController.value;
                            final mappedProgress = progress * 2.0 - 0.5;
                            return LinearGradient(
                              colors: [kGradientStart, kGradientEnd, kGradientStart],
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
                            'Schedule',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                    centerTitle: true,
                  ),
                ),
              ),
            ),
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
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCalendar(provider, theme),
                      const SizedBox(height: 16),
                      // Quick Add by Typing
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 0),
                        child: Card(
                          color: kSurfaceWhite,
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Quick Add by Typing",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryPurple,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        style: TextStyle(color: kTextColor),
                                        decoration: InputDecoration(
                                          hintText: 'Type a new event...',
                                          border: const OutlineInputBorder(),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          hintStyle: TextStyle(color: kTextColor.withOpacity(0.6)),
                                        ),
                                        // TODO: Wire up controller and logic as needed
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: kGradientDecoration,
                                      child: IconButton(
                                        icon: const Icon(Icons.send, color: Colors.white),
                                        onPressed: () {}, // TODO: Wire up logic
                                        tooltip: 'Send Event',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Add by Voice and Daily Briefing Button Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Add by Voice Card (left)
                            Expanded(
                              flex: 3,
                              child: Card(
                                color: kSurfaceWhite,
                                elevation: 4,
                                shadowColor: Colors.black.withOpacity(0.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Add by Voice",
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: kPrimaryPurple,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: AudioRecorderButton(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Gradient Camera Button with circular animation
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4.0, right: 8.0, top: 36.0),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: AnimatedBuilder(
                                    animation: _circleController,
                                    builder: (context, child) {
                                      // Create circular motion
                                      final double radius = 4.0;
                                      final double angle = _circleController.value * 2 * 3.14159;
                                      final double dx = radius * cos(angle);
                                      final double dy = radius * sin(angle);
                                      
                                      return Transform.translate(
                                        offset: Offset(dx, dy),
                                        child: child,
                                      );
                                    },
                                    child: GestureDetector(
                                      onTap: () => _pickAndUploadImage(provider),
                                      child: Container(
                                        width: 70,
                                        height: 70,
                                        decoration: kGradientDecoration,
                                        alignment: Alignment.center,
                                        child: Icon(Icons.camera_alt, color: Colors.white, size: 36),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  
  /// Builds the TableCalendar widget with event markers.
  Widget _buildCalendar(EventProvider provider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2026, 12, 31),
        focusedDay: provider.selectedDate,
        selectedDayPredicate: (day) => isSameDay(day, provider.selectedDate),
        onDaySelected: (selectedDay, focusedDay) {
          provider.fetchEventsForDate(selectedDay);
        },
        headerStyle: HeaderStyle(
          titleCentered: true,
          titleTextStyle: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, color: kPrimaryPurple),
          formatButtonVisible: false,
        ),
        eventLoader: (day) => [],
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kGradientStart, kGradientEnd],
            ),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          todayDecoration: BoxDecoration(
            color: kPrimaryPurple.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(color: kPrimaryPurple, fontWeight: FontWeight.bold),
          markerDecoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}