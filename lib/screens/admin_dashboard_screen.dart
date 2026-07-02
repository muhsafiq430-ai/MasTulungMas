import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Kita buat 2 Tab
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MasTulungMas - Dasbor Admin'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Data Pengguna'),
              Tab(icon: Icon(Icons.list_alt), text: 'Semua Pesanan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ISI TAB 1: DAFTAR PENGGUNA
            _buildDaftarPengguna(),

            // ISI TAB 2: DAFTAR PESANAN
            _buildDaftarPesanan(),
          ],
        ),
      ),
    );
  }

  // ===================================================
  // BACKEND LOGIC: MENARIK SEMUA DATA DARI KOLEKSI 'users'
  // ===================================================
  Widget _buildDaftarPengguna() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada pengguna terdaftar.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        var users = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = users[index];
            String role = user['role'] ?? 'konsumen';

            // Logika khusus untuk menampilkan array keahlian jika role-nya penolong
            String keahlianInfo = '';
            if (role == 'penolong') {
              List<dynamic> keahlianList = user['keahlian'] ?? [];
              keahlianInfo = '\nKeahlian: ${keahlianList.join(', ')}';
            }

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: role == 'admin'
                      ? Colors.red
                      : (role == 'penolong' ? Colors.green : Colors.blue),
                  child: Icon(
                    role == 'admin'
                        ? Icons.security
                        : (role == 'penolong' ? Icons.build : Icons.person),
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  user['nama'] ?? 'Tanpa Nama',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Email: ${user['email']}\nRole: ${role.toUpperCase()}$keahlianInfo',
                ),
                isThreeLine:
                    role ==
                    'penolong', // Beri ruang lebih luas jika ada teks keahlian
              ),
            );
          },
        );
      },
    );
  }

  // ===================================================
  // BACKEND LOGIC: MENARIK SEMUA DATA DARI KOLEKSI 'pesanan_tolong'
  // ===================================================
  Widget _buildDaftarPesanan() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pesanan_tolong')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada transaksi pesanan.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        var orders = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            var order = orders[index];
            String status = order['status'] ?? 'N/A';

            // Penentuan warna indikator status pesanan
            Color statusColor = Colors.grey;
            if (status == 'Mencari Penolong')
              statusColor = Colors.orange;
            else if (status == 'Dalam Perjalanan')
              statusColor = Colors.blue;
            else if (status == 'Selesai')
              statusColor = Colors.green;
            else if (status == 'Selesai & Dinilai')
              statusColor = Colors.teal;

            return Card(
              child: ListTile(
                title: Text(
                  '[${order['kategoriKeahlian']}] ${order['deskripsiMasalah']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Status: $status\nPenolong: ${order['namaPenolong'] == '' ? 'Belum Ada' : order['namaPenolong']}',
                ),
                trailing: Icon(Icons.circle, color: statusColor, size: 16),
              ),
            );
          },
        );
      },
    ); // streambuilder
  }
}
