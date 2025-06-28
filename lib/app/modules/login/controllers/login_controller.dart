import 'package:bicaraku/app/data/models/user_model.dart';
import 'package:bicaraku/app/data/repositories/auth_repository.dart';
import 'package:bicaraku/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bicaraku/app/data/controllers/user_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final UserController userController = Get.put(UserController());
  final AuthRepository authRepo = Get.find<AuthRepository>();
  final box = GetStorage();

  var obscurePassword = true.obs;
  var isLoading = false.obs;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Email dan password harus diisi");
      return;
    }

    isLoading(true);
    try {
      final response = await authRepo.login(email, password);

      if (response['status'] == 'success') {
        // Save token
        await box.write('token', response['token']);

        // Set user data
        userController.setUser(
          UserModel(
             id: response['user']['_id']?.toString() ?? '',
            name: response['user']['name'] ?? '',
            email: response['user']['email'] ?? '',
            provider: response['user']['provider'] ?? 'email',
            photoUrl: response['user']['photoUrl'] ?? '',
            lastLogin:
                response['user']['lastLogin'] ?? DateTime.now().toString(),
          ),
        );

        Get.offAllNamed(Routes.HOME);
      } else {
        Get.snackbar("Error", response['message'] ?? 'Login failed');
      }
    } catch (e) {
      Get.snackbar("Error", e.toString().replaceAll('Exception:', '').trim());
    } finally {
      isLoading(false);
    }
  }

  Future<void> loginWithGoogle() async {
    isLoading(true);
    try {
      // 1. Buat instance GoogleSignIn dengan konfigurasi
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
        signInOption: SignInOption.standard, // Gunakan dialog standar
      );

      // 2. Sign out dari akun sebelumnya
      await googleSignIn.signOut();

      // 3. Paksa tampilkan dialog pemilihan akun
      final googleUser = await googleSignIn.signIn(
        
      );

      if (googleUser == null) {
        Get.snackbar("Login Dibatalkan", "Pengguna membatalkan login Google.");
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final firebaseIdToken = await userCredential.user!.getIdToken();
      print('🔥 FIREBASE_ID_TOKEN: $firebaseIdToken');

      final response = await authRepo.loginWithGoogle(firebaseIdToken!);

      if (response['status'] == 'success') {
        await box.write('token', response['token']);

        userController.setUser(
          UserModel(
            id: response['user']['user_id'],
            name: response['user']['name'] ?? googleUser.displayName ?? 'User',
            email: response['user']['email'] ?? googleUser.email,
            provider: response['user']['provider'] ?? 'google',
            photoUrl: response['user']['photoUrl'] ?? googleUser.photoUrl ?? '',
            lastLogin:
                response['user']['lastLogin'] ?? DateTime.now().toString(),
          ),
        );

        Get.offAllNamed(Routes.HOME);
      } else {
        Get.snackbar("Error", response['message'] ?? 'Google login failed');
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan: ${e.toString()}");
      print('Google Sign-In Error: $e');
    } finally {
      isLoading(false);
    }
  }
}
