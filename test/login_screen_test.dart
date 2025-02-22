import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_demo/providers/auth_provider.dart';
import 'package:firebase_auth_demo/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();

    // Set up default mock responses
    when(() => mockUserCredential.user).thenReturn(mockUser);
    when(() => mockUser.email).thenReturn('test@example.com');
  });

  Widget createLoginScreen() {
    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
      ],
    );

    addTearDown(container.dispose);

    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  testWidgets('Login screen shows email and password fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(createLoginScreen());

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('Shows validation error for empty fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(createLoginScreen());

    // Find and tap the login button
    final loginButton = find.byType(ElevatedButton);
    await tester.tap(loginButton);
    await tester.pump();

    // Verify validation errors are shown
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('Shows validation error for invalid email',
      (WidgetTester tester) async {
    await tester.pumpWidget(createLoginScreen());

    // Enter invalid email
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'invalid-email');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'password123');

    // Tap the login button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Verify validation error is shown
    expect(find.text('Please enter a valid email'), findsOneWidget);
  });

  testWidgets('Shows validation error for short password',
      (WidgetTester tester) async {
    await tester.pumpWidget(createLoginScreen());

    // Enter valid email but short password
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), '12345');

    // Tap the login button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Verify validation error is shown
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });

  testWidgets('Successful login updates auth state',
      (WidgetTester tester) async {
    when(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => mockUserCredential);

    when(() => mockFirebaseAuth.authStateChanges())
        .thenAnswer((_) => Stream.value(mockUser));

    await tester.pumpWidget(createLoginScreen());

    // Enter valid credentials
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'password123');

    // Tap the login button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify that signInWithEmailAndPassword was called
    verify(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
  });

  testWidgets('Failed login attempt shows error message',
      (WidgetTester tester) async {
    when(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

    await tester.pumpWidget(createLoginScreen());

    // Enter credentials
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'wrongpassword');

    // Tap the login button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify that error message is shown
    expect(find.text('Wrong password provided'), findsOneWidget);
  });

  testWidgets('Shows loading indicator during login',
      (WidgetTester tester) async {
    // Setup a delayed response to show loading state
    when(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      return mockUserCredential;
    });

    await tester.pumpWidget(createLoginScreen());

    // Enter valid credentials
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'password123');

    // Tap the login button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Verify loading indicator is shown
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the login to complete
    await tester.pumpAndSettle();

    // Verify loading indicator is gone
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
