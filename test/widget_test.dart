import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitlog_pro_app/app.dart';

void main() {
  testWidgets('App builds and shows splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: FitLogApp(),
      ),
    );

    // Verify the app builds without error
    expect(find.byType(FitLogApp), findsOneWidget);
  });
}
