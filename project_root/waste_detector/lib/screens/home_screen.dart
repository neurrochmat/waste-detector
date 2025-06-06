import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/waste_classifier.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const HomeScreen({Key? key, required this.cameras}) : super(key: key);
  
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WasteClassifier _classifier = WasteClassifier();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  Map<String, dynamic>? _classificationResult;
  bool _isClassifying = false;
  bool _isModelLoaded = false;
  
  @override
  void initState() {
    super.initState();
    _loadModel();
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
    });
    
    try {
      final result = await _classifier.classifyImage(_selectedImage!.path);
      
      setState(() {
        _classificationResult = result;
        _isClassifying = false;
      });
      
      if (result == null) {
        _showErrorDialog('Gagal mengklasifikasi gambar');
      }
    } catch (e) {
      setState(() {
        _isClassifying = false;
      });
      _showErrorDialog('Error saat klasifikasi: $e');
    }
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
    
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isOrganic ? Icons.eco : Icons.delete,
                  color: isOrganic ? Colors.green : Colors.orange,
                  size: 32,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hasil Klasifikasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sampah ${result['class'].toString().toUpperCase()}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isOrganic ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: confidence / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOrganic ? Colors.green : Colors.orange,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tingkat Kepercayaan: ${confidence.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isOrganic ? Colors.green : Colors.orange).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isOrganic ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOrganic 
                        ? 'Sampah organik dapat didaur ulang menjadi kompos'
                        : 'Sampah anorganik dapat didaur ulang atau dibuang ke tempat sampah khusus',
                      style: TextStyle(fontSize: 12),
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
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Deteksi Sampah AI'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Model
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isModelLoaded ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isModelLoaded ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isModelLoaded ? Icons.check_circle : Icons.error,
                    color: _isModelLoaded ? Colors.green : Colors.red,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _isModelLoaded ? 'Model AI Siap' : 'Model AI Belum Dimuat',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isModelLoaded ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            
            // Image Display
            if (_selectedImage != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            // Loading Indicator
            if (_isClassifying)
              Container(
                margin: EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Menganalisis gambar...'),
                  ],
                ),
              ),
            
            // Results
            _buildResultCard(),
            
            // Action Buttons
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isModelLoaded ? _pickImageFromCamera : null,
                          icon: Icon(Icons.camera_alt),
                          label: Text('Ambil Foto'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isModelLoaded ? _pickImageFromGallery : null,
                          icon: Icon(Icons.photo_library),
                          label: Text('Pilih Gambar'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  if (!_isModelLoaded)
                    ElevatedButton.icon(
                      onPressed: _loadModel,
                      icon: Icon(Icons.refresh),
                      label: Text('Muat Ulang Model'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
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
}