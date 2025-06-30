import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';
import '../services/gemini_service.dart';
import '../services/waste_classifier.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomeScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final WasteClassifier _classifier = WasteClassifier();
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  Map<String, dynamic>? _classificationResult;
  bool _isClassifying = false;
  bool _isGettingTips = false;
  String? _geminiTip;
  bool _isModelLoaded = false;
  late AnimationController _resultAnimController;
  late Animation<double> _resultScaleAnim;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _resultAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _resultScaleAnim = CurvedAnimation(
      parent: _resultAnimController,
      curve: Curves.elasticOut,
    );
  }

  Future<void> _loadModel() async {
    setState(() {
      _isModelLoaded = false;
    });

    await _classifier.loadModel();

    setState(() {
      _isModelLoaded = _classifier.isModelLoaded;
    });

    if (!_isModelLoaded) {
      _showErrorDialog('Gagal memuat model AI. Pastikan file waste_classifier.tflite ada di assets/models/');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _classificationResult = null;
        });

        _classifyImage();
      }
    } catch (e) {
      _showErrorDialog('Gagal memilih gambar: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _classificationResult = null;
        });

        _classifyImage();
      }
    } catch (e) {
      _showErrorDialog('Gagal mengambil foto: $e');
    }
  }

  Future<void> _classifyImage() async {
    if (_selectedImage == null || !_isModelLoaded) return;

    setState(() {
      _isClassifying = true;
      _classificationResult = null;
      _geminiTip = null;
    });

    try {
      final result = await _classifier.classifyImage(_selectedImage!.path);

      setState(() {
        _classificationResult = result;
        _isClassifying = false;
      });

      if (result == null) {
        _showSnackbar('Gagal mengklasifikasi gambar', isError: true);
      } else {
        _resultAnimController.forward(from: 0);
        _getGeminiTips();
        _showSnackbar('Klasifikasi berhasil!', isError: false);
      }
    } catch (e) {
      setState(() {
        _isClassifying = false;
      });
      _showSnackbar('Error saat klasifikasi: $e', isError: true);
    }
  }

  Future<void> _getGeminiTips() async {
    if (_selectedImage == null) return;

    setState(() {
      _isGettingTips = true;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      final tip = await _geminiService.getTipsFromImage(imageBytes);

      setState(() {
        _geminiTip = tip;
        _isGettingTips = false;
      });

      if (tip == null) {
        _showSnackbar('Gagal mendapatkan tips dari AI', isError: true);
      }
    } catch (e) {
      setState(() {
        _isGettingTips = false;
      });
      _showSnackbar('Error saat mendapatkan tips: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    if (_classificationResult == null) return SizedBox.shrink();

    final result = _classificationResult!;
    final isOrganic = result['class'] == 'organik';
    final confidence = result['confidencePercentage'] as double;
    final Color primaryColor = isOrganic ? Color(0xFF5DB075) : Color(0xFFFF8A65);

    return ScaleTransition(
      scale: _resultScaleAnim,
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 16),
        elevation: 3,
        shadowColor: primaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Header section with type and icon
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOrganic
                      ? [Color(0xFF5DB075).withOpacity(0.9), Color(0xFF4A9975).withOpacity(0.8)]
                      : [Color(0xFFFF8A65).withOpacity(0.9), Color(0xFFFF7043).withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.9),
                    child: Icon(
                      isOrganic ? Icons.eco : Icons.delete,
                      color: primaryColor,
                      size: 36,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'SAMPAH',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          result['class'].toString().toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Details section
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Confidence section
                  Text(
                    'Tingkat Kepercayaan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Stack(
                          children: [
                            Container(
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: confidence / 100,
                              child: Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryColor,
                                      primaryColor.withOpacity(0.8),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${confidence.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Divider(height: 40),

                  // Information section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informasi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              isOrganic
                                  ? 'Sampah organik berasal dari makhluk hidup dan mudah terurai. Dapat diolah menjadi kompos dan pupuk yang bermanfaat untuk tanaman.'
                                  : 'Sampah anorganik sulit terurai secara alami. Sebaiknya didaur ulang atau dibuang pada tempat sampah khusus untuk mengurangi dampak lingkungan.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Tips section
                  if (_geminiTip != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb,
                            color: Colors.blue[700],
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tips dari AI',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _geminiTip!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _classifier.dispose();
    _resultAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Waste Detector',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5DB075), Color(0xFF4A9975)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF5F5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Header Area
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF5DB075), Color(0xFF4A9975)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 15, 16, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Deteksi Sampah AI',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Klasifikasi sampah dengan cerdas',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Status Model in Card
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isModelLoaded
                                  ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)]
                                  : [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (_isModelLoaded ? Colors.green : Colors.red).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isModelLoaded ? Icons.check_circle : Icons.error,
                                  color: _isModelLoaded ? Colors.green : Colors.red,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isModelLoaded ? 'Model AI Siap' : 'Model AI Belum Dimuat',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: _isModelLoaded ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  Text(
                                    _isModelLoaded
                                        ? 'Siap melakukan klasifikasi gambar'
                                        : 'Silakan muat ulang model',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Main Content Area - Image Preview & Results
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Upload Image Area
                          if (_selectedImage == null && !_isClassifying)
                            GestureDetector(
                              onTap: _isModelLoaded ? _pickImageFromGallery : null,
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 16),
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_search,
                                      size: 60,
                                      color: _isModelLoaded ? Color(0xFF5DB075) : Colors.grey,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Ketuk untuk memilih gambar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _isModelLoaded ? Colors.grey[800] : Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'atau gunakan kamera di bawah',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Image Display
                          if (_selectedImage != null)
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 15,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.file(
                                      _selectedImage!,
                                      // Gunakan ukuran maksimum untuk mencegah overflow
                                      height: min(300, size.height * 0.3),
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedImage = null;
                                          _classificationResult = null;
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Loading Indicator
                          if (_isClassifying)
                            Container(
                              margin: EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5DB075)),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Menganalisis gambar...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Mohon tunggu sebentar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Results
                          _buildResultCard(),
                        ],
                      ),
                    ),
                    // Action Buttons in Card
                    Card(
                      margin: EdgeInsets.all(16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Pilih Sumber Gambar",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Gunakan kamera atau pilih dari galeri",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isModelLoaded ? _pickImageFromCamera : null,
                                    icon: Icon(Icons.camera_alt),
                                    label: Text('Kamera'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Color(0xFF5DB075),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: _isModelLoaded ? 2 : 0,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isModelLoaded ? _pickImageFromGallery : null,
                                    icon: Icon(Icons.photo_library),
                                    label: Text('Galeri'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Color(0xFF4B8BDF),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: _isModelLoaded ? 2 : 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Reload model button
                            if (!_isModelLoaded)
                              Container(
                                margin: EdgeInsets.only(top: 16),
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _loadModel,
                                  icon: Icon(Icons.refresh),
                                  label: Text('Muat Ulang Model'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer area with info
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  Divider(),
                  SizedBox(height: 3),
                  Text(
                    "Waste Detector v1.1",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    "Smart Detection, Cleaner Future",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}