import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/models/UserModel.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _userWithFirebaseUserUid(User? user) {
    return user != null ? UserModel(uid: user.uid) : null;
  }

  Stream<UserModel?> get user {
    return _auth.authStateChanges().map(_userWithFirebaseUserUid);
  }

  Future<UserModel?> signInAnonymously() async {
    try {
      final UserCredential result = await _auth.signInAnonymously();
      final User? user = result.user;
      return _userWithFirebaseUserUid(user);
    } catch (err) {
      print(err.toString());
      return null;
    }
  }
}
