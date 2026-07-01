import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ui_kerangka/app_theme.dart';

class ResolutionCenterScreen extends StatefulWidget {
  const ResolutionCenterScreen({Key? key}) : super(key: key);

  @override
  State<ResolutionCenterScreen> createState() => _ResolutionCenterScreenState();
}

class _ResolutionCenterScreenState extends State<ResolutionCenterScreen> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Sedang Berjalan', 'Selesai', 'Bermasalah'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Resolusi (Transaksi)'),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pesanan_tolong').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Tidak ada transaksi.'));
                }

                List<QueryDocumentSnapshot> docs = snapshot.data!.docs.toList();
                
                // Sort locally since some docs use 'timestamp' and some use 'createdAt'
                docs.sort((a, b) {
                  var dataA = a.data() as Map<String, dynamic>;
                  var dataB = b.data() as Map<String, dynamic>;
                  Timestamp? timeA = dataA['createdAt'] ?? dataA['timestamp'];
                  Timestamp? timeB = dataB['createdAt'] ?? dataB['timestamp'];
                  if (timeA == null && timeB == null) return 0;
                  if (timeA == null) return 1;
                  if (timeB == null) return -1;
                  return timeB.compareTo(timeA); // descending
                });

                List<Map<String, dynamic>> filteredTransactions = [];

                for (var doc in docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  String status = data['status'] ?? '';
                  String mappedStatus = 'Sedang Berjalan';

                  if (status.contains('Selesai')) {
                    mappedStatus = 'Selesai';
                  } else if (status.contains('Batal') || status.contains('Bermasalah')) {
                    mappedStatus = 'Bermasalah';
                  }

                  if (_selectedFilter == 'Semua' || _selectedFilter == mappedStatus) {
                    filteredTransactions.add({
                      'id': doc.id,
                      'consumer': data['konsumen_uid']?.substring(0, 5) ?? 'Anonim', // Simplified
                      'helper': data['penolong_uid']?.substring(0, 5) ?? 'Belum ada',
                      'status': mappedStatus,
                      'real_status': status,
                      'price': data['harga'] != null ? 'Rp ${data['harga']}' : 'Rp 50000',
                      'judul': data['judul'] ?? data['kategoriKeahlian'] ?? 'Tanpa Judul',
                    });
                  }
                }

                return _buildTransactionList(filteredTransactions);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryBlue,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryBlue : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) {
      return const Center(child: Text('Tidak ada transaksi untuk filter ini.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final trx = transactions[index];
        return _buildTransactionCard(trx);
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> trx) {
    Color statusColor;
    switch (trx['status']) {
      case 'Selesai':
        statusColor = Colors.green;
        break;
      case 'Bermasalah':
        statusColor = Colors.red;
        break;
      case 'Sedang Berjalan':
      default:
        statusColor = Colors.orange;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Memuat detail transaksi ${trx['id']} dari server...')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    trx['id'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      trx['real_status'] ?? trx['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pekerjaan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(trx['judul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Harga', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(trx['price'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                  ),
                ],
              ),
              if (trx['issue'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trx['issue'],
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
