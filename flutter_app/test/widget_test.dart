// Smoke test básico de FinPareja.
//
// Verifica que la app arranca y muestra la pantalla de splash mientras
// el AuthNotifier resuelve el estado de sesión.
import 'package:flutter_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App arranca y muestra el splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();

    // El splash muestra el nombre de la app
    expect(find.text('FinPareja'), findsOneWidget);
  });
}
