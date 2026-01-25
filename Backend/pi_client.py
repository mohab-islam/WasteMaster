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

# Import our new Detection Module
try:
    import detect
except ImportError:
    print("Error: 'detect.py' not found in the same directory.")
    sys.exit(1)

# CONFIGURATION
# ---------------------------------------------------------
# RENDER URL (Production)
API_URL = "https://wastemaster.onrender.com/api/token/generate"
# LOCAL TEST URL (Uncomment to use)
# API_URL = "http://localhost:5000/api/token/generate"

SERIAL_PORT = 'COM3' # CHANGE THIS to your Arduino Port (e.g., /dev/ttyACM0 on Pi)
BAUD_RATE = 9600
# ---------------------------------------------------------

class WasteMasterClient:
    def __init__(self):
        self.serial_conn = None
        self.running = True
        self.setup_serial()
        
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
                    # CALL DETECT MODULE
                    print("[AI] Calling Detection...")
                    waste_class, conf = detect.detect_waste()
                    
                    if waste_class:
                        print(f"[AI] Identified: {waste_class} ({conf:.2f})")
                        
                        # VALIDATE AND SEND TO ARDUINO
                        # Map raw YOLO classes to Arduino commands
                        # 'cardboard' -> PAPER, etc.
                        cmd = waste_class.upper()
                        if cmd == "CARDBOARD": cmd = "PAPER"
                        
                        if self.serial_conn:
                            print(f"[Serial] Sending sorting command: {cmd}")
                            self.serial_conn.write(f"{cmd}\n".encode('utf-8'))
                        
                        self.generate_token(waste_class)
                    else:
                        print("[AI] No valid object detected.")
                    
                    # Debounce/Cooldown
                    time.sleep(3) # Increased wait for sorting to finish
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
    client = WasteMasterClient()
    
    if client.serial_conn:
        client.loop()
    else:
        print("[Mode] Manual Input Mode (No Serial)")
        while True:
            cmd = input("Press Enter to simulate Detector (q to quit): ")
            if cmd == 'q': break
            
            # CALL DETECT MODULE
            waste_class, conf = detect.detect_waste()
            if waste_class:
                print(f"[AI] Identified: {waste_class} ({conf:.2f})")
                client.generate_token(waste_class)

