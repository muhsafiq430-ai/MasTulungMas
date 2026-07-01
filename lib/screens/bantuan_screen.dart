import 'package:flutter/material.dart';
import '../ui_kerangka/app_theme.dart';

class BantuanScreen extends StatelessWidget {
  const BantuanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Bantuan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text(
            'Ada yang bisa kami bantu?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildFaqCard(
            context,
            'Bagaimana cara memesan bantuan?',
            'Masuk ke halaman utama, klik "Cari Penolong", lalu isi form pemesanan dengan detail bantuan, lokasi, dan tawaran harga.',
          ),
          _buildFaqCard(
            context,
            'Bagaimana cara pembayaran bekerja?',
            'Setelah penolong menerima pesanan Anda, tombol "Bayar Sekarang" akan muncul. Anda akan diarahkan ke sistem Midtrans untuk melakukan pembayaran yang aman.',
          ),
          _buildFaqCard(
            context,
            'Apa yang terjadi jika penolong tidak datang?',
            'Anda dapat melaporkan masalah melalui menu transaksi atau menghubungi admin. Dana Anda akan dikembalikan jika terbukti penolong tidak menyelesaikan tugas.',
          ),
          const SizedBox(height: 32),
          const Text('Hubungi Kami', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.email, color: AppTheme.primaryBlue),
            title: const Text('Email Support'),
            subtitle: const Text('support@mastulungmas.com'),
            tileColor: Colors.grey[100],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.phone, color: Colors.green),
            title: const Text('WhatsApp Admin'),
            subtitle: const Text('+62 812 3456 7890'),
            tileColor: Colors.grey[100],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqCard(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(answer, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
