import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'crypto/provider_neutral_boundary.dart';

void main() {
  runApp(const ProviderScope(child: GuffSuffApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DevStatusScreen(),
    ),
  ],
);

class GuffSuffApp extends StatelessWidget {
  const GuffSuffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GuffSuff',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF003399),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003399)),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      routerConfig: _router,
    );
  }
}

class DevStatusScreen extends StatelessWidget {
  const DevStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const MobileCryptoProvider activeProvider = UnavailableCryptoProvider();
    final bool isProviderAvailable = activeProvider.isAvailable;

    return Scaffold(
      appBar: AppBar(title: const Text('GuffSuff Secure Boundary')),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.security_rounded,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'GuffSuff Secure Messaging',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Secure messaging is not available in this build.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: isProviderAvailable ? () {} : null,
                        icon: const Icon(Icons.send),
                        label: const Text('Send Message'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: isProviderAvailable ? () {} : null,
                        icon: const Icon(Icons.group_add),
                        label: const Text('Create E2EE Group'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.red.shade800,
              padding: const EdgeInsets.all(12),
              child: const Text(
                'SECURE MESSAGING PROVIDER UNAVAILABLE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
