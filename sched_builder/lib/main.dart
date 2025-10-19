import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'providers/event_provider.dart';
import 'screens/calendar_screen.dart';
import 'screens/event_screen.dart'; // <-- 1. UPDATED IMPORT
import 'screens/settings_screen.dart';

void main() {
  tz_data.initializeTimeZones();
  runApp(const MyApp());
}

/// Google Sign-In setup
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'https://www.googleapis.com/auth/calendar',
  ],
);

final storage = const FlutterSecureStorage();

Future<String?> signInAndGetToken() async {
  try {
    final account = await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (account == null) return null; // user canceled sign-in
    final auth = await account.authentication;
    await storage.write(key: 'access_token', value: auth.accessToken);
    return auth.accessToken;
  } catch (e) {
    print('Sign-in error: $e');
    return null;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schedule App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider(
        create: (_) => EventProvider(),
        child: const AuthGate(),
      ),
    );
  }
}

/// Handles sign-in before showing main screens
class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _authenticateUser();
  }

  Future<void> _authenticateUser() async {
  String? token = await storage.read(key: 'access_token');
  
  // If no token is stored or the stored token might be expired, sign in
  if (token == null) {
    token = await signInAndGetToken();
  } else {
    // OPTIONAL: A more robust solution would be to implement token refresh
    // For now, let's try using the stored token, but your EventProvider 
    // should handle the 'invalid_token' error by prompting re-auth.
    // However, to fix the IMMEDIATE issue of a stale token from secure storage:
    
    // We will rely on signInSilently() in signInAndGetToken to refresh if needed.
    // Call signInAndGetToken() to attempt to sign in silently and get a fresh token.
    // signInAndGetToken() will try to use the existing credentials to get a new token.
    token = await signInAndGetToken();
  }

  if (token != null && mounted) {
    context.read<EventProvider>().setAccessToken(token);
    setState(() => _loading = false);
  } else if (mounted) {
    setState(() => _loading = false); // Stop loading even if sign-in fails
    
    // If sign-in failed, clear any stale token to force a full sign-in next time
    await storage.delete(key: 'access_token'); 
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Sign-In failed or was cancelled.')),
    );
    // You might want to show a Sign-In button here instead of HomeScreen
  }
}

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const HomeScreen();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // --- 2. ADD SCREEN TO THE LIST ---
  final List<Widget> _screens = [
    const CalendarScreen(),
    const EventsScreen(), // Using the correct screen name
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        // Adding type makes unselected items visible and keeps their color
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          // --- 3. ADD NEW TAB ITEM ---
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_calendar_outlined),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}