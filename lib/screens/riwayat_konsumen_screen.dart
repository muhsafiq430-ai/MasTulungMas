import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ui_kerangka/app_theme.dart';

class RiwayatKonsumenScreen extends StatelessWidget {
  const RiwayatKonsumenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Transaksi', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: primaryColor,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50,
      body: uid == null
          ? Center(child: Text('Harap login terlebih dahulu.', style: GoogleFonts.inter(color: Colors.grey.shade600)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pesanan_tolong')
                  .where('konsumen_uid', isEqualTo: uid)
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
                                    Text('Total Pembayaran', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12)),
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
                            ] else if (data['status'] == 'Selesai') ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _tampilkanDialogUlasan(context, doc.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text('Beri Ulasan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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

  void _tampilkanDialogUlasan(BuildContext context, String idPesanan) {
    int rating = 5;
    TextEditingController ulasanController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Beri Ulasan Penolong'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                          size: 32,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ulasanController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tulis ulasan Anda di sini...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (ulasanController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ulasan tidak boleh kosong!'),
                        ),
                      );
                      return;
                    }
                    await FirebaseFirestore.instance
                        .collection('pesanan_tolong')
                        .doc(idPesanan)
                        .update({
                          'status': 'Selesai & Dinilai',
                          'ratingBintang': rating,
                          'teksUlasan': ulasanController.text.trim(),
                        });
                    
                    if (context.mounted) {
                      Navigator.pop(context); // Tutup dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ulasan berhasil dikirim!'), backgroundColor: Colors.green),
                      );
                    }
                  },
                  child: const Text('Kirim Ulasan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
