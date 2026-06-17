import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_screen.dart';
import 'konsumen_dashboard_screen.dart';
import 'penolong_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===================================================
  // LOGIKA BACKEND: PROSES LOGIN & ROUTING BERDASARKAN ROLE
  // ===================================================
  void _prosesLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Password wajib diisi!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Validasi akun ke Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // 2. Ambil data dokumen user secara real-time dari Firestore koleksi 'users'
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists && mounted) {
        String role = userDoc['role'] ?? 'konsumen';

        // 3. PENGALIRAN HALAMAN (ROUTING) BERDASARKAN ROLE DATA
        if (role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()));
        } else if (role == 'penolong') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PenolongDashboardScreen()));
        } else {
          // Default diarahkan ke role konsumen
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PenggunaDashboardScreen()));
        }
      } else {
        throw Exception('Data peran pengguna tidak ditemukan di database.');
      }

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Gagal masuk, periksa kembali akun Anda'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MasTulungMas - Login Backend')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'MASUK KE SISTEM',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Input Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Alamat Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              // Input Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Kata Sandi', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 25),

              // Tombol Aksi Login
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _prosesLogin,
                      child: const Text('MASUK', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
              
              const SizedBox(height: 15),

              // Link ke Register
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                },
                child: const Text('Belum punya akun? Daftar baru di sini'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}