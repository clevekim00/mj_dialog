import 'package:flutter_test/flutter_test.dart';
import 'package:mj_dialog/main.dart';

void main() {
  testWidgets('renders the chat experience shell', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Gemma AI Coach'), findsOneWidget);
    expect(find.text('메시지를 입력하세요...'), findsOneWidget);
  });
}
