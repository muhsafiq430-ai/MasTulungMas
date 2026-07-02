# MasTulungMas (Pinjam Alat) 🛠️

MasTulungMas adalah aplikasi berbasis **Flutter** yang dirancang untuk memudahkan pengguna dalam meminjam alat atau meminta bantuan. Aplikasi ini dilengkapi dengan sistem berbasis peran (User, Penolong, dan Admin) untuk mengelola permintaan dan penyediaan alat secara efisien.

## 🌟 Fitur Utama

- **Multi-Role User System:**
  - **Pengguna (User):** Dapat mencari, melihat lokasi, dan meminjam alat atau meminta bantuan.
  - **Penolong (Provider):** Dapat mendaftarkan alat yang disewakan/dipinjamkan dan menerima permintaan dari pengguna.
  - **Admin:** Mengelola data pengguna, penolong, dan keseluruhan sistem.
- **Otentikasi Aman:** Terintegrasi dengan Firebase Authentication untuk login dan registrasi yang aman.
- **Manajemen Data Real-time:** Menggunakan Cloud Firestore untuk mengelola data peminjaman, alat, dan profil pengguna secara *real-time*.
- **Layanan Lokasi:** Dilengkapi dengan fitur `geolocator` dan `geocoding` untuk melacak lokasi alat atau penolong terdekat.
- **Unggah Gambar:** Mendukung pengambilan dan pengunggahan foto alat melalui kamera atau galeri menggunakan `image_picker` dan Firebase Storage.

## 🛠️ Teknologi yang Digunakan

- **Framework:** [Flutter](https://flutter.dev/)
- **Backend (BaaS):** [Firebase](https://firebase.google.com/)
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
- **Package Utama:**
  - `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` (Backend Firebase)
  - `geolocator`, `geocoding` (Layanan Lokasi)
  - `image_picker` (Akses Media)
  - `http`, `url_launcher` (Jaringan dan Navigasi eksternal)
  - `google_fonts`, `cupertino_icons` (Desain & Tipografi)

## 📂 Struktur Folder Utama

```text
lib/
├── models/                   # Model data (User, Alat, Transaksi, dll)
├── screens/                  # Halaman aplikasi umum (Login, Register, dll)
├── services/                 # Logika bisnis dan koneksi backend (Firebase, Location)
├── ui_kerangka/              # Antarmuka (UI) untuk pengguna biasa / peminjam
├── ui_kerangka_admin/        # Antarmuka (UI) khusus untuk Admin
└── ui_kerangka_penolong/     # Antarmuka (UI) khusus untuk Penolong / Pemilik Alat
