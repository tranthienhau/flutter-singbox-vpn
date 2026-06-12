import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_singbox_vpn/features/vpn/vpn_screen.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shoot(WidgetTester tester, String name) async {
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  testWidgets('capture sing-box vpn flow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const VpnScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await shoot(tester, '01-disconnected');

    // Open the server picker to reveal the available exit locations.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await shoot(tester, '02-server-picker');

    // Dismiss the dropdown by selecting a different server.
    await tester.tap(find.text('Germany - Frankfurt').last);
    await tester.pumpAndSettle();

    // Toggle the kill switch off to show the policy controls interacting.
    await tester.tap(find.text('Kill switch'));
    await tester.pumpAndSettle();
    await shoot(tester, '03-policy-controls');
  });
}
