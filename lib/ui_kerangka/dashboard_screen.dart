import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../screens/riwayat_konsumen_screen.dart';
import '../screens/saldo_konsumen_screen.dart';
import '../screens/bantuan_screen.dart';
import '../screens/chat_screen.dart';

enum OrderState { none, waiting, accepted }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _activeOrderId;

  @override
  void initState() {
    super.initState();
    _fetchActiveOrder();
  }

  Future<void> _fetchActiveOrder() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pesanan_tolong')
          .where('konsumen_uid', isEqualTo: uid)
          .get();
          
      if (snapshot.docs.isNotEmpty) {
        final activeStatuses = ['Menunggu Penolong', 'Diterima Penolong', 'Dalam Proses', 'Selesai'];
        
        final activeDocs = snapshot.docs.where((doc) {
          final data = doc.data();
          return activeStatuses.contains(data['status']);
        }).toList();
        
        if (activeDocs.isNotEmpty) {
          activeDocs.sort((a, b) {
            Timestamp tA = a.data()['createdAt'] as Timestamp? ?? Timestamp.now();
            Timestamp tB = b.data()['createdAt'] as Timestamp? ?? Timestamp.now();
            return tB.compareTo(tA);
          });
          
          if (mounted) {
            setState(() {
              _activeOrderId = activeDocs.first.id;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching active order: $e");
    }
  }

  Future<void> _prosesPembayaran(String idPesanan, int harga) async {
    String baseUrl = 'http://127.0.0.1:5000';
    if (Theme.of(context).platform == TargetPlatform.android) {
      baseUrl = 'http://127.0.0.1:5000'; // Menggunakan ADB Reverse untuk USB
    }
    final url = Uri.parse('$baseUrl/api/get-token');

    final body = jsonEncode({
      "order_id": idPesanan,
      "gross_amount": harga,
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

        try {
          // Optimistically update status to 'Dalam Proses' 
          await FirebaseFirestore.instance.collection('pesanan_tolong').doc(idPesanan).update({
            'status': 'Dalam Proses',
          });
          await launchUrl(midtransUrl, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint("Tidak bisa membuka halaman pembayaran: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak bisa membuka URL pembayaran.')),
            );
          }
        }
      } else {
        debugPrint("Gagal mendapat token: ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membuat transaksi: ${response.body}')),
          );
        }
      }
    } catch (e) {
      debugPrint("Terjadi kesalahan jaringan Midtrans: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal terhubung ke Midtrans: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: Text('Beranda', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: primaryColor,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(Icons.person_rounded, color: primaryColor),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .get(),
              builder: (context, snapshot) {
                String name = 'Pengguna';
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  name = data?['nama'] ?? data?['name'] ?? 'Pengguna';
                  
                  // Ambil nama depan saja agar tidak terlalu panjang
                  if (name.contains(' ')) {
                    name = name.split(' ')[0];
                  }
                }
                return Text(
                  'Halo, $name! 👋',
                  style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: primaryColor),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Mau cari bantuan apa hari ini?',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            
            // Dynamic Card for Active Order Status
            if (_activeOrderId != null) _buildActiveOrderCard(),
              
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    context, 
                    Icons.search_rounded, 
                    'Cari\nPenolong', 
                    Colors.blue.shade500,
                    Colors.blue.shade50,
                    onTap: () => _showBiddingForm(context),
                  ),
                  _buildMenuCard(
                    context, 
                    Icons.history_rounded, 
                    'Riwayat\nTransaksi', 
                    Colors.orange.shade500, 
                    Colors.orange.shade50,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RiwayatKonsumenScreen()),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context, 
                    Icons.account_balance_wallet_rounded, 
                    'Saldo\nDompet', 
                    Colors.green.shade500, 
                    Colors.green.shade50,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SaldoKonsumenScreen()),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context, 
                    Icons.help_outline_rounded, 
                    'Pusat\nBantuan', 
                    Colors.red.shade500, 
                    Colors.red.shade50,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BantuanScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard() {
    if (_activeOrderId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pesanan_tolong')
          .doc(_activeOrderId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Terjadi kesalahan memuat pesanan.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        String status = data['status'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: status == 'Menunggu Penolong' ? Colors.orange.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: status == 'Menunggu Penolong' ? Colors.orange.shade200 : Colors.green.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (status == 'Menunggu Penolong' ? Colors.orange : Colors.green).withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                if (status == 'Menunggu Penolong') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mencari Penolong', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.orange.shade800, fontSize: 16)),
                        Text('Sistem sedang mencarikan yang cocok...', style: GoogleFonts.inter(color: Colors.orange.shade700, fontSize: 13)),
                      ],
                    ),
                  ),
                ] else if (status == 'Diterima Penolong') ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Penolong Ditemukan!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 16)),
                        Text('Silakan selesaikan pembayaran.', style: GoogleFonts.inter(color: Colors.green.shade700, fontSize: 13)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chat_bubble_rounded, color: Theme.of(context).primaryColor),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(idPesanan: _activeOrderId!),
                            ),
                          );
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {
                          int harga = data['harga'] is int ? data['harga'] : int.tryParse(data['harga'].toString()) ?? 10000;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Menghubungkan ke Midtrans...')),
                          );
                          _prosesPembayaran(_activeOrderId!, harga).then((_) {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text('Bayar', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ] else if (status == 'Dalam Proses') ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.handyman_rounded, color: Colors.blue, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sedang Dikerjakan!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.blue.shade800, fontSize: 16)),
                        Text('Penolong sedang dalam perjalanan/mengerjakan.', style: GoogleFonts.inter(color: Colors.blue.shade700, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chat_bubble_rounded, color: Theme.of(context).primaryColor),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(idPesanan: _activeOrderId!),
                        ),
                      );
                    },
                  ),
                ] else if (status == 'Selesai') ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.star_rounded, color: Colors.orange, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pekerjaan Selesai!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.orange.shade800, fontSize: 16)),
                        Text('Jangan lupa beri ulasan.', style: GoogleFonts.inter(color: Colors.orange.shade700, fontSize: 13)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _tampilkanDialogUlasan(_activeOrderId!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('Ulas', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  void _tampilkanDialogUlasan(String idPesanan) {
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
                  const Text('Beri penilaian untuk penolong Anda:'),
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
                    
                    if (context.mounted) {
                      Navigator.pop(context); // Tutup dialog
                      setState(() => _activeOrderId = null); // Hilangkan kartu aktif
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

  Widget _buildMenuCard(BuildContext context, IconData icon, String title, Color iconColor, Color bgColor, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fitur belum tersedia')),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: iconColor.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: iconColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(icon, size: 36, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title, 
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  void _showBiddingForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return const BiddingFormSheet();
      },
    ).then((result) {
      if (result != null && result is String) {
        setState(() {
          _activeOrderId = result;
        });
      }
    });
  }
}

class BiddingFormSheet extends StatefulWidget {
  const BiddingFormSheet({super.key});

  @override
  State<BiddingFormSheet> createState() => _BiddingFormSheetState();
}

class _BiddingFormSheetState extends State<BiddingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedTime = 'Sekarang (Secepatnya)';

  Future<void> _ambilLokasiGPS() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Layanan Lokasi dinonaktifkan.')));
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin Lokasi ditolak.')));
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Izin Lokasi ditolak secara permanen.')));
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mencari lokasi...')));
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.street}, ${place.subLocality}, ${place.locality}";
        setState(() {
          _locationController.text = "$address (Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)})";
        });
      } else {
        setState(() {
          _locationController.text = "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mendapatkan lokasi: $e')));
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitBid() async {
    if (_formKey.currentState!.validate()) {
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) throw Exception("User tidak login");

        final priceText = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
        final price = int.tryParse(priceText) ?? 0;

        // Menyimpan data pesanan ke Firestore
        DocumentReference docRef = await FirebaseFirestore.instance.collection('pesanan_tolong').add({
          'judul': _selectedCategory ?? 'Lainnya',
          'deskripsi': _descController.text.trim(),
          'lokasi': _locationController.text.trim(),
          'waktu': _selectedTime,
          'harga': price,
          'status': 'Menunggu Penolong',
          'konsumen_uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permintaan berhasil dikirim!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, docRef.id); 
        }

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengirim pesanan: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // To handle keyboard overlap
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Form Pemesanan',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).primaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // 1. Judul / Kategori Bantuan
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Kategori Bantuan',
                  hintText: 'Pilih jenis bantuan',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Angkat Barang', child: Text('Angkat Barang')),
                  DropdownMenuItem(value: 'Bersih-bersih', child: Text('Bersih-bersih')),
                  DropdownMenuItem(value: 'Perbaikan Listrik/Air', child: Text('Perbaikan Listrik/Air')),
                  DropdownMenuItem(value: 'Belanja / Kurir', child: Text('Belanja / Kurir')),
                  DropdownMenuItem(value: 'Montir / Otomotif', child: Text('Montir / Otomotif')),
                  DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kategori bantuan wajib dipilih';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 2. Deskripsi Detail
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Deskripsi Detail',
                  hintText: 'Jelaskan detail bantuan yang dibutuhkan...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 32.0),
                    child: Icon(Icons.description_outlined),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 3. Lokasi / Patokan Alamat
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Lokasi / Patokan Alamat',
                  hintText: 'Masukkan alamat lengkap / patokan...',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.blue),
                    onPressed: _ambilLokasiGPS,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lokasi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 4. Waktu Pelaksanaan
              DropdownButtonFormField<String>(
                value: _selectedTime,
                decoration: InputDecoration(
                  labelText: 'Waktu Pelaksanaan',
                  prefixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['Sekarang (Secepatnya)', 'Jadwalkan Nanti']
                    .map((time) => DropdownMenuItem(
                          value: time,
                          child: Text(time),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    if (value != null) _selectedTime = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // 5. Tawaran Harga Jasa
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tawaran Harga Jasa',
                  hintText: 'Nominal jasa (Rp)',
                  prefixIcon: const Icon(Icons.attach_money),
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga tidak boleh kosong';
                  }
                  final priceText = value.replaceAll(RegExp(r'[^0-9]'), '');
                  final price = int.tryParse(priceText) ?? 0;
                  if (price < 10000) {
                    return 'Minimal tawaran harga adalah Rp 10.000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Tombol Aksi Utama
              ElevatedButton(
                onPressed: _submitBid,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Kirim Permintaan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
