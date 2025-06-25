import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const OnboardingScreen({Key? key, required this.cameras}) : super(key: key);
  
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  // Pengaturan PageView
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isLastPage = false;
  
  // Animasi untuk indikator dan elemen UI
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  
  // Data halaman onboarding
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Deteksi Sampah Otomatis',
      description: 'Identifikasi sampah organik dan anorganik dengan mudah menggunakan kamera ponselmu.',
      imagePath: 'assets/onboarding/detection.png', // Pastikan file gambar ada
      backgroundColor: Color(0xFF5DB075),
      illustrationWidget: _BuildDetectionIllustration(),
    ),
    OnboardingPage(
      title: 'Akurasi Tinggi',
      description: 'Klasifikasi sampah dengan tingkat akurasi tinggi berkat teknologi AI.',
      imagePath: 'assets/onboarding/accuracy.png',
      backgroundColor: Color(0xFF4B8BDF),
      illustrationWidget: _BuildAccuracyIllustration(),
    ),
    OnboardingPage(
      title: 'Tentang Sampah',
      description: 'Dapatkan tips dan informasi bermanfaat tentang pengelolaan sampah yang baik.',
      imagePath: 'assets/onboarding/info.png',
      backgroundColor: Color(0xFFEE8B60),
      illustrationWidget: _BuildInfoIllustration(),
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Setup PageController
    _pageController = PageController();
    
    // Setup animasi
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut)
    );
    
    _animController.forward();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }
  
  // Lanjutkan ke halaman berikutnya atau ke aplikasi jika sudah halaman terakhir
  void _nextPage() {
    if (_isLastPage) {
      _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }
  
  // Tandai onboarding sudah selesai dan navigasi ke HomeScreen
  void _finishOnboarding() async {
    // Menyimpan bahwa onboarding sudah selesai
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    // Navigasi ke Home Screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(cameras: widget.cameras),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient yang berubah sesuai halaman
          AnimatedContainer(
            duration: Duration(milliseconds: 500),
            color: _currentPage < _pages.length 
                ? _pages[_currentPage].backgroundColor 
                : Colors.white,
            child: SizedBox.expand(),
          ),
          
          // Konten utama (PageView)
          SafeArea(
            child: Column(
              children: [
                // Skip button di kanan atas
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 16.0, top: 16.0),
                    child: TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        'Lewati',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // PageView untuk konten onboarding
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                        _isLastPage = page == _pages.length - 1;
                      });
                      
                      // Reset dan jalankan animasi lagi saat halaman berubah
                      _animController.reset();
                      _animController.forward();
                    },
                    itemBuilder: (context, index) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildPage(_pages[index]),
                      );
                    },
                  ),
                ),
                
                // Indikator halaman dan tombol next
                Container(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indikator halaman (dots)
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => _buildDotIndicator(index),
                        ),
                      ),
                      
                      // Tombol Next/Mulai
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _pages[_currentPage].backgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isLastPage ? 'Mulai' : 'Lanjut',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(_isLastPage ? Icons.check_circle : Icons.arrow_forward),
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
    );
  }
  
  // Widget untuk membuat indikator halaman (dots)
  Widget _buildDotIndicator(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
  
  // Widget untuk membuat halaman onboarding
  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustrasi atau gambar
          Expanded(
            flex: 3,
            child: page.illustrationWidget ?? 
              Image.asset(
                page.imagePath,
                fit: BoxFit.contain,
              ),
          ),
          
          SizedBox(height: 40),
          
          // Judul
          Text(
            page.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 16),
          
          // Deskripsi
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              page.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          Spacer(),
        ],
      ),
    );
  }
}

// Model data untuk halaman onboarding
class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;
  final Color backgroundColor;
  final Widget? illustrationWidget;
  
  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.backgroundColor,
    this.illustrationWidget,
  });
}

// Custom widget untuk ilustrasi deteksi sampah
class _BuildDetectionIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 100,
              color: Colors.white,
            ),
            Positioned(
              top: 40,
              right: 40,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.eco,
                  color: Color(0xFF5DB075),
                  size: 30,
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 40,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom widget untuk ilustrasi akurasi
class _BuildAccuracyIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "95%",
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Animated checkmark bisa ditambahkan disini
        ],
      ),
    );
  }
}

// Custom widget untuk ilustrasi informasi
class _BuildInfoIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        padding: EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tips_and_updates,
              size: 60,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Container(
              height: 10,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            SizedBox(height: 10),
            Container(
              height: 10,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            SizedBox(height: 10),
            Container(
              height: 10,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
