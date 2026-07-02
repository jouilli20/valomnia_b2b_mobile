import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:valomnia_b2b_mobile/main.dart';

void main() {
  testWidgets('renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.text('Valomnia B2B'), findsOneWidget);
    expect(find.text('Bon retour'), findsNothing);
    expect(find.text('Écran de connexion'), findsNothing);
    expect(find.text('Votre Organisation'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('71 204 542'), findsOneWidget);
  });
}
