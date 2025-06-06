import os
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras import layers, models
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint

# Ambil path absolut berdasarkan lokasi file ini (train.py)
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'processed'))
TRAIN_DIR = os.path.join(BASE_DIR, 'TRAIN')
VAL_DIR = os.path.join(BASE_DIR, 'TEST')
MODEL_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'model'))

IMG_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 15

# Buat folder model jika belum ada
os.makedirs(MODEL_DIR, exist_ok=True)

# ImageDataGenerator untuk augmentasi (hanya untuk data train)
train_datagen = ImageDataGenerator(
    rescale=1.0/255,
    rotation_range=20,
    width_shift_range=0.1,
    height_shift_range=0.1,
    shear_range=0.1,
    zoom_range=0.1,
    horizontal_flip=True,
    fill_mode='nearest'
)
val_datagen = ImageDataGenerator(rescale=1.0/255)

# Flow dari direktori
train_generator = train_datagen.flow_from_directory(
    TRAIN_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='binary'
)
val_generator = val_datagen.flow_from_directory(
    VAL_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='binary'
)

# Load backbone MobileNetV2 tanpa head (tanpa top/classifier)
base_model = tf.keras.applications.MobileNetV2(
    input_shape=(IMG_SIZE[0], IMG_SIZE[1], 3),
    include_top=False,
    weights='imagenet'
)
base_model.trainable = False  # Freeze layers awal

# Tambahkan custom head
model = models.Sequential([
    base_model,
    layers.GlobalAveragePooling2D(),
    layers.Dropout(0.2),
    layers.Dense(1, activation='sigmoid')  # Dua kelas: O vs R (binary)
])

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001),
    loss='binary_crossentropy',
    metrics=['accuracy']
)

model.summary()

# Callback: early stopping dan checkpoint
checkpoint_path = os.path.join(MODEL_DIR, 'best_model.h5')
callbacks = [
    EarlyStopping(monitor='val_loss', patience=3, restore_best_weights=True),
    ModelCheckpoint(checkpoint_path, monitor='val_loss', save_best_only=True)
]

# Training
history = model.fit(
    train_generator,
    epochs=EPOCHS,
    validation_data=val_generator,
    callbacks=callbacks
)

# Simpan model terakhir
final_model_path = os.path.join(MODEL_DIR, 'final_model.h5')
model.save(final_model_path)
print(f"Model training selesai. Model disimpan di: {final_model_path}")