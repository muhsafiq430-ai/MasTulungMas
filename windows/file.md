# Tasklist Pengembangan MasTulungMas

Berikut adalah pembagian tugas untuk pengembangan MVP MasTulungMas berdasarkan Product Requirements Document (PRD).

## 👨‍💻 1. Safiq - Sisi Konsumen (Consumer App)
- [ ] Merancang dan membangun UI/UX Dashboard Konsumen.
- [ ] Mengembangkan Fitur Pembuatan Pesanan Darurat (berdasarkan 5 kategori).
- [ ] Mengintegrasikan Pelacakan Lokasi Otomatis (Geocoding - mengambil koordinat GPS dan menerjemahkannya menjadi alamat teks).
- [ ] Mengimplementasikan Fitur Lampiran Visual (upload foto kerusakan ke Firebase Storage).
- [ ] Membangun Sistem Penilaian (Rating & Review).

## 👨‍💻 2. Yoga - Sisi Penolong (Helper App) & Komunikasi
- [ ] Merancang dan membangun UI/UX Dashboard Penolong.
- [ ] Mengembangkan Fitur Filter Pesanan Real-Time (hanya menampilkan pesanan "Mencari Penolong" yang sesuai dengan keahlian).
- [ ] Membangun Alur Manajemen Tugas (perubahan status pesanan dari "Mencari" hingga "Selesai").
- [ ] Mengembangkan Fitur Preview Konteks (menampilkan jarak dan thumbnail gambar sebelum Penolong mengambil tugas).
- [ ] Mengintegrasikan Live Chat real-time 1-on-1 (Konsumen & Penolong).

## 👨‍💻 3. Alfian - Admin Dashboard & Backend Infrastructure
- [ ] Melakukan Setup Backend (Firebase Authentication, Cloud Firestore, Firebase Storage).
- [ ] Menerapkan Role-Based Access Control (RBAC) untuk Konsumen, Penolong, dan Admin di tingkat database.
- [ ] Merancang dan membangun UI/UX Dasbor Admin (Antarmuka dua tab).
- [ ] Mengembangkan Fitur Monitoring Pengguna (melihat data semua entitas).
- [ ] Mengembangkan Fitur Monitoring Pesanan (melacak status seluruh tiket pesanan secara real-time).
