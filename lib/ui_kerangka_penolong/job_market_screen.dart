import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ui_kerangka/app_theme.dart';

class JobMarketScreen extends StatefulWidget {
  const JobMarketScreen({Key? key}) : super(key: key);

  @override
  State<JobMarketScreen> createState() => _JobMarketScreenState();
}

class _JobMarketScreenState extends State<JobMarketScreen> {
  String? _selectedFilter;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _loadUserSkill();
  }

  Future<void> _loadUserSkill() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          // Jika penolong punya keahlian tersimpan, jadikan filter awal. Jika tidak, "Semua"
          _selectedFilter = data.containsKey('keahlian') && data['keahlian'] != null 
              ? data['keahlian'] 
              : 'Semua';
          _isInit = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedFilter = 'Semua';
          _isInit = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('Job Market', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: primaryColor,
        elevation: 0,
        actions: [
          if (_isInit)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    style: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.bold),
                    icon: Icon(Icons.filter_list_rounded, color: primaryColor, size: 20),
                    underline: const SizedBox(),
                    isDense: true,
                    items: [
                      DropdownMenuItem(value: 'Semua', child: Text('Semua', style: GoogleFonts.inter())),
                      DropdownMenuItem(value: 'Angkat Barang', child: Text('Angkat Barang', style: GoogleFonts.inter())),
                      DropdownMenuItem(value: 'Bersih-bersih', child: Text('Bersih-bersih', style: GoogleFonts.inter())),
                      DropdownMenuItem(value: 'Perbaikan Listrik/Air', child: Text('Perbaikan Listrik/Air', style: GoogleFonts.inter())),
                      DropdownMenuItem(value: 'Belanja / Kurir', child: Text('Belanja / Kurir', style: GoogleFonts.inter())),
                      DropdownMenuItem(value: 'Montir / Otomotif', child: Text('Montir / Otomotif', style: GoogleFonts.inter())),
                      DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya', style: GoogleFonts.inter())),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: !_isInit 
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _selectedFilter == 'Semua'
                  ? FirebaseFirestore.instance
                      .collection('pesanan_tolong')
                      .where('status', isEqualTo: 'Menunggu Penolong')
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('pesanan_tolong')
                      .where('status', isEqualTo: 'Menunggu Penolong')
                      .where('judul', isEqualTo: _selectedFilter)
                      .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi kesalahan memuat daftar pekerjaan.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada tawaran pekerjaan saat ini.'));
          }

          final jobOffers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: jobOffers.length,
            itemBuilder: (context, index) {
              final doc = jobOffers[index];
              final job = doc.data() as Map<String, dynamic>;
              final jobId = doc.id;
              String timeStr = 'Baru saja';
              if (job['createdAt'] != null && job['createdAt'] is Timestamp) {
                DateTime dt = (job['createdAt'] as Timestamp).toDate();
                Duration diff = DateTime.now().difference(dt);
                if (diff.inMinutes < 60) {
                  timeStr = '${diff.inMinutes} menit lalu';
                } else if (diff.inHours < 24) {
                  timeStr = '${diff.inHours} jam lalu';
                } else {
                  timeStr = '${diff.inDays} hari lalu';
                }
              }

              job['id'] = jobId;
              job['distance'] = job['lokasi'] ?? '1.0 km';
              job['description'] = job['deskripsi'] ?? '';
              job['price'] = 'Rp ${job['harga'] ?? 0}';
              job['time'] = timeStr;
              job['avatarUrl'] = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(job['judul'] ?? 'User')}&background=random'; 

              String konsumenUid = job['konsumen_uid'] ?? '';
              if (konsumenUid.isEmpty) {
                job['consumerName'] = job['judul'] ?? 'Pengguna';
                return _buildJobCard(context, job);
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(konsumenUid).get(),
                builder: (context, userSnapshot) {
                  String name = job['judul'] ?? 'Pengguna';
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    name = userData?['name'] ?? name;
                    job['avatarUrl'] = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random';
                  }
                  job['consumerName'] = name;
                  return _buildJobCard(context, job);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _showJobDetailsBottomSheet(context, job);
        },
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
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(job['avatarUrl']),
                        backgroundColor: Colors.grey.shade200,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        job['consumerName'],
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          job['distance'],
                          style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(job['judul'] ?? 'Pekerjaan', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                job['description'],
                style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        job['time'],
                        style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Tawaran', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500)),
                      Text(
                        job['price'],
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJobDetailsBottomSheet(BuildContext context, Map<String, dynamic> job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Detail Pekerjaan',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(job['avatarUrl']),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job['consumerName'],
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 14, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  job['lokasi'] ?? job['distance'],
                                  style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Deskripsi Tugas',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
              Text(
                job['description'],
                style: GoogleFonts.inter(fontSize: 16, color: Colors.black87, height: 1.5),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tawaran Harga',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade500),
                  ),
                  Text(
                    job['price'],
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Close BottomSheet first
                    Navigator.pop(context);
                    
                    _terimaPekerjaan(job['id']);
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
                    'Terima Pekerjaan Ini',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24), // Extra padding at bottom
            ],
          ),
        );
      },
    );
  }

  Future<void> _terimaPekerjaan(String jobId) async {
    try {
      final penolongUid = FirebaseAuth.instance.currentUser?.uid;
      if (penolongUid == null) throw Exception("Sesi penolong tidak valid.");

      await FirebaseFirestore.instance.collection('pesanan_tolong').doc(jobId).update({
        'status': 'Diterima Penolong',
        'penolong_uid': penolongUid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pekerjaan berhasil diterima!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menerima pekerjaan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
