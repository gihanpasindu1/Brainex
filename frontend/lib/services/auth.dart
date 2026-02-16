import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/models/user_model.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      return _userWithFirebaseUserUid(user);
    } catch (err) {
      debugPrint(err.toString());
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
      return _userWithFirebaseUserUid(user);
    } catch (err) {
      debugPrint(err.toString());
      return null;
    }
  }

  // register with email and password
  Future<UserModel?> registerWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User? user = result.user;
      return _userWithFirebaseUserUid(user);
    } catch (err) {
      debugPrint(err.toString());
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
