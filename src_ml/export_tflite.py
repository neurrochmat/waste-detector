import tensorflow as tf

# Load model Keras
model = tf.keras.models.load_model("../model/best_model.h5")

# Converter dengan optimasi
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]

# Jika ingin quantize ke UINT8, perlu representative dataset
def representative_data_gen():
    import numpy as np
    from PIL import Image
    # Ambil beberapa gambar dari data train sebagai contoh
    for i, img_path in enumerate(tf.io.gfile.glob("../data/processed/train/organik/*.jpg")[:100]):
        img = Image.open(img_path).resize((224,224))
        img = np.array(img, dtype=np.float32) / 255.0
        img = np.expand_dims(img, axis=0)
        yield [img]
    for i, img_path in enumerate(tf.io.gfile.glob("../data/processed/train/anorganik/*.jpg")[:100]):
        img = Image.open(img_path).resize((224,224))
        img = np.array(img, dtype=np.float32) / 255.0
        img = np.expand_dims(img, axis=0)
        yield [img]

converter.representative_dataset = representative_data_gen
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
converter.inference_input_type = tf.uint8   # atau tf.int8
converter.inference_output_type = tf.uint8  # atau tf.int8

tflite_quant_model = converter.convert()
output_path = "../model/waste_classifier_quant.tflite"
with open(output_path, "wb") as f:
    f.write(tflite_quant_model)

print(f"Model quantized TFLite ter-export di: {output_path}")
