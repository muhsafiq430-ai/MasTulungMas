import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'chat_screen.dart';

class PenolongDashboardScreen extends StatefulWidget {
  const PenolongDashboardScreen({super.key});

  @override
  State<PenolongDashboardScreen> createState() =>
      _PenolongDashboardScreenState();
}

class _PenolongDashboardScreenState extends State<PenolongDashboardScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  List<dynamic> _keahlianPenolongList = [];
  String _namaPenolong = '';
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _ambilProfilPenolong();
  }

  void _ambilProfilPenolong() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser?.uid)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _keahlianPenolongList = userDoc['keahlian'] ?? [];
          _namaPenolong = userDoc['nama'] ?? 'Tanpa Nama';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('Gagal mengambil profil penolong: $e');
      setState(() => _isLoadingProfile = false);
    }
  }

  void _terimaPekerjaan(String idPesanan) async {
    try {
      await FirebaseFirestore.instance
          .collection('pesanan_tolong')
          .doc(idPesanan)
          .update({
            'idPenolong': _currentUser?.uid,
            'namaPenolong': _namaPenolong,
            'status': 'Dalam Perjalanan',
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pekerjaan Diterima!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menerima: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selesaikanPekerjaan(String idPesanan) async {
    try {
      await FirebaseFirestore.instance
          .collection('pesanan_tolong')
          .doc(idPesanan)
          .update({'status': 'Selesai'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pekerjaan selesai! Menunggu ulasan konsumen.'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    String keahlianTeks = _keahlianPenolongList.join(', ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dasbor Penolong'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, $_namaPenolong!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Spesialisasi: $keahlianTeks',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // ==========================================
            // BAGIAN 1: ORDERAN BARU MASUK
            // ==========================================
            const Text(
              '1. ORDERAN MASUK YG COCOK (REAL-TIME)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 10),

            if (_keahlianPenolongList.isEmpty)
              const Text(
                'Anda belum memiliki keahlian terdaftar.',
                style: TextStyle(color: Colors.red),
              )
            else
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pesanan_tolong')
                    .where('status', isEqualTo: 'Mencari Penolong')
                    .where('kategoriKeahlian', whereIn: _keahlianPenolongList)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text(
                      'Belum ada orderan masuk yang cocok.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var order = snapshot.data!.docs[index];
                      // Ekstrak URL Foto jika ada
                      Map<String, dynamic> dataOrder =
                          order.data() as Map<String, dynamic>;
                      String fotoUrl = dataOrder.containsKey('fotoUrl')
                          ? dataOrder['fotoUrl']
                          : '';

                      return Card(
                        color: Colors.orange[50],
                        child: ListTile(
                          // Tampilkan Thumbnail jika ada foto
                          leading: fotoUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    fotoUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.build,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                          title: Text(
                            '[${order['kategoriKeahlian']}] ${order['deskripsiMasalah']}',
                          ),
                          subtitle: Text('Lokasi: ${order['alamat']}'),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            onPressed: () => _terimaPekerjaan(order.id),
                            child: const Text(
                              'AMBIL',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: 30),
            const Divider(thickness: 2),
            const SizedBox(height: 10),

            // ==========================================
            // BACKEND LOGIC: AMBIL SEMUA PEKERJAAN MILIK TUKANG INI
            // ==========================================
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pesanan_tolong')
                  .where('idPenolong', isEqualTo: _currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var semuaTugas = snapshot.hasData ? snapshot.data!.docs : [];

                var tugasAktif = semuaTugas
                    .where((doc) => doc['status'] == 'Dalam Perjalanan')
                    .toList();
                var riwayatSelesai = semuaTugas
                    .where(
                      (doc) =>
                          doc['status'] == 'Selesai' ||
                          doc['status'] == 'Selesai & Dinilai',
                    )
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // BAGIAN 2: TUGAS AKTIF
                    // ==========================================
                    const Text(
                      '2. TUGAS AKTIF YANG KAMU AMBIL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (tugasAktif.isEmpty)
                      const Text(
                        'Tidak ada tugas aktif.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tugasAktif.length,
                      itemBuilder: (context, index) {
                        var order = tugasAktif[index];
                        Map<String, dynamic> dataOrder =
                            order.data() as Map<String, dynamic>;
                        String fotoUrl = dataOrder.containsKey('fotoUrl')
                            ? dataOrder['fotoUrl']
                            : '';

                        return Card(
                          color: Colors.blue[50],
                          child: ListTile(
                            leading: fotoUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      fotoUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.build,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                            title: Text(
                              'Masalah: ${order['deskripsiMasalah']}',
                            ),
                            subtitle: Text(
                              'Alamat: ${order['alamat']}\nStatus: ${order['status']}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.chat,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChatScreen(idPesanan: order.id),
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () =>
                                      _selesaikanPekerjaan(order.id),
                                  child: const Text(
                                    'SELESAI',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                    const Divider(thickness: 2),
                    const SizedBox(height: 10),

                    // ==========================================
                    // BAGIAN 3: RIWAYAT PEKERJAAN
                    // ==========================================
                    const Text(
                      '3. RIWAYAT PEKERJAAN (SELESAI)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (riwayatSelesai.isEmpty)
                      const Text(
                        'Belum ada riwayat pekerjaan.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: riwayatSelesai.length,
                      itemBuilder: (context, index) {
                        var order = riwayatSelesai[index];
                        bool sudahDinilai =
                            order['status'] == 'Selesai & Dinilai';
                        Map<String, dynamic> dataOrder =
                            order.data() as Map<String, dynamic>;
                        String fotoUrl = dataOrder.containsKey('fotoUrl')
                            ? dataOrder['fotoUrl']
                            : '';

                        return Card(
                          color: Colors.green[50],
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: fotoUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      fotoUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.build,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                            title: Text('${order['deskripsiMasalah']}'),
                            subtitle: sudahDinilai
                                ? Text(
                                    'Lokasi: ${order['alamat']}\nUlasan: "${order['teksUlasan']}"',
                                  )
                                : Text(
                                    'Lokasi: ${order['alamat']}\n(Menunggu Ulasan Konsumen)',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                    ),
                                  ),
                            trailing: sudahDinilai
                                ? Text(
                                    '${order['ratingBintang']} ⭐',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.orange,
                                    ),
                                  )
                                : const Icon(
                                    Icons.hourglass_bottom,
                                    color: Colors.orange,
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
