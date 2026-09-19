import 'package:flutter_test/flutter_test.dart';

import 'package:local_llama/main.dart';

void main() {
  testWidgets('Local Llama app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const LocalLlamaApp());

    expect(find.text('Local Llama'), findsOneWidget);
  });
}
