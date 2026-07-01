import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;
  String _selectedRole = 'konsumen'; // Default role
  String? _selectedKeahlian;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua field!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Buat akun di Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 2. Simpan data user ke Firestore
      Map<String, dynamic> userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      if (_selectedRole == 'penolong' && _selectedKeahlian != null) {
        userData['keahlian'] = _selectedKeahlian;
      }

      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);

      // 3. Jika berhasil, beri notifikasi dan kembali ke Login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Silakan login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Kembali ke halaman Login
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Terjadi kesalahan saat registrasi.';
      if (e.code == 'weak-password') {
        errorMessage = 'Password terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email sudah terdaftar.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Akun Baru', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      size: 72,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bergabung dengan MasTulungMas',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Form Card
                  Card(
                    elevation: 8,
                    shadowColor: primaryColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Name Field
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nama Lengkap',
                              prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Email Field
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Password Field
                          TextField(
                            controller: _passwordController,
                            obscureText: _isObscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscure ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isObscure = !_isObscure;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Role Selection
                          Text(
                            'Mendaftar Sebagai:',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: _selectedRole == 'konsumen' ? primaryColor : Colors.grey.shade300, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                    color: _selectedRole == 'konsumen' ? primaryColor.withOpacity(0.05) : Colors.transparent,
                                  ),
                                  child: RadioListTile<String>(
                                    title: Text('Konsumen', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                    value: 'konsumen',
                                    groupValue: _selectedRole,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedRole = value!;
                                      });
                                    },
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    activeColor: primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: _selectedRole == 'penolong' ? primaryColor : Colors.grey.shade300, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                    color: _selectedRole == 'penolong' ? primaryColor.withOpacity(0.05) : Colors.transparent,
                                  ),
                                  child: RadioListTile<String>(
                                    title: Text('Penolong', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                    value: 'penolong',
                                    groupValue: _selectedRole,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedRole = value!;
                                      });
                                    },
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    activeColor: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          if (_selectedRole == 'penolong') ...[
                            const SizedBox(height: 24),
                            DropdownButtonFormField<String>(
                              value: _selectedKeahlian,
                              decoration: InputDecoration(
                                labelText: 'Keahlian Utama',
                                prefixIcon: Icon(Icons.build_circle_outlined, color: primaryColor),
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
                                  _selectedKeahlian = value;
                                });
                              },
                              validator: (value) {
                                if (_selectedRole == 'penolong' && (value == null || value.isEmpty)) {
                                  return 'Keahlian wajib dipilih';
                                }
                                return null;
                              },
                            ),
                          ],
                          
                          const SizedBox(height: 32),
                          
                          // Register Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    'DAFTAR SEKARANG',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Back to Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sudah punya akun? ',
                                style: GoogleFonts.inter(color: Colors.grey.shade600),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Masuk di sini',
                                  style: GoogleFonts.inter(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
