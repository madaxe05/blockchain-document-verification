import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';

void main() {
  group('BlockchainDocumentApp Widget Tests', () {
    testWidgets('Shows Login screen when user is NOT logged in', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const BlockchainDocumentApp(isLoggedIn: false));

      // Let all widgets settle
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);

      // Ensure home content is NOT visible
      expect(find.text('Local Blockchain Vault'), findsNothing);
    });

    testWidgets('Shows Home screen when user IS logged in', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const BlockchainDocumentApp(isLoggedIn: true));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Local Blockchain Vault'), findsOneWidget);

      // Login UI should not be visible
      expect(find.text('Welcome Back'), findsNothing);
    });
  });
}
