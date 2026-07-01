import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ui_kerangka/app_theme.dart';

class RiwayatPenolongScreen extends StatelessWidget {
  const RiwayatPenolongScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pekerjaan'),
      ),
      body: uid == null
          ? const Center(child: Text('Harap login terlebih dahulu.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pesanan_tolong')
                  .where('penolong_uid', isEqualTo: uid)
                  .where('status', whereIn: ['Selesai', 'Selesai & Dinilai'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Terjadi kesalahan memuat riwayat.'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Belum ada riwayat pekerjaan yang selesai.'));
                }

                final riwayatList = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: riwayatList.length,
                  itemBuilder: (context, index) {
                    final doc = riwayatList[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final String title = data['judul'] ?? data['kategoriKeahlian'] ?? 'Pesanan';
                    final String desc = data['deskripsi'] ?? data['deskripsiMasalah'] ?? '';
                    final String price = data['harga']?.toString() ?? '50000';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    data['status'] ?? 'Selesai',
                                    style: const TextStyle(
                                        color: Colors.green, fontSize: 12),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(desc),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Rp $price', 
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                                if (data['ratingBintang'] != null)
                                  Row(
                                    children: [
                                      Text(
                                        '${data['ratingBintang']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const Icon(Icons.star, color: Colors.orange, size: 16),
                                    ],
                                  )
                              ],
                            ),
                            if (data['teksUlasan'] != null &&
                                data['teksUlasan'].toString().isNotEmpty) ...[
                              const Divider(),
                              Text(
                                'Ulasan Konsumen: "${data['teksUlasan']}"',
                                style: const TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
