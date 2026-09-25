import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uktplqoiugaudoikkby.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVrdHBscW9pdWdhdWRvaWtiYnkiLCJuYW1lIjoiU3VwYWJhc2UgUHJvamVjdCIsInJvbGUiOiJhbm9uIn0.8A5ZQzXyC12vF0sQZfY5JQeKdL2XqM7s9tK6vR7eN8',
  );

  runApp(const TeguhAiApp());
}

class TeguhAiApp extends StatelessWidget {
  const TeguhAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeguhAi',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session != null) return const MainScaffold();
        return const LoginScreen();
      },
    );
  }
}

// ===================== LAYAR MASUK / DAFTAR =====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoginMode = true;
  bool _isForgotMode = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isLoading = false;

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(teks),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _daftar() async {
    if (_passCtrl.text != _confirmPassCtrl.text) {
      _pesan('Sandi tidak cocok! ❌');
      return;
    }
    if (_passCtrl.text.length < 6) {
      _pesan('Sandi minimal 6 karakter!');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        data: {'username': _usernameCtrl.text.trim()},
      );
      _pesan('Berhasil daftar! ✅ Silakan masuk');
      setState(() => _isLoginMode = true);
    } catch (e) {
      _pesan('Gagal daftar: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _masuk() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
    } catch (e) {
      _pesan('Gagal masuk: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _kirimReset() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _pesan('Isi email dulu!');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailCtrl.text.trim(),
      );
      _pesan('Kode dikirim! Cek email ✅');
      setState(() => _isForgotMode = false);
    } catch (e) {
      _pesan('Gagal: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.psychology, size: 70, color: Colors.green),
                const SizedBox(height: 12),
                const Text('TeguhAi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 24),

                if (_isForgotMode) ...[
                  const Text('Lupa Kata Sandi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _kirimReset,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isLoading ? 'Mengirim...' : 'Kirim Kode', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isForgotMode = false),
                    child: const Text('← Kembali'),
                  ),
                ] else ...[
                  Text(
                    _isLoginMode ? 'Masuk ke Akun' : 'Daftar Akun Baru',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  if (!_isLoginMode)
                    TextField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Pengguna',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                  if (!_isLoginMode) const SizedBox(height: 12),

                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (!_isLoginMode)
                    TextField(
                      controller: _confirmPassCtrl,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Ulangi Sandi',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                  if (!_isLoginMode) const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : (_isLoginMode ? _masuk : _daftar),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _isLoading ? 'Memproses...' : (_isLoginMode ? 'Masuk' : 'Daftar'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_isLoginMode)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => _isForgotMode = true),
                        child: const Text('Lupa Kata Sandi?'),
                      ),
                    ),

                  TextButton(
                    onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                    child: Text(_isLoginMode
                        ? 'Belum punya akun? Daftar Baru'
                        : 'Sudah punya akun? Masuk Sini'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== LAYAR UTAMA =====================
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _layar = const [
    DaftarObrolanScreen(),
    PanggilanScreen(),
    VideoCallScreen(),
    PengaturanScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TeguhAi — Obrolan'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: _layar[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Obrolan'),
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Telp'),
          BottomNavigationBarItem(icon: Icon(Icons.videocam), label: 'Video'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
        ],
      ),
    );
  }
}

// ===================== DAFTAR OBROLAN =====================
class DaftarObrolanScreen extends StatefulWidget {
  const DaftarObrolanScreen({super.key});

  @override
  State<DaftarObrolanScreen> createState() => _DaftarObrolanScreenState();
}

class _DaftarObrolanScreenState extends State<DaftarObrolanScreen> {
  final _pencarianCtrl = TextEditingController();
  List<Map<String, dynamic>> _daftarPengguna = [];
  bool _sedangCari = false;

  Future<void> _cariPengguna(String kata) async {
    if (kata.isEmpty) {
      setState(() {
        _sedangCari = false;
        _daftarPengguna.clear();
      });
      return;
    }
    setState(() => _sedangCari = true);
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select()
          .ilike('username', '%$kata%')
          .limit(15);
      setState(() => _daftarPengguna = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal cari: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _pencarianCtrl,
            decoration: InputDecoration(
              labelText: 'Cari teman...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: _cariPengguna,
          ),
        ),

        Expanded(
          child: _sedangCari && _daftarPengguna.isNotEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _daftarPengguna.length,
                  itemBuilder: (ctx, i) {
                    final p = _daftarPengguna[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person, color: Colors.white)),
                      title: Text(p['username'] ?? 'Pengguna'),
                      subtitle: Text(p['email'] ?? ''),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(teman: p),
                          ),
                        );
                      },
                    );
                  },
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Cari teman dengan nama pengguna untuk mulai obrolan 💬',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// ===================== RUANG OBROLAN =====================
class ChatRoomScreen extends StatefulWidget {
  final Map<String, dynamic> teman;
  const ChatRoomScreen({super.key, required this.teman});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _pesanCtrl = TextEditingController();
  final _scrollKontrol = ScrollController();
  List<Map<String, dynamic>> _daftarPesan = [];
  bool _tampilEmoji = false;
  final ImagePicker _pilihGambar = ImagePicker();
  String? _idObrolan;

  @override
  void initState() {
    super.initState();
    _muatAtauBuatObrolan();
  }

  Future<void> _muatAtauBuatObrolan() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final temanId = widget.teman['id'];
    if (uid == null || temanId == null) return;

    try {
      // Cek obrolan sudah ada
      final cek = await Supabase.instance.client
          .from('conversations')
          .select()
          .or('and(user1_id.eq.$uid,user2_id.eq.$temanId),and(user1_id.eq.$temanId,user2_id.eq.$uid)')
          .maybeSingle();

      if (cek != null) {
        _idObrolan = cek['id'];
        _muatPesan();
      } else {
        // Buat baru
        final baru = await Supabase.instance.client.from('conversations').insert({
          'user1_id': uid,
          'user2_id': temanId,
        }).select().single();
        _idObrolan = baru['id'];
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kesalahan obrolan: $e')),
      );
    }
  }

  Future<void> _muatPesan() async {
    if (_idObrolan == null) return;
    try {
      final res = await Supabase.instance.client
          .from('messages')
          .select()
          .eq('conversation_id', _idObrolan!)
          .order('created_at', ascending: true);
      setState(() => _daftarPesan = List<Map<String, dynamic>>.from(res));
      _gulirBawah();
    } catch (e) {
      debugPrint('Gagal muat pesan: $e');
    }
  }

  Future<void> _kirimPesan({String? tipe, String? mediaUrl}) async {
    final teks = _pesanCtrl.text.trim();
    if (teks.isEmpty && mediaUrl == null) return;
    if (_idObrolan == null) return;

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await Supabase.instance.client.from('messages').insert({
        'conversation_id': _idObrolan,
        'sender_id': uid,
        'message_type': tipe ?? 'text',
        'content': teks.isNotEmpty ? teks : null,
        'media_url': mediaUrl,
      });

      // Perbarui info terakhir di obrolan
      await Supabase.instance.client.from('conversations').update({
        'last_message': teks.isNotEmpty ? teks : '[Gambar]',
        'last_message_time': DateTime.now().toIso8601String(),
      }).eq('id', _idObrolan!);

      _pesanCtrl.clear();
      _muatPesan();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal kirim: $e')),
      );
    }
  }

  Future<void> _pilihKirimGambar() async {
    final file = await _pilihGambar.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    _kirimPesan(tipe: 'image', mediaUrl: file.path);
  }

  void _gulirBawah() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollKontrol.hasClients) {
        _scrollKontrol.animateTo(
          _scrollKontrol.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.teman['username'] ?? 'Obrolan'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.phone), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Panggilan suara — Segera hadir 📞')),
            );
          }),
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Panggilan video — Segera hadir 📹')),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _idObrolan == null
                ? const Center(child: CircularProgressIndicator())
                : _daftarPesan.isEmpty
                    ? const Center(child: Text('Belum ada pesan. Sapa duluan! 👋'))
                    : ListView.builder(
                        controller: _scrollKontrol,
                        padding: const EdgeInsets.all(12),
                        itemCount: _daftarPesan.length,
                        itemBuilder: (ctx, i) {
                          final p = _daftarPesan[i];
                          final saya = p['sender_id'] == Supabase.instance.client.auth.currentUser?.id;
                          final waktu = p['created_at'] != null
                              ? DateFormat('HH:mm').format(D
