import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http; // Pustaka API
import 'dart:convert'; // Pustaka JSON
import 'package:url_launcher/url_launcher.dart'; // Pustaka Buka Tab Baru

import 'login_screen.dart';
import 'chat_screen.dart';

class PenggunaDashboardScreen extends StatefulWidget {
  const PenggunaDashboardScreen({super.key});

  @override
  State<PenggunaDashboardScreen> createState() =>
      _PenggunaDashboardScreenState();
}

class _PenggunaDashboardScreenState extends State<PenggunaDashboardScreen> {
  final _deskripsiController = TextEditingController();
  final _alamatController = TextEditingController();
  String _selectedKategori = 'Listrik';
  bool _isSending = false;
  bool _isLoadingGPS = false;

  Uint8List? _imageBytes;

  double _currentLatitude = -7.587;
  double _currentLongitude = 110.829;

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _deskripsiController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  // ===================================================
  // LOGIKA GPS
  // ===================================================
  Future<void> _ambilLokasiGPS() async {
    setState(() => _isLoadingGPS = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Layanan GPS mati. Silakan aktifkan GPS perangkat Anda.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Izin akses lokasi ditolak oleh pengguna.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Izin lokasi ditolak permanen. Silakan ubah di pengaturan perangkat.';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentLatitude,
          _currentLongitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark tempat = placemarks[0];
          String alamatLengkap =
              "${tempat.street}, ${tempat.subLocality}, ${tempat.locality}, ${tempat.subAdministrativeArea}\n(Lat: $_currentLatitude, Lng: $_currentLongitude)";
          _alamatController.text = alamatLengkap;
        }
      } catch (e) {
        _alamatController.text =
            "Lokasi GPS: ($_currentLatitude, $_currentLongitude)";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi berhasil diambil otomatis!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingGPS = false);
    }
  }

  Future<void> _pilihGambar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800, // Membatasi ukuran gambar agar tidak terlalu besar
      maxHeight: 800,
    );

    if (pickedFile != null) {
      var bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  // ===================================================
  // LOGIKA PEMBAYARAN MIDTRANS
  // ===================================================
  Future<void> _prosesPembayaran(String idPesanan) async {
    // Gunakan 10.0.2.2 jika di emulator Android, 127.0.0.1 jika di Web/Desktop
    String baseUrl = 'http://127.0.0.1:5000';
    if (Theme.of(context).platform == TargetPlatform.android) {
      baseUrl = 'http://10.0.2.2:5000';
    }
    final url = Uri.parse('$baseUrl/api/get-token');

    // Mengirim ID Pesanan asli dari Firestore ke Midtrans
    final body = jsonEncode({
      "order_id": idPesanan,
      "gross_amount": 50000, // Nominal flat sementara untuk MVP
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception("Koneksi ke server pembayaran timeout.");
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String token = data['token'];

        final midtransUrl = Uri.parse(
          'https://app.sandbox.midtrans.com/snap/v2/vtweb/$token',
        );

        if (await canLaunchUrl(midtransUrl)) {
          await launchUrl(midtransUrl);
        } else {
          debugPrint("Tidak bisa membuka halaman pembayaran.");
        }
      } else {
        debugPrint("Gagal mendapat token: ${response.body}");
      }
    } catch (e) {
      debugPrint("Terjadi kesalahan jaringan Midtrans: $e");
    }
  }

  // ===================================================
  // LOGIKA PENGIRIMAN DATA
  // ===================================================
  void _kirimPermintaanTolong() async {
    if (_deskripsiController.text.trim().isEmpty ||
        _alamatController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Detail masalah dan Alamat wajib diisi!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      String imageUrl = '';

      if (_imageBytes != null) {
        String namaFileTunik = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('foto_kerusakan')
            .child(namaFileTunik);

        // Menambahkan metadata dan timeout untuk mencegah infinite loop saat upload
        UploadTask uploadTask = ref.putData(
          _imageBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        await uploadTask.timeout(const Duration(seconds: 30), onTimeout: () {
          throw Exception("Gagal mengunggah foto: Timeout. Periksa koneksi internet Anda.");
        });

        imageUrl = await ref.getDownloadURL();
      }

      // Simpan data ke Firestore dan tangkap DocumentReference-nya
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('pesanan_tolong')
          .add({
            'idPengguna': _currentUser?.uid,
            'idPenolong': '',
            'namaPenolong': '',
            'kategoriKeahlian': _selectedKategori,
            'deskripsiMasalah': _deskripsiController.text.trim(),
            'alamat': _alamatController.text.trim(),
            'latitude': _currentLatitude,
            'longitude': _currentLongitude,
            'fotoUrl': imageUrl,
            'status':
                'Menunggu Pembayaran', // Status diubah agar aman dari penolong
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Bersihkan formulir
      _deskripsiController.clear();
      _alamatController.clear();
      setState(() => _imageBytes = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mengalihkan ke halaman pembayaran...'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // EKSEKUSI MIDTRANS MENGGUNAKAN ID DARI FIRESTORE
      await _prosesPembayaran(docRef.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _tampilkanDialogUlasan(String idPesanan, String namaPenolong) {
    int rating = 5;
    TextEditingController ulasanController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Pekerjaan Selesai! 🎉'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Beri penilaian untuk $namaPenolong:'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: rating,
                    decoration: const InputDecoration(
                      labelText: 'Bintang (1-5)',
                      border: OutlineInputBorder(),
                    ),
                    items: [1, 2, 3, 4, 5].map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(
                          '$e ⭐',
                          style: const TextStyle(color: Colors.orange),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() => rating = val!);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: ulasanController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Tulis Ulasan Singkat',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
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
                    if (context.mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MasTulungMas - Konsumen'),
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
            const Text(
              'FORM PANGGILAN PERTOLONGAN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: _selectedKategori,
              decoration: const InputDecoration(
                labelText: 'Pilih Kategori Kendala',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Listrik',
                  child: Text('Masalah Listrik'),
                ),
                DropdownMenuItem(
                  value: 'Air',
                  child: Text('Masalah Air & Pipa'),
                ),
                DropdownMenuItem(
                  value: 'Mesin',
                  child: Text('Masalah Mesin / Elektronik'),
                ),
                DropdownMenuItem(
                  value: 'Pertukangan',
                  child: Text('Masalah Atap / Kayu'),
                ),
                DropdownMenuItem(
                  value: 'Umum',
                  child: Text('Bantuan Umum / Kegiatan Sehari-hari'),
                ),
              ],
              onChanged: (val) => setState(() => _selectedKategori = val!),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _deskripsiController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Detail Masalah',
                hintText: 'Contoh: Minta tolong...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _alamatController,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Lokasi Anda',
                      hintText: 'Klik tombol kanan untuk deteksi otomatis...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isLoadingGPS
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 28,
                        ),
                        tooltip: 'Ambil lokasi GPS otomatis',
                        onPressed: _ambilLokasiGPS,
                      ),
              ],
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.image, color: Colors.grey, size: 40),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pilihGambar,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Pilih Foto Kerusakan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            _isSending
                ? const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text(
                          'Menyimpan data & Membuka gerbang pembayaran...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _kirimPermintaanTolong,
                      child: const Text(
                        'BAYAR & SIARKAN PANGGILAN',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

            const SizedBox(height: 30),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pesanan_tolong')
                  .where('idPengguna', isEqualTo: _currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text(
                    'Belum ada riwayat pesanan.',
                    style: TextStyle(color: Colors.grey),
                  );
                }

                var semuaOrder = snapshot.data!.docs;
                var orderAktif = semuaOrder
                    .where((doc) => doc['status'] != 'Selesai & Dinilai')
                    .toList();
                var riwayatOrder = semuaOrder
                    .where((doc) => doc['status'] == 'Selesai & Dinilai')
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(thickness: 2),
                    const Text(
                      'ORDER AKTIF & MENUNGGU ULASAN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (orderAktif.isEmpty)
                      const Text(
                        'Tidak ada order aktif.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orderAktif.length,
                      itemBuilder: (context, index) {
                        var order = orderAktif[index];
                        String statusPekerjaan = order['status'];
                        String fotoUrl =
                            order.data().toString().contains('fotoUrl')
                            ? order['fotoUrl']
                            : '';

                        return Card(
                          color: statusPekerjaan == 'Selesai'
                              ? Colors.yellow[100]
                              : Colors.blue[50],
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
                            title: Text(
                              'Kategori: ${order['kategoriKeahlian']}',
                            ),
                            subtitle: Text(
                              'Masalah: ${order['deskripsiMasalah']}\nAlamat: ${order['alamat']}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (statusPekerjaan == 'Dalam Perjalanan')
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

                                if (statusPekerjaan == 'Selesai')
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _tampilkanDialogUlasan(
                                      order.id,
                                      order['namaPenolong'],
                                    ),
                                    child: const Text('Beri Ulasan'),
                                  )
                                else if (statusPekerjaan != 'Dalam Perjalanan')
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      statusPekerjaan,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    const Divider(thickness: 2),
                    const Text(
                      'RIWAYAT PESANAN (SELESAI)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (riwayatOrder.isEmpty)
                      const Text(
                        'Belum ada riwayat pekerjaan selesai.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: riwayatOrder.length,
                      itemBuilder: (context, index) {
                        var order = riwayatOrder[index];
                        return Card(
                          color: Colors.green[50],
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text('${order['deskripsiMasalah']}'),
                            subtitle: Text(
                              'Dikerjakan oleh: ${order['namaPenolong']}\nUlasan: "${order['teksUlasan']}"',
                            ),
                            trailing: Text(
                              '${order['ratingBintang']} ⭐',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.orange,
                              ),
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
