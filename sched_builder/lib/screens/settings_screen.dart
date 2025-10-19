import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../providers/event_provider.dart';

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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  late String _selectedTimeZone;
  late AnimationController _gradientController;

  // List of common time zones
  final List<String> _timeZones = [
    'Etc/GMT+12',
    'Pacific/Midway',
    'Pacific/Honolulu',
    'America/Anchorage',
    'America/Los_Angeles',
    'America/Denver',
    'America/Chicago',
    'America/New_York',
    'America/Toronto',
    'America/St_Johns',
    'America/Argentina/Buenos_Aires',
    'Atlantic/Azores',
    'UTC',
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'Africa/Cairo',
    'Asia/Amman',
    'Asia/Dubai',
    'Asia/Kolkata',
    'Asia/Bangkok',
    'Asia/Hong_Kong',
    'Asia/Shanghai',
    'Asia/Tokyo',
    'Australia/Sydney',
    'Pacific/Auckland',
    'Pacific/Fiji',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTimeZone = context.read<EventProvider>().selectedTimeZone;
    _gradientController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    // Listen for timezone changes from the provider
    context.read<EventProvider>().addListener(_onTimeZoneChanged);
  }

  void _onTimeZoneChanged() {
    final newTimeZone = context.read<EventProvider>().selectedTimeZone;
    if (_selectedTimeZone != newTimeZone) {
      setState(() {
        _selectedTimeZone = newTimeZone;
      });
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    context.read<EventProvider>().removeListener(_onTimeZoneChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                final progress = _gradientController.value;
                // Map progress to range -0.5 to 1.5 so gradient travels smoothly
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
                'Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFFDE6F3),
        centerTitle: true,
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Time Zone Section Header ---
                  Text(
                    'Time Zone',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select your time zone to display events and schedules correctly.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // --- Time Zone Dropdown ---
                  Consumer<EventProvider>(
                    builder: (context, provider, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: kSurfaceWhite,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(color: kPrimaryPurple.withOpacity(0.2)),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: provider.selectedTimeZone,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: kPrimaryPurple,
                            size: 30,
                          ),
                          elevation: 4,
                          style: TextStyle(
                            color: kTextColor,
                            fontSize: 16,
                          ),
                          underline: const SizedBox.shrink(),
                          dropdownColor: kSurfaceWhite,
                          items: _timeZones.map((timeZone) {
                            return DropdownMenuItem<String>(
                              value: timeZone,
                              child: Text(
                                timeZone,
                                style: TextStyle(
                                  color: kTextColor,
                                  fontWeight: timeZone == provider.selectedTimeZone ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newTimeZone) {
                            if (newTimeZone != null) {
                              context.read<EventProvider>().setTimeZone(newTimeZone);
                            }
                          },
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // --- Current Time Zone Info Card ---
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [kGradientStart, kGradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kSurfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Current Time Zone Info',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Consumer<EventProvider>(
                            builder: (context, provider, _) {
                              final formatter = DateFormat('h:mm a');
                              try {
                                final location = tz.getLocation(provider.selectedTimeZone);
                                final now = tz.TZDateTime.now(location);
                                final formattedTime = formatter.format(now);
                                
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Selected: ${provider.selectedTimeZone}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: kTextColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    ShaderMask(
                                      shaderCallback: (bounds) => LinearGradient(
                                        colors: [kGradientStart, kGradientEnd],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                      child: Text(
                                        formattedTime,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Local Time',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                );
                              } catch (e) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Selected: ${provider.selectedTimeZone}',
                                      style: TextStyle(fontSize: 14, color: kTextColor),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Unable to load',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.red,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}