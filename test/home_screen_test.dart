import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_demo/screens/home_screen.dart';
import 'package:firebase_auth_demo/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late MockNavigatorObserver mockNavigatorObserver;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockNavigatorObserver = MockNavigatorObserver();

    // Set up default mock responses
    when(() => mockUser.email).thenReturn('test@example.com');

    // Register fallback value for navigation verification
    registerFallbackValue(MaterialPageRoute<void>(builder: (_) => Container()));
  });

  Widget createHomeScreen() {
    return MaterialApp(
      home: HomeScreen.withAuth(mockFirebaseAuth, mockUser),
      navigatorObservers: [mockNavigatorObserver],
    );
  }

  testWidgets('Home screen shows user email', (WidgetTester tester) async {
    await tester.pumpWidget(createHomeScreen());

    expect(find.text('Welcome test@example.com!'), findsOneWidget);
  });

  testWidgets('Home screen shows logout button', (WidgetTester tester) async {
    await tester.pumpWidget(createHomeScreen());

    expect(find.byIcon(Icons.logout), findsOneWidget);
  });

  testWidgets('Successful logout navigates to login screen',
      (WidgetTester tester) async {
    // Setup successful signOut
    when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});

    await tester.pumpWidget(createHomeScreen());

    // Tap logout button
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    // Verify signOut was called
    verify(() => mockFirebaseAuth.signOut()).called(1);

    // Verify navigation occurred at least once
    verify(() => mockNavigatorObserver.didPush(any(), any()))
        .called(greaterThan(0));

    // Verify we're showing the login screen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Login'),
        ),
        findsOneWidget);
  });

  testWidgets('Failed logout shows error message', (WidgetTester tester) async {
    // Setup failed signOut
    when(() => mockFirebaseAuth.signOut())
        .thenThrow(FirebaseAuthException(code: 'error'));

    await tester.pumpWidget(createHomeScreen());

    // Tap logout button
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    // Verify error message is shown
    expect(find.text('Error logging out. Please try again.'), findsOneWidget);
  });

  testWidgets('Home screen shows all UI elements', (WidgetTester tester) async {
    await tester.pumpWidget(createHomeScreen());

    // Verify all text elements are present
    expect(find.text('You are now logged in.'), findsOneWidget);
    expect(
        find.text(
            'To logout, click the logout button in the top right corner.'),
        findsOneWidget);
  });
}
