import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ui_kerangka/app_theme.dart';

class DashboardAdminScreen extends StatelessWidget {
  const DashboardAdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildStatisticsGrid(context),
              const SizedBox(height: 32),
              _buildRecentActivities(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, Admin!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ringkasan sistem hari ini',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        const CircleAvatar(
          radius: 28,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=68'), // Dummy admin photo
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Utama',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, userSnapshot) {
            int totalUsers = userSnapshot.hasData ? userSnapshot.data!.docs.length : 0;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pesanan_tolong').snapshots(),
              builder: (context, orderSnapshot) {
                int pesananBerjalan = 0;
                int totalTransaksi = 0;

                if (orderSnapshot.hasData) {
                  for (var doc in orderSnapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String status = data['status'] ?? '';
                    if (status == 'Menunggu Penolong' || status == 'Diterima Penolong') {
                      pesananBerjalan++;
                    }
                    if (status == 'Selesai' || status == 'Selesai & Dinilai') {
                      var harga = data['harga'];
                      if (harga is int) {
                        totalTransaksi += harga;
                      } else if (harga is String) {
                        totalTransaksi += int.tryParse(harga) ?? 0;
                      }
                    }
                  }
                }

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildStatCard(
                      context,
                      title: 'Total Pengguna',
                      value: '$totalUsers',
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Pesanan Berjalan',
                      value: '$pesananBerjalan',
                      icon: Icons.sync,
                      color: Colors.orange,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Total Transaksi',
                      value: 'Rp $totalTransaksi',
                      icon: Icons.account_balance_wallet,
                      color: Colors.green,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Laporan Isu',
                      value: '0',
                      icon: Icons.warning,
                      color: Colors.red,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: Theme.of(context).cardTheme.elevation ?? 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aktivitas Terkini',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pesanan_tolong')
              .orderBy('timestamp', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Belum ada aktivitas.'),
                ),
              );
            }

            return Card(
              elevation: Theme.of(context).cardTheme.elevation ?? 2,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  String title = 'Pesanan "${data['judul']}" status: ${data['status']}';
                  
                  // Handle timestamp
                  String time = 'Baru saja';
                  if (data['timestamp'] != null) {
                    DateTime dt = (data['timestamp'] as Timestamp).toDate();
                    Duration diff = DateTime.now().difference(dt);
                    if (diff.inMinutes < 60) {
                      time = '${diff.inMinutes} menit lalu';
                    } else if (diff.inHours < 24) {
                      time = '${diff.inHours} jam lalu';
                    } else {
                      time = '${diff.inDays} hari lalu';
                    }
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                      child: const Icon(Icons.notifications_none, color: AppTheme.primaryBlue, size: 20),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      time,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
