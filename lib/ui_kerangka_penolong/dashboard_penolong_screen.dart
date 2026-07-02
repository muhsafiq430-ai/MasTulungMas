import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ui_kerangka/app_theme.dart';
import '../screens/chat_screen.dart';

class DashboardPenolongScreen extends StatefulWidget {
  const DashboardPenolongScreen({Key? key}) : super(key: key);

  @override
  State<DashboardPenolongScreen> createState() => _DashboardPenolongScreenState();
}

class _DashboardPenolongScreenState extends State<DashboardPenolongScreen> {
  bool _isOnline = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildStatusToggle(),
              const SizedBox(height: 32),
              _buildSummaryCards(),
              const SizedBox(height: 32),
              _buildStreamCurrentJob(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get(),
      builder: (context, snapshot) {
        String name = 'Penolong';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          name = data?['nama'] ?? data?['name'] ?? 'Penolong';
          
          if (name.contains(' ')) {
            name = name.split(' ')[0];
          }
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $name! 👋',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Siap membantu hari ini?',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, color: Colors.white, size: 30),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusToggle() {
    return Card(
      elevation: 0,
      color: _isOnline ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isOnline ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Kerja',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isOnline ? 'Online - Menerima Pesanan' : 'Offline - Istirahat',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: _isOnline ? Colors.green[700] : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Switch(
              value: _isOnline,
              activeColor: Colors.green,
              onChanged: (value) {
                setState(() {
                  _isOnline = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pesanan_tolong')
          .where('penolong_uid', isEqualTo: uid)
          .where('status', whereIn: ['Selesai', 'Selesai & Dinilai'])
          .snapshots(),
      builder: (context, snapshot) {
        int totalPendapatan = 0;
        int totalSelesai = 0;

        if (snapshot.hasData) {
          totalSelesai = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            var harga = data['harga'];
            if (harga is int) {
              totalPendapatan += harga;
            } else if (harga is String) {
              totalPendapatan += int.tryParse(harga) ?? 0;
            }
          }
        }

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Pendapatan',
                value: 'Rp $totalPendapatan',
                icon: Icons.account_balance_wallet,
                iconColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                title: 'Pekerjaan Selesai',
                value: '$totalSelesai',
                icon: Icons.check_circle,
                iconColor: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamCurrentJob() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pesanan_tolong')
          .where('penolong_uid', isEqualTo: uid)
          .where('status', whereIn: ['Diterima Penolong', 'Dalam Proses', 'Selesai'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Ambil pekerjaan pertama (asumsi penolong hanya ambil 1 kerjaan pada satu waktu)
        var doc = snapshot.data!.docs.first;
        var data = doc.data() as Map<String, dynamic>;

        return _buildCurrentJobCard(doc.id, data);
      },
    );
  }

  Widget _buildCurrentJobCard(String jobId, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pekerjaan Saat Ini',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
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
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=33'), // Dummy avatar
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['judul'] ?? 'Pengguna',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              'Konsumen',
                              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                         color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data['status'] == 'Dalam Proses' ? 'Sedang Pengerjaan' : 'Menunggu Pembayaran',
                        style: GoogleFonts.inter(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(),
                ),
                Text(
                  'Deskripsi Pekerjaan:',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  data['deskripsi'] ?? '',
                  style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Harga Deal:',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Rp ${data['harga'] ?? 0}',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat, color: Colors.blue, size: 32),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(idPesanan: jobId),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    if (data['status'] == 'Dalam Proses')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance.collection('pesanan_tolong').doc(jobId).update({
                                'status': 'Selesai',
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Pekerjaan telah diselesaikan!'), backgroundColor: Colors.green),
                                );
                              }
                            } catch (e) {
                               if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal menyelesaikan: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: AppTheme.primaryBlue.withOpacity(0.4),
                          ),
                          child: Text(
                            'Selesaikan Pekerjaan',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    else if (data['status'] == 'Selesai')
                      Expanded(
                        child: Text(
                          'Pekerjaan Selesai!\nMenunggu ulasan konsumen.',
                          style: GoogleFonts.inter(color: Colors.green, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          'Menunggu konfirmasi pembayaran...',
                          style: GoogleFonts.inter(color: Colors.grey, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} //catatan
