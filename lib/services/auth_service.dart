import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isLoggedIn => currentUser != null;

  //Sign in with email and password
  Future<String?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  //Register with email and password
  Future<String?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _auth.signOut();
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  //Sign in with Google
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return 'Google sign-in was cancelled.';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      //Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      //Sign in to Firebase with the Google credential
      await _auth.signInWithCredential(credential);
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return 'Failed to sign in with Google. Please try again.';
    }
  }

  //Sign out the current user
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    notifyListeners();
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
