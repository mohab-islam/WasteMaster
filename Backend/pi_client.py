import requests
import json
import time

# CONFIGURATION
# ---------------------------------------------------------
# RELACE with your Render URL or Local IP
API_URL = "https://wastemaster.onrender.com/api/token/generate" 
# API_URL = "http://192.168.1.X:5000/api/token/generate"

WASTE_TYPE = "plastic" # or "can", "paper"
# ---------------------------------------------------------

def generate_token():
    print(f"\n[IoT] Analyzing Waste: {WASTE_TYPE}...")
    time.sleep(1) # Simulate sensor processing

    try:
        payload = {"wasteType": WASTE_TYPE}
        response = requests.post(API_URL, json=payload)
        
        if response.status_code == 201:
            data = response.json()
            token = data.get("token")
            points = data.get("points")
            qr_url = data.get("qrUrl")

            print("\n✅ SUCCESS! Token Generated.")
            print(f"   Token: {token}")
            print(f"   Points: {points}")
            print(f"   QR Code URL: {qr_url}")
            
            # In a real Pi project, you would display the QR code on a screen here.
            # For now, we print the URL.
            print("\n[DISPLAY] Showing QR Code on Screen...")
            
        else:
            print(f"\n❌ FAILED. Status: {response.status_code}")
            print(response.text)

    except Exception as e:
        print(f"\n❌ ERROR: {e}")

if __name__ == "__main__":
    print("--- WasteMaster IoT Client ---")
    print("Press Ctrl+C to exit")

    # MODE: Set to True for real hardware, False for keyboard simulation
    REAL_HARDWARE = False 

    if REAL_HARDWARE:
        try:
            import RPi.GPIO as GPIO
            
            # Setup GPIO
            SENSOR_PIN = 17 # Example GPIO pin for your sensor within the Pi
            GPIO.setmode(GPIO.BCM)
            GPIO.setup(SENSOR_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)

            print(f"[HW] Monitoring GPIO {SENSOR_PIN} for waste detection...")
            
            def sensor_callback(channel):
                print(f"\n[HW] Sensor Triggered on channel {channel}!")
                generate_token()

            # Add event listener
            GPIO.add_event_detect(SENSOR_PIN, GPIO.FALLING, callback=sensor_callback, bouncetime=300)
            
            # Keep script running
            while True:
                time.sleep(1)

        except ImportError:
            print("❌ RPi.GPIO module not found. Are you running this on a Raspberry Pi?")
        except Exception as e:
            print(f"Error: {e}")
            
    else:
        # --- SIMULATION MODE ---
        while True:
            cmd = input("\n[SIM] Press ENTER to simulate sorting trash (or 'q' to quit)...")
            if cmd.lower() == 'q':
                break
            generate_token()
