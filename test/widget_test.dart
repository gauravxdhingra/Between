import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:between/main.dart';

void main() {
  testWidgets('renders app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SettleApp()));
    await tester.pumpAndSettle();

    expect(find.text('Between'), findsOneWidget);
  });
}
