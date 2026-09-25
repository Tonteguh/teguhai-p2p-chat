import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://uktplqoiugaaudoikkby.supabase.co',
    anonKey: 'sb_publishable_UZSK6fDquV0dDBG3GZBJcw_T48lleMk',
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
      home: const Beranda(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Beranda extends StatefulWidget {
  const Beranda({super.key});

  @override
  State<Beranda> createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> {
  int tabAktif = 0;

  final List<Widget> isiTab = const [
    LayarObrolan(),
    LayarVideo(),
    LayarBelanja(),
    LayarPengaturan(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TeguhAi'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: isiTab[tabAktif],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tabAktif,
        onTap: (i) => setState(() => tabAktif = i),
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

class LayarObrolan extends StatefulWidget {
  const LayarObrolan({super.key});

  @override
  State<LayarObrolan> createState() => _LayarObrolanState();
}

class _LayarObrolanState extends State<LayarObrolan> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        child: const Icon(Icons.add_comment, color: Colors.white),
        onPressed: () {},
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat, size: 72, color: Colors.green),
            SizedBox(height: 16),
            Text('Obrolan & Panggilan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Langsung antar HP — aman, cepat, ringan', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TombolCepat(ikon: Icons.phone, warna: Colors.green, label: 'Panggilan Suara'),
                SizedBox(width: 20),
                TombolCepat(ikon: Icons.videocam, warna: Colors.redAccent, label: 'Panggilan Video'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TombolCepat extends StatelessWidget {
  final IconData ikon;
  final Color warna;
  final String label;

  const TombolCepat({super.key, required this.ikon, required this.warna, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: warna.withOpacity(0.15),
          child: Icon(ikon, color: warna, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}

class LayarVideo extends StatelessWidget {
  const LayarVideo({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> daftarVideo = [
      {'judul': 'Belajar Sains Seru', 'tautan': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'gambar': '📺'},
      {'judul': 'Cerita Anak & Dongeng', 'tautan': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'gambar': '🎬'},
      {'judul': 'Kisah Teladan & Motivasi', 'tautan': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'gambar': '✨'},
      {'judul': 'Musik & Lagu Penenang', 'tautan': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'gambar': '🎵'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('🎬 Tonton Video'), automaticallyImplyLeading: false),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: daftarVideo.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final vid = daftarVideo[i];
          return Card(
            elevation: 2,
            child: ListTile(
              leading: Text(vid['gambar']!, style: const TextStyle(fontSize: 28)),
              title: Text(vid['judul']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Tonton langsung di sini', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final uri = Uri.parse(vid['tautan']!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.inAppWebView);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class LayarBelanja extends StatelessWidget {
  const LayarBelanja({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> daftarProduk = [
      {'nama': 'HP & Aksesoris', 'link': 'https://shopee.co.id/', 'ikon': '📱'},
      {'nama': 'Pakaian & Busana', 'link': 'https://shopee.co.id/', 'ikon': '👕'},
      {'nama': 'Perlengkapan Rumah', 'link': 'https://shopee.co.id/', 'ikon': '🏠'},
      {'nama': 'Elektronik & Gadget', 'link': 'https://shopee.co.id/', 'ikon': '🔌'},
      {'nama': 'Makanan & Kebutuhan', 'link': 'https://shopee.co.id/', 'ikon': '🍜'},
      {'nama': 'Alat Tulis & Sekolah', 'link': 'https://shopee.co.id/', 'ikon': '✏️'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('🛒 Belanja & Berbagi'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dapat Komisi Setiap Belanja!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                  SizedBox(height: 4),
                  Text('Beli lewat tautan di bawah → kamu & saya sama-sama untung', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: daftarProduk.length,
                itemBuilder: (context, i) {
                  final prd = daftarProduk[i];
                  return Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: () async {
                        final uri = Uri.parse(prd['link']!);
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(prd['ikon']!, style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(prd['nama']!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LayarPengaturan extends StatelessWidget {
  const LayarPengaturan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ Pengaturan'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Column(
              children: [
                CircleAvatar(radius: 36, backgroundColor: Colors.green, child: Text('T', style: TextStyle(fontSize: 32, color: Colors.white))),
                SizedBox(height: 12),
                Text('TeguhAi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Versi 1.0.0 • Ringan & Gratis', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Divider(),
          ListTile(leading: const Icon(Icons.person), title: const Text('Profil Saya'), onTap: () {}),
          ListTile(leading: const Icon(Icons.notifications), title: const Text('Notifikasi'), onTap: () {}),
          ListTile(leading: const Icon(Icons.privacy_tip), title: const Text('Privasi & Keamanan'), onTap: () {}),
          ListTile(leading: const Icon(Icons.help), title: const Text('Bantuan'), onTap: () {}),
          ListTile(leading: const Icon(Icons.info), title: const Text('Tentang'), onTap: () {}),
        ],
      ),
    );
  }
}
