# System & Project Requirements

To run the **WasteMaster V2** project successfully on a different PC, ensure the following requirements are met.

## 🖥️ System Requirements
*   **Operating System**: Windows 10/11, macOS, or Linux. (Windows recommended for this specific build).
*   **RAM**: Minimum 8GB (16GB recommended for running Android Emulator + Server).
*   **Disk Space**: At least 10GB free space (for Android Studio, SDKs, and dependencies).

## 🛠️ Software Prerequisites
You must install these tools before running the project:

1.  **Node.js**:
    *   **Version**: v16.0.0 or higher.
    *   **Check**: Run `node -v` in terminal.
2.  **Flutter SDK**:
    *   **Version**: Stable channel (latest).
    *   **Check**: Run `flutter doctor` to verify installation.
3.  **MongoDB**:
    *   **Type**: Community Server (Local) or Atlas (Cloud).
    *   **Status**: Must be running on port `27017` for local setup.
4.  **Git**: For version control (optional but recommended).

## 📦 Project Dependencies
The specific libraries used in this project are defined in the standard configuration files:

### 1. Backend (Node.js)
*   **File**: `Backend/package.json`
*   **Key Libraries**:
    *   `express`: Web server framework.
    *   `mongoose`: MongoDB object modeling.
    *   `dotenv`: Environment variable management.
    *   `cors`: Cross-origin resource sharing.
    *   `mqtt`: For IoT (ESP32) communication.

### 2. Mobile App (Flutter)
*   **File**: `mobile app/pubspec.yaml`
*   **Key Packages**:
    *   `http`: API communication.
    *   `mobile_scanner`: QR code scanning.
    *   `shared_preferences`: Local storage (auth tokens).
    *   `google_fonts`: Typography.
    *   `intl`: Date formatting.

## 🚀 Installation Commands
(See `README.md` for full guide)

**Backend**:
```bash
npm install
```

**Mobile**:
```bash
flutter pub get
```
