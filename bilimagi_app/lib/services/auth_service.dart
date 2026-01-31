import 'package:firebase_auth/firebase_auth.dart';
import 'profile_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _profileService = ProfileService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Initialize user stats if they don't exist
    if (credential.user != null) {
      await _profileService.initializeUserStats(credential.user!.uid);
    }

    return credential;
  }

  // v4.0: Sign up new user
  Future<UserCredential> signUp(String email, String password, String displayName) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user profile
    if (credential.user != null) {
      await _profileService.createUserProfile(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
      );
    }

    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
