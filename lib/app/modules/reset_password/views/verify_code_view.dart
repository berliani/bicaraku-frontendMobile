import 'package:bicaraku/app/modules/reset_password/controllers/verify_code_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerifyCodeView extends GetView<VerifyCodeController> {
  const VerifyCodeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          // agar tidak overflow
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button dengan teks
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.arrow_back),
                      SizedBox(width: 6),
                      Text(
                        "Reset Kata Sandi",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                const Text("Verifikasi Kode", style: TextStyle(fontSize: 20)),
                const SizedBox(height: 12),
                const Text(
                  "Kami telah mengirimkan 6 digit kode ke email Anda. Masukkan kode tersebut di bawah ini untuk verifikasi.",
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 28),

                const Text("Kode Verifikasi"),
                const SizedBox(height: 12),

                // PinCode Field
                Center(
                  child: PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: controller.codeController,
                    autoFocus: true,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    animationDuration: const Duration(milliseconds: 250),
                    enableActiveFill: true,
                    onCompleted: (value) {},
                    onChanged: (value) {},
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(10),
                      fieldHeight: 50,
                      fieldWidth: 45,
                      activeFillColor: Colors.white,
                      inactiveFillColor: Colors.white,
                      selectedFillColor: Colors.white,
                      activeColor: Colors.purple,
                      selectedColor: Colors.purple,
                      inactiveColor: Colors.grey.shade300,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Tombol Verifikasi + Kirim Ulang
                Obx(
                  () => Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Tombol Verifikasi
                      ElevatedButton(
                        onPressed:
                            controller.isLoading.value
                                ? null
                                : controller.verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child:
                            controller.isLoading.value
                                ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  "Verifikasi",
                                  style: TextStyle(color: Colors.white),
                                ),
                      ),
                      const SizedBox(width: 20),

                      // Teks Kirim Ulang
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: controller.resendCode,
                            child: const Text(
                              "Kirim ulang",
                              style: TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
