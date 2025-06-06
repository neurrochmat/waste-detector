import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Kelas untuk melakukan klasifikasi sampah menggunakan model TensorFlow Lite
class WasteClassifier {
  static const String _modelPath = 'assets/models/waste_classifier_quant.tflite';
  static const int _inputSize = 224;
  
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  
  /// Memuat model TensorFlow Lite dari assets
  /// 
  /// Throws [Exception] jika gagal memuat model
  Future<void> loadModel() async {
    try {
      final interpreterOptions = InterpreterOptions();
      interpreterOptions.threads = 4;
      
      _interpreter = await Interpreter.fromAsset(
        _modelPath,
        options: interpreterOptions,
      );
      
      _isModelLoaded = true;
      print('Model berhasil dimuat');
      
      // Print model info untuk debugging
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
      
    } catch (e) {
      print('Error loading model: $e');
      _isModelLoaded = false;
      throw Exception('Gagal memuat model: $e');
    }
  }
  
  /// Melakukan klasifikasi pada gambar yang diberikan
  /// 
  /// [imagePath] adalah path ke file gambar yang akan diklasifikasi
  /// Returns [Map] yang berisi hasil klasifikasi atau null jika terjadi error
  Future<Map<String, dynamic>?> classifyImage(String imagePath) async {
    if (!_isModelLoaded || _interpreter == null) {
      throw Exception('Model belum dimuat. Panggil loadModel() terlebih dahulu.');
    }
    
    try {
      // Load dan preprocess image
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('File gambar tidak ditemukan: $imagePath');
      }
      
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Gagal decode image');
      }
      
      // Convert to RGB if necessary
      final rgbImage = image.numChannels == 3 ? image : img.copyResize(image, width: image.width, height: image.height);
      
      // Resize image ke ukuran yang dibutuhkan model
      final resizedImage = img.copyResize(
        rgbImage,
        width: _inputSize,
        height: _inputSize,
      );
      
      // Get input details untuk determine dtype
      final inputDetails = _interpreter!.getInputTensor(0);
      final inputType = inputDetails.type;
      
      // Prepare input berdasarkan model dtype
      final input = _prepareInput(resizedImage, inputType);
      
      // Get output details
      final outputDetails = _interpreter!.getOutputTensor(0);
      final outputType = outputDetails.type;
      
      // Prepare output buffer berdasarkan tipe output
      var output;
      if (outputType == TensorType.float32) {
        output = List.filled(1, 0.0).reshape([1, 1]);
      } else if (outputType == TensorType.uint8) {
        output = List.filled(1, 0).reshape([1, 1]);
      } else {
        throw Exception('Unsupported output type: $outputType');
      }
      
      // Run inference
      _interpreter!.run(input, output);
      
      // Process results
      double rawScore;
      if (outputType == TensorType.float32) {
        rawScore = output[0][0].toDouble();
      } else {
        rawScore = output[0][0].toDouble() / 255.0;
      }
      
      print('Raw score: $rawScore');
      
      // Binary classification: >= 0.5 = anorganik, < 0.5 = organik
      String predictedClass = rawScore >= 0.5 ? 'anorganik' : 'organik';
      
      // Calculate confidence (distance from 0.5 threshold)
      double confidence = rawScore >= 0.5 ? rawScore : (1.0 - rawScore);
      double confidencePercentage = confidence * 100;
      
      print('Final prediction: $predictedClass with confidence: ${confidencePercentage.toStringAsFixed(2)}%');
      
      return {
        'class': predictedClass,
        'confidence': confidence,
        'confidencePercentage': confidencePercentage,
        'rawScore': rawScore,
      };
      
    } catch (e) {
      print('Error during classification: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }
  
  dynamic _prepareInput(img.Image image, TensorType inputType) {
    if (inputType == TensorType.float32) {
      return _imageToFloat32(image);
    } else if (inputType == TensorType.uint8) {
      return _imageToUint8(image);
    } else {
      throw Exception('Unsupported input type: $inputType');
    }
  }
  
  List<List<List<List<double>>>> _imageToFloat32(img.Image image) {
    final convertedBytes = List.generate(
      1,
      (i) => List.generate(
        _inputSize,
        (j) => List.generate(
          _inputSize,
          (k) => List.generate(3, (l) => 0.0),
        ),
      ),
    );
    
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = image.getPixel(x, y);
        
        // Normalize pixel values to 0-1 range
        convertedBytes[0][y][x][0] = (pixel.r / 255.0);
        convertedBytes[0][y][x][1] = (pixel.g / 255.0);
        convertedBytes[0][y][x][2] = (pixel.b / 255.0);
      }
    }
    
    return convertedBytes;
  }
  
  List<List<List<List<int>>>> _imageToUint8(img.Image image) {
    final convertedBytes = List.generate(
      1,
      (i) => List.generate(
        _inputSize,
        (j) => List.generate(
          _inputSize,
          (k) => List.generate(3, (l) => 0),
        ),
      ),
    );
    
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = image.getPixel(x, y);
        
        // Keep pixel values as 0-255 for quantized model
        convertedBytes[0][y][x][0] = pixel.r.toInt();
        convertedBytes[0][y][x][1] = pixel.g.toInt();
        convertedBytes[0][y][x][2] = pixel.b.toInt();
      }
    }
    
    return convertedBytes;
  }
  
  /// Membersihkan resources yang digunakan oleh interpreter
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
  
  /// Status apakah model sudah dimuat atau belum
  bool get isModelLoaded => _isModelLoaded;
}