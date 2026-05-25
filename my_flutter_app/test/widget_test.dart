import 'package:flutter_test/flutter_test.dart';

import 'package:my_flutter_app/app.dart';

void main() {
  testWidgets('SIP app loads settings screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SipApp());

    expect(find.text('SIP Settings'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
  });
}
