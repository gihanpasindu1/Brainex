import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/services/user_profile_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserProfileService _userProfileService = UserProfileService();

  UserModel? _userWithFirebaseUserUid(User? user) {
    return user != null ? UserModel(uid: user.uid) : null;
  }

  Stream<UserModel?> get user {
    return _auth.authStateChanges().map(_userWithFirebaseUserUid);
  }

  //anony loging (just for testing)
  Future<UserModel?> signInAnonymously() async {
    try {
      final UserCredential result = await _auth.signInAnonymously();
      final User? user = result.user;
      if (user != null) {
        await _userProfileService.syncDailyLoginXp(user.uid);
      }
      return _userWithFirebaseUserUid(user);
    } catch (err) {
      debugPrint(err.toString());
      return null;
    }
  }

  // google login
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      final User? user = result.user;

      if (user != null) {
        await _userProfileService.syncDailyLoginXp(user.uid);
      }
      return _userWithFirebaseUserUid(user);
    } catch (err) {
      debugPrint('Google Sign-In Error: $err');
      return null;
    }
  }

  // email.pw loging
  Future<UserModel?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User? user = result.user;
      if (user != null) {
        await _userProfileService.syncDailyLoginXp(user.uid);
      }
      return _userWithFirebaseUserUid(user);
    } catch (err) {
      debugPrint(err.toString());
      return null;
    }
  }

  // register with email and password
  Future<dynamic> registerWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User? user = result.user;
      if (user != null) {
        await _userProfileService.syncDailyLoginXp(user.uid);
      }
      return _userWithFirebaseUserUid(user);
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Error: ${e.code} - ${e.message}");
      return e.code; // Return the error code (e.g., 'email-already-in-use')
    } catch (err) {
      debugPrint("General Registration Error: ${err.toString()}");
      return null;
    }
  }

  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (err) {
      debugPrint(err.toString());
      return null;
    }
  }
}
