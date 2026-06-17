import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String idPesanan; // ID unik untuk membedakan ruang chat setiap orderan

  const ChatScreen({super.key, required this.idPesanan});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _pesanController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // ==========================================
  // BACKEND LOGIC: KIRIM PESAN KE FIRESTORE
  // ==========================================
  void _kirimPesan() async {
    if (_pesanController.text.trim().isEmpty) return;

    String pesan = _pesanController.text.trim();
    _pesanController
        .clear(); // Bersihkan kolom ketik segera setelah tombol ditekan

    try {
      // Menyimpan pesan ke sub-koleksi 'messages' di dalam dokumen pesanan
      await FirebaseFirestore.instance
          .collection('pesanan_tolong')
          .doc(widget.idPesanan)
          .collection('messages')
          .add({
            'pengirimId': _currentUser?.uid,
            'teks': pesan,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Gagal mengirim pesan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ruang Obrolan')),
      body: Column(
        children: [
          // ==========================================
          // BACKEND LOGIC: BACA PESAN REAL-TIME
          // ==========================================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pesanan_tolong')
                  .doc(widget.idPesanan)
                  .collection('messages')
                  .orderBy(
                    'timestamp',
                    descending: true,
                  ) // Urutkan pesan terbaru di bawah
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada pesan. Sapa sekarang!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse:
                      true, // Membalik daftar agar chat scroll dari bawah ke atas
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msg = messages[index];
                    bool isMe = msg['pengirimId'] == _currentUser?.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 12,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isMe ? 12 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 12),
                          ),
                        ),
                        child: Text(msg['teks'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // AREA INPUT KETIK PESAN
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pesanController,
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _kirimPesan,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
