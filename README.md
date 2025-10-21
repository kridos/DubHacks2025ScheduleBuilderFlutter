# Flutter Frontend Setup Guide

## Prerequisites

Before running the Flutter frontend on Android, ensure you have the following installed:

- **Flutter SDK**
- **Android Studio**
- **Visual Studio Code (recommended)**

Verify your Flutter installation by running:

```bash
flutter doctor
```

---

## Configuration Steps

### 1. Google Cloud Authentication Setup

Create a Google Cloud project with OAuth 2.0 credentials:

1. Navigate to the **Google Cloud Console**
2. Create a new project or select an existing one
3. Enable the **Google Sign-In API**
4. Configure the **OAuth consent screen** and add test users
5. Create **OAuth 2.0 credentials** for Android

> **Note:** Only designated test users will be able to authenticate during development.

---

### 2. Firebase Project Setup

1. Create a new **Firebase project** in the [Firebase Console](https://console.firebase.google.com/)
2. Add an **Android app** to your Firebase project
3. Register your app with the package name: `com.example.sched_builder`
4. Download the `google-services.json` file
5. Place the file in the `android/app/` directory

> **Important:** The `google-services.json` file contains your Firebase API key. Keep this file secure and **do not commit it to version control.**

---

### 3. Install Dependencies

Navigate to the project directory and run:

```bash
flutter pub get
```

---

### 4. Android Emulator Setup

1. Open **Android Studio**
2. Navigate to **Tools > Device Manager**
3. Create and launch a virtual device (AVD)
4. Ensure the emulator is running before proceeding

---

### 5. Running the Application

1. Open the project in **Visual Studio Code**
2. Verify the Android emulator is detected (check the bottom-right corner of VS Code)
3. Run the application:

```bash
flutter run
```

---

## Backend Setup

For backend configuration and setup instructions, please refer to the https://github.com/kridos/Dubhacks2025ScheduleBuilderAPI

---

## Troubleshooting

If you encounter issues:

- Run `flutter doctor` to diagnose common problems
- Ensure the Android emulator is fully booted before running the app
- Verify that `google-services.json` is in the correct location
- Check that test users are properly configured in **Google Cloud Console**
