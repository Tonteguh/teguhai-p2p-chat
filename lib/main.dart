import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/chat/chat_screen.dart';

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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // === MODE ===
  bool _isLoginMode = true;
  bool _isForgotMode = false;
  bool _isVerifyMode = false;
  
  // === PILIHAN KIRIM OTP ===
  int? _otpChannel; // 0=WA, 1=SMS, 2=Email

  // === SANDI MATA ===
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // === INPUT ===
  final TextEditingController _kontakController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String? _nomorTersimpan;
  String? _emailTersimpan;
  bool _isLoading = false;

  // === NORMALISASI NOMOR HP ===
  String _formatNoHp(String input) {
    String no = input.trim();
    if (no.startsWith('0')) no = no.substring(1);
    if (!no.startsWith('+')) no = '+62$no';
    return no;
  }

  // === KIRIM OTP BERDASARKAN PILIHAN ===
  Future<void> _kirimOTP() async {
    final kontak = _kontakController.text.trim();
    if (kontak.isEmpty || _otpChannel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi kontak & pilih cara kirim kode')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_otpChannel == 2) {
        // EMAIL
        await Supabase.instance.client.auth.resetPasswordForEmail(kontak);
        _emailTersimpan = kontak;
      } else {
        // WA atau SMS — pakai nomor HP
        final noHp = _formatNoHp(kontak);
        await Supabase.instance.client.auth.signInWithOtp(phone: noHp);
        _nomorTersimpan = noHp;
      }

      setState(() => _isVerifyMode = true);

      String cara = '';
      switch (_otpChannel) {
        case 0: cara = 'WhatsApp'; break;
        case 1: cara = 'SMS'; break;
        case 2: cara = 'Email'; break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kode dikirim lewat $cara ✅ Cek segera!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal kirim: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  // === VERIFIKASI OTP ===
  Future<void> _cekOTP() async {
    final kode = _otpController.text.trim();
    if (kode.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      if (_otpChannel == 2 && _emailTersimpan != null) {
        // Email — untuk reset, langsung lanjut buat sandi baru
        await Supabase.instance.client.auth.verifyOTP(
          email: _emailTersimpan!,
          token: kode,
          type: OtpType.recovery,
        );
      } else if (_nomorTersimpan != null) {
        // HP — WA/SMS
        await Supabase.instance.client.auth.verifyOTP(
          phone: _nomorTersimpan!,
          token: kode,
          type: OtpType.sms,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kode salah/kadaluarsa: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  // === DAFTAR ===
  Future<void> _daftar() async {
    if (_passController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sandi tidak cocok! ❌')),
      );
      return;
    }
    if (_passController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sandi minimal 6 karakter')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final nama = _namaController.text.trim();
      final kontak = _kontakController.text.trim();

      if (kontak.contains('@')) {
        // Daftar pakai Email
        await Supabase.instance.client.auth.signUp(
          email: kontak,
          password: _passController.text,
          data: {'name': nama},
        );
      } else {
        // Daftar pakai No HP
        await Supabase.instance.client.auth.signUp(
          phone: _formatNoHp(kontak),
          password: _passController.text,
          data: {'name': nama},
        );
      }

      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': uid,
          'name': nama,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil daftar! 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal daftar: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  // === MASUK ===
  Future<void> _masuk() async {
    setState(() => _isLoading = true);
    try {
      final kontak = _kontakController.text.trim();

      if (kontak.contains('@')) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: kontak,
          password: _passController.text,
        );
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          phone: _formatNoHp(kontak),
          password: _passController.text,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal masuk: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.psychology, size: 70, color: Colors.green),
                const SizedBox(height: 12),
                const Text('TeguhAi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 24),

                // === LAYAR VERIFIKASI OTP ===
                if (_isVerifyMode) ...[
                  const Text('Masukkan Kode OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Kode dikirim lewat ${_otpChannel == 0 ? "WhatsApp" : _otpChannel == 1 ? "SMS" : "Email"}',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 10),
                    decoration: const InputDecoration(
                      labelText: 'Kode 6 angka',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        await _cekOTP();
                        // Kalau dari lupa sandi & berhasil → tampilkan buat sandi baru
                        if (_isForgotMode && Supabase.instance.client.auth.currentUser != null) {
                          setState(() {
                            _isVerifyMode = false;
                            // Tetap di lupa mode untuk ubah sandi
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isLoading ? 'Memproses...' : 'Verifikasi Kode', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isVerifyMode = false;
                        _otpChannel = null;
                      });
                    },
                    child: const Text('← Kembali'),
                  ),

                // === LAYAR LUPA SANDI — PILIHAN KIRIM ===
                ] else if (_isForgotMode) ...[
                  const Text('Lupa Kata Sandi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Masukkan nomor atau email, lalu pilih cara kirim kode',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _kontakController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor HP / Email',
                      prefixIcon: Icon(Icons.alternate_email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      hintText: '0812... atau email@contoh.com',
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Pilih cara terima kode:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  // === 3 PILIHAN ===
                  _buildPilihanOTP(0, '💬 WhatsApp'),
                  const SizedBox(height: 8),
                  _buildPilihanOTP(1, '📱 SMS'),
                  const SizedBox(height: 8),
                  _buildPilihanOTP(2, '✉️ Email'),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _kirimOTP,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isLoading ? 'Mengirim...' : 'Kirim Kode', style: const TextStyle(fontSize: 16)),
                    ),
                  ),

                  // === BUAT SANDI BARU JIKA SUDAH VERIFIKASI ===
                  if (Supabase.instance.client.auth.currentUser != null) ...[
                    const SizedBox(height: 24),
                    const Text('Buat Sandi Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passController,
                      obscureText: _obscurePass,
                      decoration: InputDecoration(
                        labelText: 'Sandi Baru',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPassController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Ulangi Sandi Baru',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () async {
                          if (_passController.text == _confirmPassController.text) {
                            setState(() => _isLoading = true);
                            try {
                              await Supabase.instance.client.auth.updateUser(
                                UserAttributes(password: _passController.text),
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sandi berhasil diubah! ✅')),
                                );
                                setState(() {
                                  _isForgotMode = false;
                                  _isLoginMode = true;
                                });
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal ubah sandi: $e')),
                                );
                              }
                            }
                            setState(() => _isLoading = false);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sandi tidak cocok!')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Simpan Sandi Baru', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],

                  TextButton(
                    onPressed: () => setState(() {
                      _isForgotMode = false;
                      _otpChannel = null;
                    }),
                    child: const Text('← Kembali ke Masuk'),
                  ),

                // === LAYAR UTAMA — MASUK / DAFTAR ===
                ] else ...[
                  Text(_isLoginMode ? 'Masuk ke Akun' : 'Daftar Akun Baru',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  if (!_isLoginMode) ...[
                    TextField(
                      controller: _namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: _kontakController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor HP / Email',
                      prefixIcon: Icon(Icons.contact_page),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      hintText: '0812... atau email@contoh.com',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _passController,
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
                      controller: _confirmPassController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Kata Sandi',
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.cir
