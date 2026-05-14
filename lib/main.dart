import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/vpn/vpn_screen.dart';

void main() {
  runApp(const ProviderScope(child: SingboxVpnApp()));
}

class SingboxVpnApp extends StatelessWidget {
  const SingboxVpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sing-box VPN',
      theme: ThemeData.dark(useMaterial3: true),
      home: const VpnScreen(),
    );
  }
}
