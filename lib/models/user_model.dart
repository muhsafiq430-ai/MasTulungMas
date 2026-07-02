class UserModel {
  final String uid;
  final String namaLengkap;
  final String email;
  final String nim;
  final String? whatsapp;
  final String role; // 'admin' atau 'mahasiswa'

  UserModel({
    required this.uid,
    required this.namaLengkap,
    required this.email,
    required this.nim,
    this.whatsapp,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      namaLengkap: map['nama'] ?? '',
      email: map['email'] ?? '',
      nim: map['nim'] ?? '',
      whatsapp: map['whatsapp'],
      role: map['role'] ?? 'mahasiswa',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': namaLengkap,
      'email': email,
      'nim': nim,
      'whatsapp': whatsapp,
      'role': role,
    };
  }
}
