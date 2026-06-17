import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'konsumen';
  bool _isLoading = false;

  // BACKEND LOGIC: Array untuk menyimpan LEBIH DARI SATU keahlian
  final List<String> _daftarKeahlian = [
    'Listrik',
    'Air',
    'Mesin',
    'Pertukangan',
    'Umum',
  ];
  List<String> _selectedKeahlianList = [];

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _prosesRegistrasi() async {
    if (_namaController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _whatsappController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua kolom wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi khusus jika penolong tidak memilih keahlian sama sekali
    if (_selectedRole == 'penolong' && _selectedKeahlianList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penolong wajib memilih minimal 1 keahlian!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      String uid = userCredential.user!.uid;

      Map<String, dynamic> userData = {
        'uid': uid,
        'nama': _namaController.text.trim(),
        'email': _emailController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'role': _selectedRole,
        'latitude': -7.587,
        'longitude': 110.829,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // BACKEND LOGIC: Simpan list keahlian sebagai Array di Firestore
      if (_selectedRole == 'penolong') {
        userData['keahlian'] = _selectedKeahlianList;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registrasi $_selectedRole Berhasil! Silakan Login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Terjadi kesalahan autentikasi'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan data ke database'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MasTulungMas - Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'REGISTRASI AKUN BARU',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor WhatsApp',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Daftar Sebagai',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'konsumen',
                    child: Text('Konsumen (Masyarakat)'),
                  ),
                  DropdownMenuItem(
                    value: 'penolong',
                    child: Text('Penolong (Mitra Teknisi)'),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedRole = val!;
                    // Bersihkan pilihan jika pindah ke konsumen
                    if (_selectedRole == 'konsumen')
                      _selectedKeahlianList.clear();
                  });
                },
              ),

              // UI MULTI-SELECT KEAHLIAN MENGGUNAKAN FILTERCHIP
              if (_selectedRole == 'penolong') ...[
                const SizedBox(height: 15),
                const Text(
                  'Pilih Keahlian Anda (Bisa lebih dari 1):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: _daftarKeahlian.map((keahlian) {
                    return FilterChip(
                      label: Text(keahlian),
                      selected: _selectedKeahlianList.contains(keahlian),
                      selectedColor: Colors.blue[100],
                      checkmarkColor: Colors.blue,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedKeahlianList.add(keahlian);
                          } else {
                            _selectedKeahlianList.remove(keahlian);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 25),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _prosesRegistrasi,
                      child: const Text(
                        'DAFTAR SEKARANG',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                ),
                child: const Text('Sudah punya akun? Masuk di sini'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
