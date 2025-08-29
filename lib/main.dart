import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/network_scan_provider.dart';
import 'screens/scanner_screen.dart';

void main() {
  runApp(const NetworkScannerApp());
}

class NetworkScannerApp extends StatelessWidget {
  const NetworkScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NetworkScanProvider(),
      child: MaterialApp(
        title: 'Network Scanner',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        home: const ScannerScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
