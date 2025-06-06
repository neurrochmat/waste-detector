import numpy as np
from PIL import Image
import tensorflow as tf

# Load TFLite model
interpreter = tf.lite.Interpreter(model_path="../model/waste_classifier_quant.tflite")
interpreter.allocate_tensors()

# Dapatkan detail input-output
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Cek tipe input model
input_dtype = input_details[0]['dtype']
input_index = input_details[0]['index']
output_index = output_details[0]['index']

# Fungsi prediksi
def predict_image(img_path):
    # Buka gambar dan ubah ke RGB
    img = Image.open(img_path).convert('RGB').resize((224, 224))
    img = np.array(img)

    # Konversi sesuai dtype model
    if input_dtype == np.float32:
        img = img.astype(np.float32) / 255.0
    elif input_dtype == np.uint8:
        img = img.astype(np.uint8)
    else:
        raise ValueError(f"Tipe input tidak didukung: {input_dtype}")

    img = np.expand_dims(img, axis=0)  # Tambah dimensi batch

    # Set input dan jalankan inferensi
    interpreter.set_tensor(input_index, img)
    interpreter.invoke()

    output_data = interpreter.get_tensor(output_index)

    # Ambil prediksi
    score = output_data[0][0]
    if output_data.dtype == np.uint8:
        score = score / 255.0

    pred = "anorganik" if score >= 0.5 else "organik"
    print(f"{img_path} → Prediksi: {pred} | Skor: {score:.4f}")

# Uji gambar
predict_image("../data/processed/TEST/kangkung.png")
predict_image("../data/processed/TEST/plastik.jpg")
