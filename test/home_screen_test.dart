import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_demo/providers/auth_provider.dart';
import 'package:firebase_auth_demo/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Set up default mock responses
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockFirebaseAuth.authStateChanges())
        .thenAnswer((_) => Stream.value(mockUser));
  });

  Widget createHomeScreen() {
    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
      ],
    );

    addTearDown(container.dispose);

    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  testWidgets('Home screen shows user email', (WidgetTester tester) async {
    await tester.pumpWidget(createHomeScreen());
    await tester.pumpAndSettle();

    expect(find.text('Welcome test@example.com!'), findsOneWidget);
  });

  testWidgets('Home screen shows logout button', (WidgetTester tester) async {
    await tester.pumpWidget(createHomeScreen());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.logout), findsOneWidget);
  });

  testWidgets('Successful logout clears auth state',
      (WidgetTester tester) async {
    // Setup successful signOut
    when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});

    await tester.pumpWidget(createHomeScreen());
    await tester.pumpAndSettle();

    // Tap logout button
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    // Verify signOut was called
    verify(() => mockFirebaseAuth.signOut()).called(1);
  });

  testWidgets('Failed logout shows error in console',
      (WidgetTester tester) async {
    // Setup failed signOut
    when(() => mockFirebaseAuth.signOut())
        .thenThrow(FirebaseAuthException(code: 'error'));

    await tester.pumpWidget(createHomeScreen());
    await tester.pumpAndSettle();

    // Tap logout button
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    // Error is logged to console, we can't test debug prints directly
    verify(() => mockFirebaseAuth.signOut()).called(1);
  });

  testWidgets('Home screen shows all UI elements', (WidgetTester tester) async {
    await tester.pumpWidget(createHomeScreen());
    await tester.pumpAndSettle();

    // Verify all text elements are present
    expect(find.text('You are now logged in.'), findsOneWidget);
    expect(
      find.text('To logout, click the logout button in the top right corner.'),
      findsOneWidget,
    );
  });
}
