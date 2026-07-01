import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ui_kerangka/app_theme.dart';

class RiwayatPenolongScreen extends StatelessWidget {
  const RiwayatPenolongScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Pekerjaan', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.grey.shade50,
      body: uid == null
          ? Center(child: Text('Harap login terlebih dahulu.', style: GoogleFonts.inter(color: Colors.grey.shade600)))
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
                    
                    final String title = data['judul'] ?? data['kategoriKeahlian'] ?? 'Pekerjaan';
                    final String desc = data['deskripsi'] ?? data['deskripsiMasalah'] ?? '';
                    final String price = data['harga']?.toString() ?? '50000';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 18,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        data['status'] ?? 'Selesai',
                                        style: GoogleFonts.inter(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              desc,
                              style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Pendapatan', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12)),
                                    Text(
                                      'Rp $price', 
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                if (data['ratingBintang'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.orange.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${data['ratingBintang']}',
                                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                                      ],
                                    ),
                                  )
                              ],
                            ),
                            if (data['teksUlasan'] != null &&
                                data['teksUlasan'].toString().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.format_quote_rounded, color: Colors.grey.shade400, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${data['teksUlasan']}',
                                        style: GoogleFonts.inter(fontStyle: FontStyle.italic, color: Colors.grey.shade700, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
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
