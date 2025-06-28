import 'package:bicaraku/app/modules/profil/controllers/profil_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bicaraku/core/network/api_constant.dart';

class ProfilView extends StatelessWidget {
  ProfilView({super.key});
  final profilController = Get.find<ProfilController>();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: const BackButton(),
          title: const Text("Profil Saya"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person), text: "Data Akun"),
              Tab(icon: Icon(Icons.history), text: "Aktivitas"),
            ],
            indicatorColor: Colors.purpleAccent,
            labelColor: Colors.purpleAccent,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: Obx(() {
          if (profilController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            children: [_buildDataAkunTab(), _buildAktivitasTab()],
          );
        }),
      ),
    );
  }

  Widget _buildDataAkunTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Obx(() {
                final avatar = profilController.avatarPath.value;
                return CircleAvatar(
                  radius: 60,
                  backgroundImage:
                      avatar.isEmpty
                          ? const AssetImage("assets/images/iconuser.png")
                              as ImageProvider
                          : avatar.startsWith("http")
                          ? NetworkImage(avatar)
                          : NetworkImage('${ApiConstants.baseUrl}$avatar'),
                );
              }),
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: profilController.pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Klik untuk ubah foto",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 24),

          _buildTextField(
            label: "Email",
            controller: profilController.emailController,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: "Username",
            controller: profilController.usernameController,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: "Kata Sandi",
            controller: profilController.passwordController,
            isPassword: true,
            obscureRx: profilController.obscurePassword,
          ),
          const SizedBox(height: 24),

          // Tombol Update
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: profilController.updateProfile,
              icon: const Icon(Icons.save_rounded, size: 20),
              label: const Text("Update"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Logout & Hapus Akun
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text("Keluar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmDeleteAccount,
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: const Text("Hapus Akun"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAktivitasTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.login, color: Colors.blue),
          title: const Text("Riwayat Login"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Get.toNamed("/history-activity", arguments: {'type': "login"});
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.edit_note, color: Colors.orange),
          title: const Text("Riwayat Update Profil"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Get.toNamed(
              "/history-activity",
              arguments: {'type': "update_profile"},
            );
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    RxBool? obscureRx,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && obscureRx != null ? obscureRx.value : false,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon:
            isPassword && obscureRx != null
                ? Obx(
                  () => IconButton(
                    icon: Icon(
                      obscureRx.value ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => obscureRx.toggle(),
                  ),
                )
                : const Icon(Icons.edit, color: Colors.grey),
      ),
    );
  }

  void _confirmLogout() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.blue),
            SizedBox(width: 10),
            Text("Konfirmasi Keluar Akun"),
          ],
        ),
        content: const Text("Apakah Anda yakin ingin keluar dari akun ini?"),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "Batal",
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              profilController.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              "Ya, Keluar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  void _confirmDeleteAccount() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("Konfirmasi Hapus Akun"),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin menghapus akun ini? Tindakan ini tidak dapat dibatalkan.",
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "Batal",
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              profilController.deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              "Hapus Akun",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
