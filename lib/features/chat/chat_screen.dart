import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'emoji_picker_flutter.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _listenMessages();
  }

  void _listenMessages() {
    _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .limit(100)
        .listen((data) {
          if (mounted) {
            setState(() {
              _messages.clear();
              _messages.addAll(data);
            });
          }
        });
  }

  // === KIRIM TEKS + EMOJI ===
  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await _supabase.from('messages').insert({
      'content': text,
      'type': 'text',
      'sender_id': _supabase.auth.currentUser?.id,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    _messageController.clear();
    setState(() => _showEmojiPicker = false);
  }

  // === PILIH & KIRIM GAMBAR ===
  Future<void> _sendImage() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (picked == null) return;

    final fileName = 'chat-img-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageResponse = await _supabase.storage
        .from('chat-media')
        .upload(fileName, File(picked.path));
    
    final String imageUrl = _supabase.storage
        .from('chat-media')
        .getPublicUrl(fileName);

    await _supabase.from('messages').insert({
      'content': imageUrl,
      'type': 'image',
      'sender_id': _supabase.auth.currentUser?.id,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // === KIRIM GIF (LINK SAJA — TIDAK SIMPAN DI SERVER) ===
  Future<void> _sendGif(String gifUrl) async {
    await _supabase.from('messages').insert({
      'content': gifUrl,
      'type': 'gif',
      'sender_id': _supabase.auth.currentUser?.id,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // === KIRIM PDF / DOKUMEN — HANYA LINK & INFO, TIDAK SIMPAN DI SERVER ===
  Future<void> _sendDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
      withData: false, // TIDAK baca isi file — tetap di HP!
    );
    if (result == null) return;

    final file = result.files.first;
    
    // Kita kirim HANYA informasi & cara akses
    await _supabase.from('messages').insert({
      'content': jsonEncode({
        'name': file.name,
        'size': file.size,
        'path': file.path, // Jalur lokal di perangkat pengirim
        'extension': file.extension,
      }),
      'type': 'document',
      'sender_id': _supabase.auth.currentUser?.id,
      'created_at': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dokumen siap dibagikan — tetap di perangkatmu')),
      );
    }
  }

  // === TAMPILAN PESAN ===
  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isMe = msg['sender_id'] == _supabase.auth.currentUser?.id;
    final type = msg['type'] ?? 'text';
    final content = msg['content'] ?? '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.green.shade100 : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: _buildMessageContent(type, content),
      ),
    );
  }

  Widget _buildMessageContent(String type, dynamic content) {
    switch (type) {
      case 'text':
        return Text('$content', style: const TextStyle(fontSize: 16));
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network('$content', fit: BoxFit.cover, width: 200),
        );
      case 'gif':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network('$content', fit: BoxFit.cover, width: 200),
        );
      case 'document':
        final info = jsonDecode(content);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insert_drive_file, color: Colors.blue, size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${(info['size'] / 1024).toStringAsFixed(1)} KB',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // Buka dokumen dari perangkat penerima
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Membuka dokumen...')),
                );
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Buka Dokumen'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50),
            ),
          ],
        );
      default:
        return Text('$content');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obrolan & Panggilan'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Daftar Pesan
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Belum ada pesan 😊\nMulai obrolan sekarang!', textAlign: TextAlign.center))
                : ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = _messages.length - 1 - index;
                      return _buildMessageBubble(_messages[reversedIndex]);
                    },
                  ),
          ),

          // Pemilih Emoji
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _messageController.text += emoji.emoji;
                },
              ),
            ),

          // Kotak Ketik & Tombol
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Emoji
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined, size: 26),
                    onPressed: () {
                      setState(() => _showEmojiPicker = !_showEmojiPicker);
                    },
                  ),
                  // Gambar
                  IconButton(
                    icon: const Icon(Icons.image_outlined, size: 26, color: Colors.green),
                    onPressed: _sendImage,
                  ),
                  // GIF
                  IconButton(
                    icon: const Icon(Icons.gif_box_outlined, size: 26, color: Colors.purple),
                    onPressed: () {
                      // Nanti kita sambungkan dengan pencari GIF ringan
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pencari GIF akan segera hadir! 🎬')),
                      );
                    },
                  ),
                  // Dokumen
                  IconButton(
                    icon: const Icon(Icons.attach_file_outlined, size: 26, color: Colors.orange),
                    onPressed: _sendDocument,
                  ),
                  // Kotak Teks
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Ketik pesan...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  // Kirim
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.green, size: 26),
                    onPressed: _sendText,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
