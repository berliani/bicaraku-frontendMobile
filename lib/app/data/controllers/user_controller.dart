import 'package:bicaraku/app/data/controllers/total_points_controller.dart';
import 'package:bicaraku/app/data/models/user_model.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bicaraku/app/data/controllers/activity_controller.dart';

class UserController extends GetxController {
  final Rxn<UserModel> _user = Rxn<UserModel>();
  final box = GetStorage();

  // Getter untuk mengakses user data
  UserModel? get user => _user.value;
  Rxn<UserModel> get userRx => _user;

  @override
  void onInit() {
    super.onInit();
    _loadUserFromStorage();

    // Panggil loadTotalPoints saat user login
    ever(_user, (_) {
      if (_user.value != null) {
        Get.put(TotalPointsController()).loadTotalPoints();
      }
    });

    ever(_user, (_) {
      if (Get.isRegistered<ActivityController>()) {
        final activityController = Get.find<ActivityController>();
        if (_user.value != null && _user.value!.id.isNotEmpty) {
          // User login/data user di-set, muat histories
          activityController.loadHistories();
          // } else {
          //   // Hanya clear local state, TIDAK hapus dari server
          //   activityController.histories.clear();
          // }
        }
      }
    });
  }

  void setUser(UserModel u) {
    _user.value = u; // Update Rxn
    _saveUserToStorage(u); // Simpan ke local storage
  }

  void clearUser() {
    _user.value = null; // Set user ke null
    box.remove('user'); // Hapus dari local storage
  }

  void setBasicUser(String name, String email) {
    final newUser = UserModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}', // ID sementara
      name: name,
      email: email,
      provider: 'email',
      photoUrl: '',
      lastLogin: DateTime.now().toIso8601String(), // String ISO
      points: 0,
    );
    _user.value = newUser; // Update Rxn
  }

  // ============ PRIVATE METHODS ============
  void _saveUserToStorage(UserModel user) {
    // print('Saving user to storage: ${user.toJson()}'); // Debug print
    box.write('user', user.toJson()); // Langsung simpan Map dari toJson()
  }

  void _loadUserFromStorage() {
    // print('Attempting to load user from storage...'); // Debug print
    final storedUserMap = box.read('user');
    if (storedUserMap != null && storedUserMap is Map<String, dynamic>) {
      try {
        final loadedUser = UserModel.fromJson(storedUserMap);
        _user.value = loadedUser;
        // print('User loaded from storage: ${loadedUser.toJson()}'); // Debug print
      } catch (e) {
        print('Error parsing stored user data: $e');
        _user.value = null; // Clear user if parsing fails
        box.remove('user'); // Also remove invalid data
      }
    } else {
      // print('No user found in storage or data is invalid.'); // Debug print
      _user.value = null;
    }
  }

  // Helper untuk update field spesifik
  void updateUserInfo({
    String? name,
    String? email,
    String? photoUrl,
    int? points,
  }) {
    if (_user.value != null) {
      final currentUser = _user.value!;
      final updatedUser = _user.value!.copyWith(
        name: name ?? currentUser.name,
        email: email ?? currentUser.email,
        photoUrl: photoUrl ?? currentUser.photoUrl,
        points: points ?? currentUser.points, // Tambahkan update points
      );
      setUser(updatedUser); // Gunakan setUser untuk simpan ke storage
    }
  }
}
