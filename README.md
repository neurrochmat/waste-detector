<h1 align="center">WASTE-DETECTOR</h1>

<p align="center"><i>Smart Detection, Cleaner Future—Empowering Waste Management with AI</i></p>

<p align="center">
  <img src="https://img.shields.io/github/last-commit/neurrochmat/waste-detector" alt="last commit"/>
  <img src="https://img.shields.io/github/languages/top/neurrochmat/waste-detector" alt="top language"/>
  <img src="https://img.shields.io/github/languages/count/neurrochmat/waste-detector" alt="languages"/>
  <img src="https://img.shields.io/github/repo-size/neurrochmat/waste-detector" alt="repo size"/>
</p>

<p align="center"><i>Built with the tools and technologies:</i></p>

<p align="center">
  <img src="https://img.shields.io/badge/C++-00599C?style=flat-square&logo=c%2B%2B&logoColor=white"/>
  <img src="https://img.shields.io/badge/CMake-064F8C?style=flat-square&logo=cmake&logoColor=white"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white"/>
  <img src="https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white"/>
  <img src="https://img.shields.io/badge/Swift-FA7343?style=flat-square&logo=swift&logoColor=white"/>
  <img src="https://img.shields.io/badge/C-00599C?style=flat-square&logo=c&logoColor=white"/>
  <img src="https://img.shields.io/badge/Other-lightgrey?style=flat-square"/>
</p>

---

## Table of Contents
- [Overview](#overview)
- [Technologies Used](#technologies-used)
- [Features](#features)
- [Project Structure](#project-structure)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Setting Up the Environment](#setting-up-the-environment)
- [Machine Learning Pipeline](#machine-learning-pipeline)
  - [Data Preprocessing](#data-preprocessing)
  - [Model Training](#model-training)
  - [Model Evaluation](#model-evaluation)
  - [Export to TFLite](#export-to-tflite)
- [Building the Flutter App](#building-the-flutter-app)
  - [Running in Development Mode](#running-in-development-mode)
  - [Building for Production](#building-for-production)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Overview
Waste Detector is a mobile application designed to identify and classify different types of waste using computer vision and machine learning techniques. The application aims to help users properly sort waste for recycling and disposal, contributing to better waste management practices.

## Technologies Used
- **Flutter/Dart**: For cross-platform mobile application development
- **Python**: ML model training, preprocessing and evaluation scripts
- **TensorFlow/Keras**: For training waste classification models
- **TensorFlow Lite**: For on-device inference of waste classification models

## Features
- Real-time waste detection and classification
- User-friendly interface for waste identification
- Support for multiple waste categories
- Offline functionality for use without internet connection
- Educational information about proper waste disposal

## Project Structure
```
waste-detector/
├── data/
│   ├── processed/          # Processed datasets
│   │   ├── TEST/           # Test dataset
│   │   └── TRAIN/          # Training dataset
│   └── raw/                # Raw datasets
│       ├── DATASET/
│       ├── O/
│       └── R/
├── model/                  # Trained models
│   ├── best_model.h5       # Best performing model
│   ├── final_model.h5      # Final trained model
│   ├── waste_classifier_quant.tflite  # Quantized TFLite model
│   └── waste_classifier.tflite        # TFLite model
├── project_root (waste_detector)/     # Flutter app
│   ├── android/            # Android-specific code
│   ├── assets/             # App assets
│   ├── ios/                # iOS-specific code
│   ├── lib/                # Dart source files
│   ├── linux/              # Linux platform code
│   ├── macos/              # macOS platform code
│   ├── test/               # App tests
│   ├── web/                # Web platform code
│   ├── windows/            # Windows platform code
│   └── [Flutter config files]
└── src_ml/                 # Machine learning source code
    ├── evaluate.py         # Model evaluation script
    ├── export_tflite.py    # Script to export models to TFLite
    ├── preprocess.py       # Data preprocessing script
    ├── train.py            # Model training script
    └── verify.py           # Model verification script
```

## Installation

### Prerequisites
- Flutter SDK
- Python 3.7+
- TensorFlow 2.x
- Android Studio or Xcode

### Setting Up the Environment
1. Clone the repository:
   ```
   git clone https://github.com/neurrochmat/waste-detector.git
   ```
2. Set up the Python environment for ML:
   ```
   cd waste-detector
   pip install -r requirements.txt  # If provided
   ```
3. Set up the Flutter app:
   ```
   cd project_root
   flutter pub get
   ```

## Machine Learning Pipeline

### Data Preprocessing
```
python src_ml/preprocess.py
```

### Model Training
```
python src_ml/train.py
```

### Model Evaluation
```
python src_ml/evaluate.py
```

### Export to TFLite
```
python src_ml/export_tflite.py
```

## Building the Flutter App

### Running in Development Mode
```
cd project_root
flutter run
```

### Building for Production
```
flutter build apk  # For Android
flutter build ios  # For iOS
```

## Usage
1. Open the application on your mobile device
2. Point your camera at the waste item
3. The app will identify the type of waste
4. Follow the disposal recommendations provided by the app

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements
- [TensorFlow](https://www.tensorflow.org/)
- [Flutter](https://flutter.dev/)
- All contributors who have helped with the development of this project
