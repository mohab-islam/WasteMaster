# WasteMaster - Full Cycle Integration & Verification Guide

This guide details exactly how to connect the Hardware (Arduino + Pi), setup the Software (Client + Server), and verify the "throw-to-reward" flow.

## 1. System Architecture

- **Trigger**: Ultrasonic Sensor (HC-SR04) detects an object in the smart bin.
- **Controller 1 (Arduino)**: Reads sensor. If distance < 20cm, it sends the string `"DETECTED\n"` over USB Serial.
- **Controller 2 (Raspberry Pi 4)**:
    - Listens to USB Serial.
    - Upon receiving "DETECTED", it captures an image via USB Webcam.
    - Runs **YOLOv8** model to classify waste (e.g., "plastic", "can").
    - Sends `POST /api/token/generate` to the Server.
    - Displays the returned **QR Code** on the LCD Screen (HDMI).
- **Server (Render)**: Validates request, generates unique token, stores in DB.
- **User (Mobile App)**: Scans QR code to claim points.

## 2. Hardware Connection

### Arduino -> Sensors
| Component | Pin | Arduino Pin |
| :--- | :--- | :--- |
| **HC-SR04 VCC** | VCC | 5V |
| **HC-SR04 GND** | GND | GND |
| **HC-SR04 Trig** | Trig | D9 |
| **HC-SR04 Echo** | Echo | D10 |

### Power Supply (Servos)
> [!IMPORTANT]
> **DO NOT** power servos from the Arduino 5V pin.
> See [Power_Connection.md](Power_Connection.md) for the full wiring guide using 3x 3.7V batteries and LM2596.


### Arduino -> Raspberry Pi
- Connect Arduino to Raspberry Pi via **USB Cable**.
- Identify the port on Pi: usually `/dev/ttyACM0` or `/dev/ttyUSB0`.
    - Run `ls /dev/tty*` on Pi to check.

### Raspberry Pi -> Peripherals
- **Camera**: Connect USB Webcam.
- **LCD**: Connect via HDMI (or DSI). Ensure Desktop UI is running.

## 3. Installation & Setup

### A. Arduino
1. Open `Backend/arduino_sensor.ino` in Arduino IDE.
2. Select your board (Uno/Nano) and Port.
3. Upload the sketch.
4. **Test**: Open Serial Monitor (9600 baud). Put your hand in front of the sensor. specific output: `DETECTED`.

### B. Raspberry Pi (Environment)
1. Ensure Python 3.8+ is installed.
2. Install dependencies:
    ```bash
    pip install ultralytics opencv-python pyserial requests numpy
    ```
3. Transfer Files to Pi:
    - `pi_client.py`
    - `detect.py` (New detection module)
    - **Copy your customized model**: `Final Grad/runs/detect/train3/weights/best.pt` -> Rename to `best.pt` and place next to `pi_client.py`.
4. **Configuration**:
    - Edit `pi_client.py`:
        - `SERIAL_PORT`: Set to `/dev/ttyACM0` (or your detected port).
        - Update model path line: `self.model = YOLO("best.pt")` (if you renamed it) or keep `yolov8n.pt` if testing.
        - `API_URL`: Ensure it points to `https://wastemaster.onrender.com/api/token/generate`.

## 4. Running the System
1. **Start Server**: Ensure Backend is running (already on Render).
2. **Connect Hardware**: Plug Arduino into Pi.
3. **Start Client**:
    ```bash
    python pi_client.py
    ```
    - *Expected Output*:
        ```
        [Init] Loading YOLOv8 Model...
        [Init] Connected to Arduino on /dev/ttyACM0
        --- WasteMaster IoT Client Running ---
        ```

## 5. Verification Steps (The "Throw" Cycle)

1. **The Throw**: Toss an item (or place hand) in front of the Ultrasonic Sensor.
2. **The Trigger**: Arduino LED (TX) flashes. Pi console shows: `[Trig] Ultrasonic Sensor Triggered!`.
3. **The Vision**:
    - Pi Camera activates.
    - Console: `[AI] Detected: plastic (0.85)`.
4. **The API**:
    - Console: `✅ Token Generated!`.
5. **The Display**:
    - A Fullscreen Window pops up on the Pi LCD showing a QR Code.
    - It stays for 10 seconds.
6. **The Claim**:
    - Open WasteMaster App -> Scan QR.
    - Verify Points are added to your profile.

## Troubleshooting

- **"Serial Connection Failed"**:
    - Check cable.
    - Check port name (`ls /dev/tty*`).
    - Ensure Serial Monitor is CLOSED on PC/Pi (only one app can access Serial at a time).
- **"Camera not found"**:
    - Change `CAMERA_INDEX = 0` to `1` in `pi_client.py`.
- **"Connection Refused" (API)**:
    - Check Internet connection on Pi.
    - Verify server URL.
