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
  // === PILIHAN TAB ===
  int _selectedAuthTab = 0; // 0 = No HP, 1 = Email
  bool _isLoginMode = true;
  bool _isForgotMode = false;
  bool _isVerifyOtpMode = false;

  // === PENGATURAN SANDI MATA ===
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // === KONTROL INPUT ===
  final TextEditingController _noHpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String? _verificationId;
  String? _resetTarget;
  bool _isLoading = false;

  // === KIRIM OTP UNTUK DAFTAR/LOGIN ===
  Future<void> _sendOtp() async {
    final contact = _selectedAuthTab == 0 
        ? _noHpController.text.trim() 
        : _emailController.text.trim();
    if (contact.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (_selectedAuthTab == 0) {
        // Nomor HP — tambah kode +62 otomatis kalau belum ada
        String noHp = contact;
        if (!noHp.startsWith('+')) {
          if (noHp.startsWith('0')) noHp = noHp.substring(1);
          noHp = '+62$noHp';
        }
        await Supabase.instance.client.auth.signInWithOtp(phone: noHp);
      } else {
        // Email
        await Supabase.instance.client.auth.signInWithOtp(email: contact);
      }
      
      setState(() {
        _isVerifyOtpMode = true;
        _verificationId = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode dikirim! Cek SMS/Email kamu ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal kirim kode: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  // === VERIFIKASI OTP ===
  Future<void> _verifyOtp() async {
    final contact = _selectedAuthTab == 0 
        ? _noHpController.text.trim() 
        : _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (_selectedAuthTab == 0) {
        String noHp = contact;
        if (!noHp.startsWith('+')) {
          if (noHp.startsWith('0')) noHp = noHp.substring(1);
          noHp = '+62$noHp';
        }
        await Supabase.instance.client.auth.verifyOTP(
          phone: noHp,
          token: otp,
          type: OtpType.sms,
        );
      } else {
        await Supabase.instance.client.auth.verifyOTP(
          email: contact,
          token: otp,
          type: OtpType.magiclink,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kode salah atau kadaluarsa: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  // === DAFTAR PENUH DENGAN SANDI ===
  Future<void> _registerWithPassword() async {
    if (_passController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi tidak cocok! ❌')),
      );
      return;
    }
    if (_passController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi minimal 6 karakter!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final nama = _namaController.text.trim();
      
      if (_selectedAuthTab == 0) {
        String noHp = _noHpController.text.trim();
        if (!noHp.startsWith('+')) {
          if (noHp.startsWith('0')) noHp = noHp.substring(1);
          noHp = '+62$noHp';
        }
        await Supabase.instance.client.auth.signUp(
          phone: noHp,
          password: _passController.text,
          data: {'name': nama},
        );
        // Simpan profil
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          await Supabase.instance.client.from('profiles').upsert({
            'id': uid,
            'name': nama,
          });
        }
      } else {
        final email = _emailController.text.trim();
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: _passController.text,
          data: {'name': nama},
        );
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          await Supabase.instance.client.from('profiles').upsert({
            'id': uid,
            'name': nama,
          });
        }
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

  // === MASUK DENGAN SANDI ===
  Future<void> _loginWithPassword() async {
    setState(() => _isLoading = true);
    try {
      if (_selectedAuthTab == 0) {
        String noHp = _noHpController.text.trim();
        if (!noHp.startsWith('+')) {
          if (noHp.startsWith('0')) noHp = noHp.substring(1);
          noHp = '+62$noHp';
        }
        await Supabase.instance.client.auth.signInWithPassword(
          phone: noHp,
          password: _passController.text,
        );
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
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

  // === LUPA SANDI ===
  Future<void> _sendResetOtp() async {
    final contact = _selectedAuthTab == 0 
        ? _noHpController.text.trim() 
        : _emailController.text.trim();
    if (contact.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (_selectedAuthTab == 1) {
        await Supabase.instance.client.auth.resetPasswordForEmail(contact);
      } else {
        // Untuk HP — kirim OTP dulu
        String noHp = contact;
        if (!noHp.startsWith('+')) {
          if (noHp.startsWith('0')) noHp = noHp.substring(1);
          noHp = '+62$noHp';
        }
        await Supabase.instance.client.auth.signInWithOtp(phone: noHp);
      }
      
      setState(() {
        _isForgotMode = true;
        _resetTarget = contact;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode dikirim! Cek SMS/Email ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal kirim kode: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  // === TAMPILAN UTAMA ===
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

                // === PILIHAN: NO HP / EMAIL ===
                if (!_isVerifyOtpMode && !_isForgotMode)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: _selectedAuthTab == 0 ? Colors.green : Colors.transparent,
                              foregroundColor: _selectedAuthTab == 0 ? Colors.white : Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => setState(() => _selectedAuthTab = 0),
                            child: const Text('📱 No. HP', style: TextStyle(fontSize: 15)),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: _selectedAuthTab == 1 ? Colors.green : Colors.transparent,
                              foregroundColor: _selectedAuthTab == 1 ? Colors.white : Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => setState(() => _selectedAuthTab = 1),
                            child: const Text('✉️ Email', style: TextStyle(fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // === BAGIAN FORM ===
                if (_isVerifyOtpMode) ...[
                  const Text('Masukkan Kode OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Kode dari SMS/Email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, letterSpacing: 8),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isLoading ? 'Memproses...' : 'Verifikasi', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isVerifyOtpMode = false),
                    child: const Text('← Kembali'),
                  ),
                ] else if (_isForgotMode) ...[
                  const Text('Reset Kata Sandi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Kode OTP',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passController,
                    obscureText: _obscurePass,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi Baru',
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
                      labelText: 'Konfirmasi Sandi Baru',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        if (_passController.text == _confirmPassController.text) {
                          _verifyOtp();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sandi tidak cocok!')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isLoading ? 'Memproses...' : 'Simpan Sandi Baru', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isForgotMode = false),
                    child: const Text('← Kembali Masuk'),
                  ),
                ] else ...[
                  // Nama (hanya saat Daftar)
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

                  // No HP atau Email
                  TextField(
                    controller: _selectedAuthTab == 0 ? _noHpController : _emailController,
                    keyboardType: _selectedAuthTab == 0 ? TextInputType.phone : TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: _selectedAuthTab == 0 ? 'Nomor HP' : 'Alamat Email',
                      prefixIcon: Icon(_selectedAuthTab == 0 ? Icons.phone : Icons.email),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      hintText: _selectedAuthTab == 0 ? 'Contoh: 08123456789' : 'email@contoh.com',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Kata Sandi
                  TextField(
                    controller: _passController,
                    obscureText: _obscurePass,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Konfirmasi Sandi (hanya Daftar)
                  if (!_isLoginMode)
                    TextField(
                      controller: _confirmPassController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Kata Sandi',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                  if (!_isLoginMode) const SizedBox(height: 20),

                  // Tombol Utama
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : (_isLoginMode ? _loginWithPassword : _registerWithPassword),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _isLoading ? 'Memproses...' : (_isLoginMode ? 'Masuk' : '
