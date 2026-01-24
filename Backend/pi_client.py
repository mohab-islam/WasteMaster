import requests
import json
import time
import sys
import threading
import cv2
import numpy as np

# Try importing necessary libraries with instructions if missing
try:
    import serial
except ImportError:
    print("Error: 'pyserial' not found. Install with: pip install pyserial")
    serial = None

try:
    from ultralytics import YOLO
except ImportError:
    print("Warning: 'ultralytics' not found. YOLO model will fallback to simulation.")
    YOLO = None

# CONFIGURATION
# ---------------------------------------------------------
# RENDER URL (Production)
API_URL = "https://wastemaster.onrender.com/api/token/generate"
# LOCAL TEST URL (Uncomment to use)
# API_URL = "http://localhost:5000/api/token/generate"

SERIAL_PORT = 'COM3' # CHANGE THIS to your Arduino Port (e.g., /dev/ttyACM0 on Pi)
BAUD_RATE = 9600
CAMERA_INDEX = 0

# Class Names from your data.yaml
CLASS_NAMES = ['cardboard', 'glass', 'metal', 'paper', 'plastic', 'trash']

# ---------------------------------------------------------

class WasteMasterClient:
    def __init__(self):
        self.model = None
        self.serial_conn = None
        self.cap = None
        self.running = True
        
        self.setup_model()
        self.setup_serial()
        
    def setup_model(self):
        if YOLO:
            print("[Init] Loading YOLOv8 Model...")
            # Ensure best.pt (your trained model) is in the same folder or provide path
            try:
                self.model = YOLO("best.pt") 
                print("[Init] Model Loaded Successfully.")
            except Exception as e:
                print(f"[Warn] 'best.pt' not found. Trying 'yolov8n.pt'...")
                try:
                    self.model = YOLO("yolov8n.pt")
                    print("[Init] Base Model Loaded.")
                except Exception as e2:
                    print(f"[Error] Failed to load any model: {e2}")
                    self.model = None
        else:
            print("[Init] YOLO library not present. Running in SIMULATION MODE for inference.")

    def setup_serial(self):
        if not serial:
            return
            
        try:
            self.serial_conn = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
            print(f"[Init] Connected to Arduino on {SERIAL_PORT}")
            # Flush startup junk
            time.sleep(2) 
            self.serial_conn.reset_input_buffer()
        except Exception as e:
            print(f"[Error] Serial Connection Failed: {e}")
            print(f"       Ensure Arduino is connected and SERIAL_PORT is correct.")
            self.serial_conn = None

    def generate_token(self, waste_type):
        print(f"\n[API] Generating Token for: {waste_type}...")
        
        try:
            payload = {"wasteType": waste_type}
            response = requests.post(API_URL, json=payload, timeout=10)
            
            if response.status_code == 201:
                data = response.json()
                token = data.get("token")
                qr_url = data.get("qrUrl")
                points = data.get("points")
                
                print("✅ Token Generated!")
                print(f"   Value: {token}")
                print(f"   Points: {points}")
                
                self.display_qr(qr_url, token, waste_type)
            else:
                print(f"❌ API Error: {response.status_code} - {response.text}")

        except Exception as e:
            print(f"❌ Network Error: {e}")

    def display_qr(self, url, token, waste_type):
        """
        Fetches QR code image and displays it fullscreen.
        """
        print(f"[Display] Fetching QR Code from {url}...")
        try:
            resp = requests.get(url)
            if resp.status_code == 200:
                # Convert raw bytes to numpy array for cv2
                image_array = np.asarray(bytearray(resp.content), dtype=np.uint8)
                qr_img = cv2.imdecode(image_array, cv2.IMREAD_COLOR)
                
                # Resize for visibility (optional, fit to screen)
                # For Pi LCD (e.g., 800x480), trigger fullscreen
                
                # Add Text overlay
                cv2.putText(qr_img, f"Type: {waste_type.upper()}", (10, 30), 
                            cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 0), 2)
                cv2.putText(qr_img, "Scan to Claim!", (10, 190), 
                            cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255), 2)

                cv2.namedWindow("WasteMaster QR", cv2.WINDOW_NORMAL)
                cv2.setWindowProperty("WasteMaster QR", cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_FULLSCREEN)
                cv2.imshow("WasteMaster QR", qr_img)
                
                # Show for 10 seconds or until key press
                print("[Display] Showing QR code for 10 seconds...")
                cv2.waitKey(10000) 
                cv2.destroyWindow("WasteMaster QR")
            else:
                print(f"[Error] Failed to fetch QR image: {resp.status_code}")
                
        except Exception as e:
            print(f"[Error] Display logic failed: {e}")

    def capture_and_infer(self):
        """
        Captures an image from the camera and runs inference.
        Returns the detected class name or 'trash' if multiple/unknown.
        """
        print("[Cam] Capturing image for analysis...")
        
        cap = cv2.VideoCapture(CAMERA_INDEX)
        if not cap.isOpened():
            print("[Error] Camera not found.")
            return "unknown"
            
        ret, frame = cap.read()
        cap.release()
        
        if not ret:
            print("[Error] Failed to capture frame.")
            return "unknown"

        if self.model:
            # Run YOLO Inference
            results = self.model(frame)
            
            # Simple logic: pick the detection with highest confidence
            highest_conf = 0.0
            detected_class = "unknown"
            
            for r in results:
                for box in r.boxes:
                    conf = float(box.conf)
                    cls_id = int(box.cls)
                    if conf > highest_conf:
                        highest_conf = conf
                        if cls_id < len(CLASS_NAMES):
                            detected_class = CLASS_NAMES[cls_id]
                        else:
                            detected_class = "trash" # Default fallback
            
            print(f"[AI] Detected: {detected_class} ({highest_conf:.2f})")
            
            # Threshold
            if highest_conf < 0.4:
                print("[AI] Confidence too low. Ignoring.")
                return None
                
            return detected_class
        else:
            # Simulation fallback
            print("[Sim] Simulating detection 'plastic'...")
            return "plastic"

    def loop(self):
        print("\n--- WasteMaster IoT Client Running ---")
        if not self.serial_conn:
            print("[Warn] No Serial. Press 'Enter' in console to simulate trigger.")
            
        while self.running:
            try:
                triggered = False
                
                # 1. Check Serial Trigger
                if self.serial_conn and self.serial_conn.in_waiting > 0:
                    line = self.serial_conn.readline().decode('utf-8').strip()
                    if line == "DETECTED":
                        print("\n[Trig] Ultrasonic Sensor Triggered!")
                        triggered = True
                
                # 2. Manual Trigger (for testing without Arduino)
                if not self.serial_conn:
                    if sys.stdin in select.select([sys.stdin], [], [], 0)[0]:
                         sys.stdin.read(1) # Clear buffer
                         triggered = True
                         
                # 3. Process Trigger
                if triggered:
                    waste_class = self.capture_and_infer()
                    
                    if waste_class:
                        self.generate_token(waste_class)
                    
                    # Debounce/Cooldown to prevent double scanning the same item immediately
                    time.sleep(2)
                    if self.serial_conn:
                        self.serial_conn.reset_input_buffer()

                time.sleep(0.1)
                
            except KeyboardInterrupt:
                print("\nExiting...")
                self.running = False
            except Exception as e:
                # print(f"Loop Error: {e}")
                time.sleep(0.1)

if __name__ == "__main__":
    # Needed for manual non-blocking input check on Windows? 
    # Actually, Windows doesn't support select on stdin. 
    # We will stick to Serial for main loop and a simple blocking input fallback if serial fails is simpler for now,
    # OR better yet, just run the loop.
    
    # Correction for Windows Manual Trigger for testing:
    # We'll just define a simple loop.
    
    client = WasteMasterClient()
    
    if client.serial_conn:
        client.loop()
    else:
        print("[Mode] Manual Input Mode (No Serial)")
        while True:
            cmd = input("Press Enter to simulate Detector (q to quit): ")
            if cmd == 'q': break
            
            waste_class = client.capture_and_infer()
            if waste_class:
                client.generate_token(waste_class)

