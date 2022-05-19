import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_flutter/pocket/main.dart';
import 'package:hello_flutter/pocket/time.dart';
import 'package:hello_flutter/pocket/diary.dart' as diary;

void main() {
  group("Basic Usage Test", () {
    testWidgets('Page Switch Test', (WidgetTester tester) async {
      await tester.pumpWidget(CMPocket.call());

      expect(find.text('我的一天'), findsOneWidget);
      expect(find.text(TimeUtil.todayShort()), findsOneWidget);

      await tester.tap(find.byIcon(Icons.sticky_note_2_outlined));
      await tester.pump();

      expect(find.byIcon((diary.mainButton as Icon).icon!), findsOneWidget);
    });
  });
}
