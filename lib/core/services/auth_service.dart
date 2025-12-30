import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart' as app_user;

class AuthService {
  // AuthService() : _auth = FirebaseAuth.instance, _googleSignIn = GoogleSignIn();
  AuthService() : _googleSignIn = GoogleSignIn();

  // final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  // Stream<User?> get authStateChanges => _auth.authStateChanges();
  Stream<dynamic> get authStateChanges => Stream.empty();

  // User? get currentFirebaseUser => _auth.currentUser;
  dynamic get currentFirebaseUser => null;

  app_user.User? get currentUser {
    /*
    final user = _auth.currentUser;
    if (user == null) return null;

    return app_user.User(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
    */
    return null;
  }

  Future<app_user.User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    /*
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      return currentUser;
    }
    */
    return null;
  }

  Future<app_user.User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    /*
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null && displayName != null) {
      await credential.user!.updateDisplayName(displayName);
      await credential.user!.reload();
    }

    return currentUser;
    */
    return null;
  }

  Future<app_user.User?> signInWithGoogle() async {
    /*
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      final credential = await _auth.signInWithPopup(googleProvider);
      if (credential.user != null) {
        return currentUser;
      }
      return null;
    } else {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return currentUser;
    }
    */
    return null;
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    // await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    // await _auth.sendPasswordResetEmail(email: email);
  }
}
