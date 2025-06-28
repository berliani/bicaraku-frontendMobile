import 'dart:async';
import 'package:flutter/foundation.dart'; 

class Throttler {
  final Duration throttleDuration;
  Timer? _timer;
  bool _canCall = true;

  Throttler(this.throttleDuration);

  /// Memanggil callback jika interval throttle sudah berlalu.
  void call(VoidCallback callback) {
    if (_canCall) {
      _canCall = false;
      callback(); // Panggil fungsi segera
      _timer = Timer(throttleDuration, () {
        _canCall = true; // Izinkan panggilan berikutnya setelah durasi berlalu
      });
    }
  }

  /// Membatalkan timer throttle yang sedang berjalan dan mengizinkan panggilan berikutnya.
  void cancel() {
    _timer?.cancel();
    _canCall = true; // Reset agar bisa langsung memanggil lagi setelah reset
  }

  // Opsional: Untuk debugging atau pengujian
  @visibleForTesting
  bool get isThrottled => !_canCall;
}