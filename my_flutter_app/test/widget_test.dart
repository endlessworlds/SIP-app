import 'package:flutter_test/flutter_test.dart';

import 'package:my_flutter_app/app.dart';

void main() {
  testWidgets('SIP app loads dialpad screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SipApp());

    expect(find.text('Dialpad'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
  });
}
