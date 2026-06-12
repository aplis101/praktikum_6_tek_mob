import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'helpers/database_helper.dart';

void main() {
  runApp(const LaporanApp());
}

class LaporanApp extends StatelessWidget {
  const LaporanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pelaporan Lapangan',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FormLaporanScreen(),
    );
  }
}

class FormLaporanScreen extends StatefulWidget {
  const FormLaporanScreen({super.key});

  @override
  State<FormLaporanScreen> createState() => _FormLaporanScreenState();
}

class _FormLaporanScreenState extends State<FormLaporanScreen> {
  // وحدات التحكم للحقول النصية
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();

  // متغيرات لحفظ مسار الصورة والإحداثيات
  String? _imagePath;
  double? _latitude;
  double? _longitude;

  final ImagePicker _picker = ImagePicker();

  // 1. دالة التقاط الصورة من الكاميرا
  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _imagePath = photo.path;
        });
        // بمجرد التقاط الصورة، نسحب الموقع تلقائياً كما طلب الأستاذ
        await _getLocation();
      }
    } catch (e) {
      _showMessage('Gagal membuka kamera: $e');
    }
  }

  // 2. دالة جلب الموقع الجغرافي (مع معالجة الأخطاء Try-Catch)
  Future<void> _getLocation() async {
    try {
      // التحقق من صلاحيات الموقع
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showMessage('Izin lokasi ditolak!');
          return;
        }
      }

      // جلب الإحداثيات الحالية
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      _showMessage('Lokasi berhasil didapatkan!');
    } catch (e) {
      _showMessage('Gagal mendapatkan lokasi: $e');
    }
  }

  // 3. دالة التحقق والحفظ في قاعدة البيانات
  Future<void> _submitLaporan() async {
    String judul = _judulController.text;
    String deskripsi = _deskripsiController.text;

    // شرط إجباري: التحقق من الحقول الفارغة والصورة والموقع
    if (judul.isEmpty || deskripsi.isEmpty) {
      _showMessage('Error: Judul dan Deskripsi tidak boleh kosong!');
      return;
    }
    if (_imagePath == null || _latitude == null || _longitude == null) {
      _showMessage('Error: Harap ambil foto terlebih dahulu!');
      return;
    }

    // تجهيز البيانات للحفظ
    Map<String, dynamic> row = {
      'judul': judul,
      'deskripsi': deskripsi,
      'foto_path': _imagePath,
      'latitude': _latitude,
      'longitude': _longitude,
    };

    // حفظ البيانات في قاعدة البيانات
    await DatabaseHelper().insertLaporan(row);
    _showMessage('Laporan Berhasil Disimpan!');

    // تفريغ الحقول بعد الحفظ
    setState(() {
      _judulController.clear();
      _deskripsiController.clear();
      _imagePath = null;
      _latitude = null;
      _longitude = null;
    });
  }

  // دالة مساعدة لإظهار الرسائل المنبثقة (SnackBar)
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan Lapangan'),
        // زر للانتقال لصفحة السجل (سنبنيها في الخطوة القادمة)
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // فتح صفحة السجل عند الضغط على الأيقونة
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RiwayatLaporanScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _judulController,
              decoration: const InputDecoration(
                labelText: 'Judul Laporan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _deskripsiController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Kejadian',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // زر التقاط الصورة
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Ambil Foto & Lokasi GPS'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              onPressed: _takePicture,
            ),
            const SizedBox(height: 16),

            // عرض الصورة والإحداثيات إذا تم التقاطها
            if (_imagePath != null) ...[
              Image.file(File(_imagePath!), height: 200, fit: BoxFit.cover),
              const SizedBox(height: 8),
              Text(
                'Lat: $_latitude, Lng: $_longitude',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 24),

            // زر الحفظ
            ElevatedButton(
              onPressed: _submitLaporan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Submit Laporan',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// شاشة سجل التقارير (Riwayat Laporan)
// ==========================================
// ==========================================
// شاشة سجل التقارير (Riwayat Laporan) - محدثة مع ميزة الحذف
// ==========================================
class RiwayatLaporanScreen extends StatefulWidget {
  const RiwayatLaporanScreen({super.key});

  @override
  State<RiwayatLaporanScreen> createState() => _RiwayatLaporanScreenState();
}

class _RiwayatLaporanScreenState extends State<RiwayatLaporanScreen> {
  List<Map<String, dynamic>> _laporanList = [];

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    final data = await DatabaseHelper().getLaporanList();
    setState(() {
      _laporanList = data;
    });
  }

  // دالة لحذف تقرير محدد وتحديث الشاشة
  Future<void> _deleteLaporan(int id) async {
    await DatabaseHelper().deleteLaporan(id);
    _loadRiwayat(); // إعادة جلب البيانات بعد الحذف

    // سطر الأمان لمنع الخطأ في فلاتر بعد عملية await
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Laporan berhasil dihapus!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // نافذة تأكيد لحذف كل السجل
  Future<void> _showDeleteAllDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Riwayat?'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus seluruh data laporan secara permanen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // إلغاء
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // إغلاق النافذة
              await DatabaseHelper().deleteAllLaporan(); // مسح الكل
              _loadRiwayat(); // تحديث الشاشة

              // سطر الأمان لمنع الخطأ
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Semua riwayat berhasil dihapus!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              'Hapus Semua',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Laporan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        actions: [
          // زر مسح كل السجل
          if (_laporanList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              tooltip: 'Hapus Semua',
              onPressed: _showDeleteAllDialog,
            ),
        ],
      ),
      body: _laporanList.isEmpty
          ? const Center(
              child: Text(
                'Belum ada laporan yang disimpan.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _laporanList.length,
              itemBuilder: (context, index) {
                final laporan = _laporanList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(laporan['foto_path']),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      laporan['judul'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${laporan['deskripsi']}\n📍 Lat: ${laporan['latitude']}\n📍 Lng: ${laporan['longitude']}',
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                    isThreeLine: true,
                    // أيقونة الحذف الفردي
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () =>
                          _deleteLaporan(laporan['id']), // تمرير الـ ID للحذف
                    ),
                  ),
                );
              },
            ),
    );
  }
}
