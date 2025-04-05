import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      developer.log('Starting Google Sign-In process', name: 'AuthService');

      // Check if user is already signed in
      if (await _googleSignIn.isSignedIn()) {
        developer.log('User already signed in, signing out first',
            name: 'AuthService');
        await _googleSignIn.signOut();
      }

      // Trigger the authentication flow
      developer.log('Attempting to trigger Google Sign-In flow',
          name: 'AuthService');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        developer.log('Google Sign-In cancelled by user', name: 'AuthService');
        return null;
      }

      developer.log(
          'Google Sign-In successful, user email: ${googleUser.email}',
          name: 'AuthService');

      try {
        // Obtain the auth details from the request
        developer.log('Getting Google auth details', name: 'AuthService');
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a new credential
        developer.log('Creating Firebase credential', name: 'AuthService');
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        developer.log('Signing in to Firebase with Google credential',
            name: 'AuthService');
        final userCredential = await _auth.signInWithCredential(credential);

        developer.log(
            'Firebase sign-in successful: ${userCredential.user?.uid}',
            name: 'AuthService');
        return userCredential;
      } catch (e, stackTrace) {
        developer.log('Error during Google authentication: $e\n$stackTrace',
            name: 'AuthService');
        // Sign out from Google if Firebase auth fails
        await _googleSignIn.signOut();
        rethrow;
      }
    } catch (e, stackTrace) {
      developer.log('Error signing in with Google: $e\n$stackTrace',
          name: 'AuthService');
      if (e is FirebaseAuthException) {
        developer.log('Firebase Auth Error Code: ${e.code}',
            name: 'AuthService');
        developer.log('Firebase Auth Error Message: ${e.message}',
            name: 'AuthService');
      }
      // Ensure we're signed out from Google if there's an error
      try {
        await _googleSignIn.signOut();
      } catch (signOutError) {
        developer.log('Error signing out after failure: $signOutError',
            name: 'AuthService');
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      developer.log('Starting sign out process', name: 'AuthService');
      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
      ]);
      developer.log('Sign out successful', name: 'AuthService');
    } catch (e, stackTrace) {
      developer.log('Error signing out: $e\n$stackTrace', name: 'AuthService');
      rethrow;
    }
  }
}
