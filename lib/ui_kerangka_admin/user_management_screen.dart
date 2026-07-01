import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ui_kerangka/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // Data dari Firestore

  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen Pengguna'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Konsumen'),
              Tab(text: 'Penolong'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStreamUserList('konsumen'),
            _buildStreamUserList('penolong'),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamUserList(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Tidak ada pengguna.'));
        }

        final users = snapshot.data!.docs;
        final isHelper = role == 'penolong';

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final doc = users[index];
            final data = doc.data() as Map<String, dynamic>;
            final id = doc.id;
            
            final name = data['name'] ?? 'Pengguna';
            final status = data['status'] ?? 'Aktif'; // Default Aktif
            final email = data['email'] ?? '';
            final bool isSuspend = status == 'Suspend';

            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                leading: const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSuspend ? Colors.red : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        color: isSuspend ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showUserDetailsDialog(context, id, data, isHelper: isHelper, isSuspend: isSuspend);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showUserDetailsDialog(BuildContext context, String uid, Map<String, dynamic> data, {required bool isHelper, required bool isSuspend}) {
    final name = data['name'] ?? 'Pengguna';
    final email = data['email'] ?? '-';
    final status = data['status'] ?? 'Aktif';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                isHelper ? 'Mitra Penolong' : 'Konsumen',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              // Detail Info
              _buildDetailRow('Email', email),
              _buildDetailRow('Status', status, valueColor: isSuspend ? Colors.red : Colors.green),
              
              const SizedBox(height: 32),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog
                    
                    try {
                      String newStatus = isSuspend ? 'Aktif' : 'Suspend';
                      await FirebaseFirestore.instance.collection('users').doc(uid).update({
                        'status': newStatus,
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Status $name berhasil diubah menjadi $newStatus'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal mengubah status: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  icon: Icon(isSuspend ? Icons.check_circle : Icons.block),
                  label: Text(isSuspend ? 'Aktifkan Kembali Akun' : 'Blokir / Suspend Akun'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuspend ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16), // Bottom padding
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
