import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jeep_app/main.dart';

void main() {
  testWidgets('renders jeep home dashboard', (tester) async {
    final repository = JeepRepository();
    repository.data = JeepData.sample().normalized();

    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Karta vozu'), findsOneWidget);
    expect(find.text('SERVIS'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
