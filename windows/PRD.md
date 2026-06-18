# Product Requirements Document (PRD)
**Nama Produk:** MasTulungMas (Aplikasi On-Demand Services)
**Status:** Tahap Pengembangan (MVP - Minimum Viable Product)

## 1. Ringkasan Eksekutif (Overview)
MasTulungMas adalah platform aplikasi on-demand yang menjembatani masyarakat yang membutuhkan bantuan jasa perbaikan atau tugas sehari-hari (Konsumen) dengan tenaga ahli atau pekerja paruh waktu (Penolong) di sekitar mereka. Aplikasi ini dirancang dengan alur yang cepat, berbasis lokasi (GPS), dan memiliki sistem komunikasi real-time.

## 2. Target Pengguna & Peran (User Roles)
Sistem ini menggunakan Role-Based Access Control (RBAC) yang membagi pengguna menjadi tiga entitas utama:
* Konsumen: Pengguna yang membutuhkan bantuan, memanggil penolong, dan memberikan ulasan.
* Penolong: Tenaga ahli atau pekerja yang menerima tugas berdasarkan kecocokan kategori keahlian mereka.
* Admin: Pengawas sistem yang memiliki akses God View untuk memantau aktivitas pengguna dan transaksi pesanan.

## 3. Fitur Utama (Core Features)

### Sisi Konsumen (Consumer App)
* Pembuatan Pesanan Darurat: Pengguna dapat membuat pesanan berdasarkan 5 kategori (Listrik, Air, Mesin, Pertukangan, Umum).
* Pelacakan Lokasi Otomatis (Geocoding): Pengambilan kordinat (Latitude/Longitude) secara otomatis dari sensor GPS perangkat yang diterjemahkan menjadi alamat teks.
* Lampiran Visual: Kemampuan mengunggah foto kerusakan perangkat agar Penolong memiliki konteks visual sebelum menerima tugas.
* Sistem Penilaian (Rating & Review): Memberikan bintang (1-5) dan ulasan teks setelah pekerjaan berstatus Selesai.

### Sisi Penolong (Helper App)
* Filter Pesanan Real-Time: Penolong hanya melihat siaran pesanan yang statusnya "Mencari Penolong" dan cocok dengan array keahlian yang terdaftar di profil mereka.
* Manajemen Tugas: Alur penerimaan tugas yang mengubah status pesanan menjadi "Dalam Perjalanan" hingga "Selesai".
* Preview Konteks: Melihat secara jelas jarak lokasi (alamat) dan thumbnail foto kerusakan sebelum menekan tombol "Ambil".

### Komunikasi & Pengawasan
* Live Chat: Ruang obrolan real-time 1-on-1 antara Konsumen dan Penolong khusus untuk pesanan yang sedang berjalan.
* Dasbor Admin (Monitoring): Antarmuka dua layar (Tab) untuk memantau data seluruh entitas pengguna dan memantau status semua tiket pesanan yang terjadi di database.

## 4. Arsitektur Backend & Infrastruktur Data
Fokus utama sistem ini terletak pada efisiensi backend dan real-time database syncing.
* Autentikasi: Menggunakan Firebase Authentication (Email/Password) dengan pemisahan role yang aman di tingkat database.
* Database (Cloud Firestore): Menggunakan struktur NoSQL dengan koleksi utama meliputi users, pesanan_tolong, dan chats.
* Penyimpanan Media (Firebase Storage): Mengelola file gambar (foto kerusakan) yang diunggah pengguna dan mengubahnya menjadi URL network yang disuntikkan ke dokumen Firestore.
* Manajemen State: Menggunakan StreamBuilder untuk memastikan setiap perubahan data di server langsung tercermin di layar aplikasi tanpa perlu refresh manual.

## 5. Matrik Keberhasilan (Success Metrics)
Untuk mengukur keberhasilan MVP ini, indikator yang akan dipantau meliputi:
* Order Completion Rate: Persentase pesanan yang berhasil mencapai status "Selesai & Dinilai" dibandingkan dengan total pesanan yang disiarkan.
* Match Speed: Rata-rata waktu yang dibutuhkan sejak pesanan dibuat hingga tombol "Ambil" ditekan oleh Penolong.
* System Stability: Nol error pada sinkronisasi gambar dan pengambilan titik kordinat GPS.