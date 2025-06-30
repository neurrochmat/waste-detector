import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';

class GeminiService {
  final GenerativeModel _model;
  static const String _apiKey = "AIzaSyD1YOyHm5Tqlp17ChTVZSlEU0cgRr-3LEU";

  GeminiService()
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: _apiKey,
        );

  Future<String?> getTipsFromImage(Uint8List imageBytes) async {
    try {
      final prompt = TextPart("Berikan tips untuk mengelola sampah pada gambar ini:");
      final imagePart = DataPart('image/jpeg', imageBytes);

      final content = [Content.multi([prompt, imagePart])];
      
      final response = await _model.generateContent(content);
      
      return response.text;
    } catch (e) {
      print('Error getting tips from Gemini: $e');
      return "Maaf, terjadi kesalahan saat meminta tips dari AI.";
    }
  }
}
