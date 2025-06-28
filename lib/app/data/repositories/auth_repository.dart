
import 'package:bicaraku/app/data/controllers/total_points_controller.dart';
import 'package:bicaraku/app/data/controllers/user_controller.dart';
import 'package:bicaraku/app/data/models/user_model.dart';
import 'package:bicaraku/core/network/api_constant.dart';
import 'package:bicaraku/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository() : _dioClient = Get.find<DioClient>();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      if (response.data['user'] != null) {
      final userData = response.data['user'];
      final user = UserModel.fromJson(userData);
      Get.find<UserController>().setUser(user);
      
      // Load poin setelah login
      Get.put(TotalPointsController()).loadTotalPoints();
    }

    return response.data;
  } on DioException catch (e) {
      print("Login Error: ${e.response?.data} | ${e.message}");
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.register,
        data: {'name': name, 'email': email, 'password': password},
      );

      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.googleLogin,
        data: {'idToken': idToken},
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Map<String, dynamic> _handleResponse(response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data;
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: response.data['message'] ?? 'Unknown error occurred',
      );
    }
  }

  String _handleError(DioException error) {
    final message =
        error.response?.data?['message'] ??
        error.message ??
        'Terjadi kesalahan yang tidak diketahui';
    final statusCode = error.response?.statusCode ?? 500;

    switch (statusCode) {
      case 400:
        return 'Permintaan tidak valid: $message';
      case 401:
        return 'Autentikasi gagal: $message';
      case 404:
        return 'Endpoint tidak ditemukan: $message';
      default:
        return 'Error $statusCode: $message';
    }
  }
}
