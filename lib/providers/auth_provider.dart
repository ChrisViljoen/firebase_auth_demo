import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  Stream<User?> build() {
    return ref.watch(firebaseAuthProvider).authStateChanges();
  }

  Future<void> signIn(String email, String password) async {
    await ref.read(firebaseAuthProvider).signInWithEmailAndPassword(
          email: email,
          password: password,
        );
  }

  Future<void> signUp(String email, String password) async {
    await ref.read(firebaseAuthProvider).createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
  }

  Future<void> signOut() async {
    await ref.read(firebaseAuthProvider).signOut();
  }
}
