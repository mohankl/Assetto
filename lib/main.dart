import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/assets_screen.dart';
import 'screens/tenants_screen.dart';
import 'screens/transactions_screen.dart';
import 'providers/firebase_provider.dart';

void main() async {
  try {
    developer.log('Starting app initialization...');

    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();
    developer.log('Flutter bindings initialized');

    // Initialize Firebase
    try {
      developer.log('Starting Firebase initialization...');
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyA5Xxjg1PeuH2noYmgOWSi85Rr0nzkldfY',
          appId: '1:184273620099:android:1f425a1374733bc058dfb6',
          messagingSenderId: '184273620099',
          projectId: 'assetto-7cad8',
          storageBucket: 'assetto-7cad8.firebasestorage.app',
        ),
      );
      developer.log('Firebase initialized successfully');

      // Set the database URL after Firebase is initialized
      FirebaseDatabase.instance.databaseURL =
          'https://assetto-7cad8-default-rtdb.asia-southeast1.firebasedatabase.app';
      developer.log('Database URL set successfully');

      // Test database connection
      try {
        developer.log('Testing database connection...');
        final ref = FirebaseDatabase.instance.ref();
        await ref.child('.info/connected').get();
        developer.log('Database connection successful');
      } catch (e, stackTrace) {
        developer.log('Database connection failed: $e\n$stackTrace');
        runApp(const ErrorApp(error: 'Failed to connect to database'));
        return;
      }
    } catch (e, stackTrace) {
      developer.log('Firebase initialization failed: $e\n$stackTrace');
      runApp(ErrorApp(error: 'Failed to initialize Firebase: $e'));
      return;
    }

    developer.log('Starting app...');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    developer.log('Critical error during initialization: $e\n$stackTrace');
    runApp(ErrorApp(error: 'Critical error: $e'));
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    developer.log('Building MyApp...');
    return ChangeNotifierProvider(
      create: (context) {
        developer.log('Creating FirebaseProvider...');
        final provider = FirebaseProvider();
        provider.initialize().catchError((e, stackTrace) {
          developer.log('Error initializing FirebaseProvider: $e\n$stackTrace');
        });
        return provider;
      },
      child: MaterialApp(
        title: 'Assetto - Property Management',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AssetsScreen(),
    const TenantsScreen(),
    const TransactionsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    developer.log('MainScreen initialized');
  }

  void _onItemTapped(int index) {
    developer.log('Navigation item tapped: $index');
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    developer.log('Building MainScreen with selected index: $_selectedIndex');
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(Icons.home), label: 'Assets'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Tenants'),
          NavigationDestination(
            icon: Icon(Icons.payments),
            label: 'Transactions',
          ),
        ],
      ),
    );
  }
}
