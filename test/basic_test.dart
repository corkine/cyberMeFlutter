import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_flutter/pocket/config.dart';
import 'package:hello_flutter/pocket/main.dart';
import 'package:hello_flutter/pocket/time.dart';
import 'package:hello_flutter/pocket/diary.dart' as diary;
import 'package:hello_flutter/pocket/dashboard.dart' as dash;
import 'package:provider/provider.dart';

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

  group("Dashboard Test", () {
    testWidgets('Dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
          create: (c) => Config(),
          child: const MaterialApp(home: dash.DashHome())));
          
      //TODO: Find a way to mock http request
      //await tester.pump(const Duration(seconds: 1));

      //expect(find.byWidget(const CircularProgressIndicator(), skipOffstage: false), findsOneWidget);
      expect(find.text("正在联系服务器"), findsOneWidget);
      //expect(find.text(TimeUtil.time), findsOneWidget);
    });
  });
}
