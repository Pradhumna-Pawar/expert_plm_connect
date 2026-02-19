# Firebase Setup & Configuration Guide

## 🔴 Current Errors

### Error 1: Google Sign-In Developer Error
```
Not showing notification since connectionResult is not user-facing: 
ConnectionResult{statusCode=DEVELOPER_ERROR, ...}
```

### Error 2: Firestore API Not Enabled
```
Cloud Firestore API has not been used in project expert-plm-connect 
before or it is disabled. Enable it by visiting 
https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=expert-plm-connect
```

---

## ✅ Solution Steps

### Step 1: Enable Firestore API (CRITICAL)

1. **Open the direct link from error message:**
   ```
   https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=expert-plm-connect
   ```

2. **Or manually enable it:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Select project: **expert-plm-connect**
   - Click **APIs & Services** → **Library**
   - Search for **"Cloud Firestore API"**
   - Click on it
   - Click **ENABLE** button
   - Wait 2-3 minutes for activation

3. **Verify it's enabled:**
   - You should see "API is enabled" in green

---

### Step 2: Enable Google Cloud APIs Required

Enable these APIs in Google Cloud Console:

1. **Cloud Firestore API** ✅ (from Step 1)
2. **Identity and Access Management (IAM) API**
3. **Service Usage API**
4. **Google Identity Platform API**

**How to enable:**
- Go to **APIs & Services** → **Library**
- Search for each API
- Click **ENABLE**

---

### Step 3: Fix Google Sign-In Configuration

**Issue:** OAuth2 configuration is incomplete

1. **Get your SHA-1 fingerprint:**
   ```bash
   gradlew.bat signingReport
   ```
   - Copy the **SHA-1** from **debug** key
   - Example: `a2e96aff86748b273227b15939a90bb07c0503ea`

2. **Add to Firebase Console:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select **expert-plm-connect** project
   - Go to **Project Settings** ⚙️
   - Click on your Android app
   - Add SHA-1 fingerprint to **SHA certificate fingerprints**
   - Click **Save**

3. **Verify Google Sign-In is enabled:**
   - Go to **Authentication** → **Sign-in method**
   - Ensure **Google** is **ENABLED** (toggle switch ON)
   - Check **Web SDK configuration** is set

---

### Step 4: Configure Firestore Security Rules

1. **Go to Firebase Console:**
   - Select **expert-plm-connect** project
   - Click **Firestore Database** (left sidebar)
   - If not created, click **Create Database**

2. **Set Security Rules:**
   - Click **Rules** tab
   - Replace with this (for development):
   ```firestore
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Allow read/write for authenticated users
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```
   - Click **Publish**

3. **Start in test mode (temporary):**
   - Or select **Start in test mode** when creating database
   - This allows any user to read/write for 30 days

---

### Step 5: Enable Billing (If Not Already Done)

⚠️ **Required for OAuth and API usage**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Project Settings** ⚙️
3. Click **Billing**
4. Click **Link Billing Account**
5. Follow payment setup

---

### Step 6: Update Android Configuration (If Needed)

**File:** `android/app/build.gradle.kts`

Ensure these settings:
```gradle
android {
    compileSdk 34
    
    defaultConfig {
        applicationId = "com.example.expert_plm_connect"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}
```

---

## 📋 Complete Checklist

### Firebase Console Setup
- [ ] **Billing enabled** - Required for APIs
- [ ] **Firestore API enabled** - For database
- [ ] **Google Sign-In enabled** - In Authentication
- [ ] **SHA-1 fingerprint added** - For Android
- [ ] **Firestore database created** - With test mode or security rules
- [ ] **Security rules published** - Allow authenticated access

### Android Configuration
- [ ] **google-services.json present** - In `android/app/`
- [ ] **compileSdk = 34** - In build.gradle.kts
- [ ] **minSdk = 21** - In build.gradle.kts
- [ ] **Permissions in AndroidManifest.xml** - Internet, GET_ACCOUNTS

### Code Configuration
- [ ] **firebase_core: ^3.12.1** - In pubspec.yaml
- [ ] **firebase_auth: ^5.5.1** - In pubspec.yaml
- [ ] **google_sign_in: ^6.2.1** - In pubspec.yaml
- [ ] **Firebase initialization** - In main.dart

---

## 🔧 Quick Fix Commands

### 1. Clean everything
```bash
flutter clean
rm -rf pubspec.lock
flutter pub get
```

### 2. Run with verbose output to see errors
```bash
flutter run -v
```

### 3. Check SHA-1 fingerprint
```bash
gradlew.bat signingReport
```

---

## ⏱️ Timing

After enabling APIs, **wait 2-3 minutes** before testing because:
- Google Cloud takes time to propagate changes
- Firebase needs to activate the APIs
- Firestore needs to initialize

---

## 🧪 Testing After Fix

1. **App should:**
   - ✅ Load without Firebase errors
   - ✅ Allow Google Sign-In/Sign-Up
   - ✅ Save user data to Firestore
   - ✅ Allow Phone OTP
   - ✅ Allow Email/Password auth

2. **Errors should disappear:**
   - ❌ No more "Firestore API not enabled"
   - ❌ No more "DEVELOPER_ERROR" from Google
   - ❌ No more PERMISSION_DENIED messages

---

## 📞 If Still Having Issues

1. **Check error message carefully** - It tells you exactly what to fix
2. **Wait 5 minutes** - APIs take time to activate
3. **Clear browser cache** - Go to console in incognito mode
4. **Regenerate google-services.json:**
   - Firebase Console → Project Settings
   - Download google-services.json again
   - Replace in `android/app/`
   - Run `flutter clean && flutter pub get`

---

## 🚀 After Setup Complete

Once all APIs are enabled:
1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter run`
4. Test all authentication methods:
   - ✅ Google Sign-Up
   - ✅ Google Sign-In
   - ✅ Email/Password
   - ✅ Phone OTP

---

## 📚 Useful Links

- [Enable Firestore API](https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=expert-plm-connect)
- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Firebase Auth Docs](https://firebase.google.com/docs/auth)
- [Firestore Docs](https://firebase.google.com/docs/firestore)

---

**Status: ACTION REQUIRED** 🔴

Complete all steps above and the errors will be fixed!

