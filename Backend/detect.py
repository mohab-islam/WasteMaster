import time
import cv2
from ultralytics import YOLO

# ----------------------------
# SETTINGS
# ----------------------------
MODEL_PATH = "besto.pt"      # best.pt in the same folder
CAM_INDEX = 0

FRAME_WIDTH = 960           # if slow -> 640
FRAME_HEIGHT = 540          # if slow -> 360

IMGSZ = 224                 # classification default
TARGET_FPS = 15             # if slow -> 10

# map your classes to bins (edit if needed)
BIN_FOR_CLASS = {
    "cardboard": "PAPER",
    "paper": "PAPER",
    "plastic": "PLASTIC",
    "metal": "METAL",
    "glass": "GLASS",
    "trash": "TRASH",
}

# ----------------------------
# CAMERA
# ----------------------------
# ----------------------------
# MODEL WRAPPER
# ----------------------------
model = None

def init_model():
    global model
    if model is None:
        print(f"[Init] Loading Model: {MODEL_PATH}")
        try:
            model = YOLO(MODEL_PATH)
            print("[OK] Model loaded.")
        except Exception as e:
            print(f"[Error] Could not load {MODEL_PATH}: {e}")
            print("Falling back to yolov8n-cls.pt (Classification)...")
            model = YOLO("yolov8n-cls.pt")

def detect_waste():
    """
    Called by pi_client.py
    Opens camera, takes 1 picture, predicts, returns (label, conf).
    """
    init_model()
    
    cap = cv2.VideoCapture(CAM_INDEX)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, FRAME_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, FRAME_HEIGHT)
    
    # Warmup / Buffer clear
    # Sometimes the first frame is black or old buffer
    for _ in range(2): 
        cap.read()

    ret, frame = cap.read()
    cap.release()

    if not ret:
        print("[Error] Cam failed")
        return None, 0.0

    # Inference
    try:
        r = model.predict(frame, imgsz=IMGSZ, verbose=False)[0]
        
        # Classification (probs) vs Object Detection (boxes) check
        if hasattr(r, 'probs') and r.probs is not None:
             # Classification Model
            cls_id = int(r.probs.top1)
            label = r.names[cls_id]
            conf = float(r.probs.top1conf)
        else:
            # Fallback to Object Detection logic just in case user swaps model type back
            # Pick highest conf box
            best_conf = 0.0
            label = "unknown"
            for box in r.boxes:
                if float(box.conf) > best_conf:
                    best_conf = float(box.conf)
                    label = r.names[int(box.cls)]
            conf = best_conf

        print(f"[Debug] Detect: {label} ({conf:.2f})")
        return label, conf
        
    except Exception as e:
        print(f"[Error] Inference failed: {e}")
        return None, 0.0


# ----------------------------
# STANDALONE LOOP (TESTING)
# ----------------------------
if __name__ == "__main__":
    init_model()
    
    cap = cv2.VideoCapture(CAM_INDEX)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, FRAME_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, FRAME_HEIGHT)

    # simple fps limiter
    frame_time = 1.0 / float(TARGET_FPS)
    last_ts = time.time()
    
    print("--- Running Standalone Loop (Press 'q' to quit) ---")

    while True:
        now = time.time()
        if now - last_ts < frame_time:
            continue
        last_ts = now

        ret, frame = cap.read()
        if not ret:
            break

        # Predict
        results = model.predict(frame, imgsz=IMGSZ, verbose=False)
        r = results[0]
        
        if hasattr(r, 'probs') and r.probs is not None:
            cls_id = int(r.probs.top1)
            label = r.names[cls_id]
            conf = float(r.probs.top1conf)
        else:
            # Fallback for OD model
            label = "Object"
            conf = 0.0
            if len(r.boxes) > 0:
                label = r.names[int(r.boxes[0].cls)]
                conf = float(r.boxes[0].conf)

        bin_name = BIN_FOR_CLASS.get(label, "TRASH")

        # display
        cv2.putText(frame, f"{label} ({conf:.2f}) -> {bin_name}", (20, 40),
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0,255,0), 2)

        cv2.imshow("Waste Classification (Pi)", frame)

        if cv2.waitKey(1) & 0xFF == ord("q"):
            break

    cap.release()
    cv2.destroyAllWindows()
