import 'package:bsb_eats/service/auth_service.dart';
import 'package:bsb_eats/shared/model/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthController  extends ChangeNotifier {
  static final AuthService _service = AuthService();
  OAuthCredential? _gCredential;
  OAuthCredential? _appleCredential;

  OAuthCredential? get gCredential => _gCredential;
  OAuthCredential? get appleCredential => _appleCredential;
  MyUser? currentUser;
  bool loading = false;

  void notify() => notifyListeners();

  Stream<User?> get authStateChanges => _service.authStateChanges;

  Future<void> getLoggedUser() async {
    currentUser = await _service.getLoggedUser();
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _service.login(email, password);
    await getLoggedUser();
    return;
  }

  Future<void> logout() async => _service.logout();

  Future<void> registerUser({required MyUser user, required String pass}) async {
    await _service.registerUser(user: user, pass: pass);
    notifyListeners();
    return;
  }

  Future<void> sendEmailVerification() async => _service.sendEmailVerification();

  Future<User?> reloadUser() async => _service.reloadUser();

  Future<void> resetPassword(String email) async => await _service.resetPassword(email);

  Future<UserCredential?> reauthenticateUser(String email, String password) async => _service.reauthenticateUser(email, password);

  Future<void> updatePassword(String newPassword) async => _service.updatePassword(newPassword);

  Future<void> deleteAccount() async {
    await _service.deleteAccount(currentUser!);
    currentUser = null;
  }

  Future<void> saveUserData(MyUser user) async => _service.saveUserData(user);

  Future<void> getGoogleCredential() async {
    _gCredential = await _service.getGoogleCredential();
  }

  Future<void> getAppleCredential() async {
    _appleCredential = await _service.getAppleCredential();
  }

  Future<UserCredential?> googleSignIn() async {
    final userCredential = await _service.signInWithCredential(_gCredential!);
    if(userCredential != null) {
      await getLoggedUser();
    }
    return userCredential;
  }

  Future<UserCredential?> appleSignIn() async {
    final userCredential = await _service.signInWithCredential(_appleCredential!);
    if(userCredential != null) {
      await getLoggedUser();
    }

    return userCredential;
  }

  Future<bool> isUsernameAvailable(String username) async => _service.isUsernameAvailable(username);

  void changeApiUrl(String url) => _service.changeApiUrl(url);
}