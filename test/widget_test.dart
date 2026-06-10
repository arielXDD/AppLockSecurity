import 'package:app_hider/app.dart';
import 'package:app_hider/providers/apps_provider.dart';
import 'package:app_hider/providers/auth_provider.dart';
import 'package:app_hider/providers/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows calculator disguise', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AppsProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const BovedaApp(),
      ),
    );

    expect(find.text('AC'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
  });
}
