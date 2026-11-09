import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;

late List<CameraDescription> kameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  kameras = await availableCameras();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Layar(),
  ));
}

class Layar extends StatefulWidget {
  const Layar({super.key});
  @override
  State<Layar> createState() => _LayarState();
}

class _LayarState extends State<Layar> {
  late CameraController c;
  bool siap = false;
  bool sibuk = false;

  @override
  void initState() {
    super.initState();
    c = CameraController(kameras.first, ResolutionPreset.high,
        enableAudio: false);
    c.initialize().then((_) {
      if (mounted) setState(() => siap = true);
    });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  String waktu() {
    final n = DateTime.now();
    String d(int x) => x.toString().padLeft(2, '0');
    return '${d(n.day)}/${d(n.month)}/${n.year} '
        '${d(n.hour)}:${d(n.minute)}:${d(n.second)}';
  }

  void pesan(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> ambil() async {
    setState(() => sibuk = true);
    try {
      final f = await c.takePicture();
      final teks = waktu();
      final asli = img.decodeImage(await f.readAsBytes())!;
      final gambar = img.bakeOrientation(asli);
      img.drawString(gambar, teks,
          font: img.arial48,
          x: 30,
          y: gambar.height - 90,
          color: img.ColorRgb8(255, 255, 0));
      final path =
          '${Directory.systemTemp.path}/ts_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(path).writeAsBytes(img.encodeJpg(gambar, quality: 92));
      await Gal.putImage(path);
      pesan('Tersimpan di galeri');
    } catch (e) {
      pesan('Gagal: $e');
    }
    if (mounted) setState(() => sibuk = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: siap
          ? Column(children: [
              Expanded(child: Center(child: CameraPreview(c))),
              Padding(
                padding: const EdgeInsets.all(24),
                child: sibuk
                    ? const CircularProgressIndicator()
                    : FloatingActionButton(
                        onPressed: ambil,
                        child: const Icon(Icons.camera_alt),
                      ),
              ),
            ])
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
