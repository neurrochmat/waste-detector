import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.models import load_model

TEST_DIR = "../data/processed/TEST"
# Path untuk data test
IMG_SIZE = (224, 224)
BATCH_SIZE = 32

# Load model terbaik
model = load_model("../model/best_model.h5")

# Data test (hanya rescale, tanpa augmentasi)
test_datagen = ImageDataGenerator(rescale=1.0/255)
test_generator = test_datagen.flow_from_directory(
    TEST_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='binary',
    shuffle=False
)

# Evaluasi
loss, acc = model.evaluate(test_generator)
print(f"Test Loss: {loss:.4f}")
print(f"Test Accuracy: {acc:.4f}")

# Menampilkan classification report (precision, recall, f1-score)
import numpy as np
from sklearn.metrics import classification_report, confusion_matrix

# Prediksi
y_true = test_generator.classes
y_pred_prob = model.predict(test_generator)
y_pred = (y_pred_prob > 0.5).astype(int).reshape(-1)

print("Classification Report:")
print(classification_report(y_true, y_pred, target_names=["organik", "anorganik"]))

print("Confusion Matrix:")
print(confusion_matrix(y_true, y_pred))
