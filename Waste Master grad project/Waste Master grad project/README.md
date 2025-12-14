# WasteMaster V2 - Gamified Recycling App ♻️🎮

This project is a full-stack IoT-enabled recycling application features a **Node.js Backend** and a **Flutter Mobile App**.

## 📂 Project Structure
- `Backend/`: Node.js + Express Server + MongoDB
- `mobile app/`: Flutter / Dart Application

---

## 🛠️ Prerequisites
Before running, ensure you have the following installed on your PC:
1.  **Node.js** (v14+): [Download here](https://nodejs.org/)
2.  **MongoDB**: [Download Community Server](https://www.mongodb.com/try/download/community) (Ensure it is running locally on port 27017).
3.  **Flutter SDK**: [Install Guide](https://docs.flutter.dev/get-started/install)
4.  **Android Studio** or **VS Code** with Flutter extensions.

---

## 🚀 Step 1: Backend Setup (Server)

1.  **Navigate to the Backend folder:**
    ```bash
    cd Backend
    ```

2.  **Install Dependencies:**
    ```bash
    npm install
    ```

3.  **Configure Environment:**
    *   Ensure you have a `.env` file in the `Backend` folder.
    *   Content should look like:
        ```env
        PORT=5000
        MONGO_URI=mongodb://127.0.0.1:27017/wastemaster
        MQTT_BROKER=your_mqtt_broker_url_here
        ```

4.  **Seed the Database (First Time Only):**
    *   This populates the challenges for the app.
    ```bash
    node seed_challenges.js
    ```

5.  **Start the Server:**
    ```bash
    npm run dev
    ```
    *   *Success Message:* `Server running on port 5000` & `MongoDB Connected`

---

## 📱 Step 2: Mobile App Setup

1.  **Navigate to the Mobile App folder:**
    ```bash
    cd "mobile app"
    ```

2.  **Install Flutter Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **⚠️ IMPORTANT: Update API IP Address**
    *   Open `lib/services/api_service.dart`.
    *   Find the line:
        ```dart
        static const String baseUrl = 'http://192.168.1.X:5000/api';
        ```
    *   Change `192.168.1.X` to your PC's local IP address (Run `ipconfig` in cmd to find it).
    *   *Note: If running on an Android Emulator on the SAME PC, you can use `10.0.2.2`.*

4.  **Run the App:**
    *   Ensure an Emulator is open or a physical device is connected via USB.
    ```bash
    flutter run
    ```

---

## 🧪 Troubleshooting

*   **"Connection Refused"**: user your PC's IP address (e.g., `192.168.1.5`) instead of `localhost` in the mobile app.
*   **"Disk Full" error**: Run `flutter clean` and free up space.
*   **"MongoDB Connection Error"**: Ensure MongoDB service is running in Windows Services.

---

## 📝 Commands Summary for Handoff

**Backend:**
```bash
cd Backend
npm install
node seed_challenges.js
npm run dev
```

**Mobile:**
```bash
cd "mobile app"
flutter pub get
flutter run
```
