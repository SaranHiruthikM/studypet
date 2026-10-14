import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studypet/app.dart';
import 'package:studypet/providers.dart';

void main() {
  testWidgets('renders the StudyPet home dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefsProvider.overrideWithValue(prefs)],
        child: const StudyPetApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ready to grow?'), findsOneWidget);
    expect(find.text('Start studying'), findsOneWidget);
  });
}
