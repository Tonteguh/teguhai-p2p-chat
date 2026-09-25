import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://ganti-proyek-anda.supabase.co',
    anonKey: 'ganti-kunci-anda-disini',
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
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabSaatIni = 0;

  final List<Widget> _layar = const [
    ObrolanLayar(),
    PusatVideoLayar(),
    TokoAfiliasiLayar(),
    PengaturanLayar(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TeguhAi'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: _layar[_tabSaatIni],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabSaatIni,
        onTap: (i) => setState(() => _tabSaatIni = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Obrolan'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle), label: 'Video'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Belanja'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
        ],
      ),
    );
  }
}

// Layar 1 — Obrolan
class ObrolanLayar extends StatelessWidget {
  const ObrolanLayar({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text('Obrolan P2P', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Langsung antar HP, aman & cepat', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// Layar 2 — Nonton Video
class PusatVideoLayar extends StatelessWidget {
  const PusatVideoLayar({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle, size: 64, color: Colors.redAccent),
          SizedBox(height: 16),
          Text('Tonton Video', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Nonton langsung di sini tanpa keluar aplikasi', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// Layar 3 — Belanja Afiliasi
class TokoAfiliasiLayar extends StatelessWidget {
  const TokoAfiliasiLayar({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text('Belanja & Berbagi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Dapat komisi setiap pembelian lewat Anda', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// Layar 4 — Pengaturan
class PengaturanLayar extends StatelessWidget {
  const PengaturanLayar({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 64, color: Colors.blueGrey),
          SizedBox(height: 16),
          Text('Pengaturan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
