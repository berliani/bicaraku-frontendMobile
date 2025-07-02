# Bicaraku 🗣️

**Bicaraku** adalah aplikasi mobile berbasis **Flutter** yang terintegrasi dengan model **AI YOLOv8** untuk deteksi multi-objek secara real-time.  
Aplikasi ini dikembangkan untuk **stimulasi bicara interaktif anak usia golden age (0-5 tahun)** melalui interaksi dengan objek sekitar dan latihan berbicara.

## 🚀 Fitur Utama

- 👀 **Melihat**  
  Mendeteksi objek sekitar dengan kamera secara real-time menggunakan YOLOv8.  
  Disertai **speech-to-text (STT)** yang menjelaskan nama objek.  
  Pengguna diminta mengulangi nama objek — sistem memberikan feedback apakah pengucapan benar atau salah.

- 🔍 **Mencari**  
  Pengguna memilih objek yang ingin dicari.  
  Kamera mendeteksi keberadaan objek tersebut dan memberikan feedback saat ditemukan.

- 💬 **Berbicara**  
  Stimulasi berbicara melalui berbagai challenge.  
  Setiap level memiliki tingkat kesulitan berbeda berdasarkan jumlah suku kata yang harus diucapkan.

## 🛠 Teknologi dan Library

- **Flutter**
- **YOLOv8** (deteksi objek real-time)
- **STT** (Speech-to-Text)
- **TTS** (Text-to-Speech)

## ⚙️ Instalasi dan Cara Menjalankan

1️⃣ Clone repository ini:
```bash
git clone https://github.com/berliani/bicaraku-frontendMobile.git
cd bicaraku-frontendMobile
```
2️⃣ Pastikan Anda sudah menginstal Flutter SDK dan dependencies:
```bash
flutter pub get
```
3️⃣ Jalankan aplikasi di emulator atau perangkat fisik:
```bash
flutter run
```
