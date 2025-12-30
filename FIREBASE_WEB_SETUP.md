# Firebase Web Configuration - Required Steps

## Current Issue
The web app is using placeholder values for Firebase configuration, causing authentication errors.

## Steps to Fix

### 1. Register a Web App in Firebase Console

1. Go to https://console.firebase.google.com/
2. Select your project: **langxc-46763**
3. Click the gear icon (⚙️) → **Project settings**
4. Scroll to "Your apps" section
5. Click **Add app** → select **Web** (</> icon)
6. Register the app:
   - **App nickname**: `LangXC Web`
   - **Check** "Also set up Firebase Hosting" (optional)
   - Click **Register app**
7. You'll see a config block like this:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyCjpvuWvcRucagAzKFwqelTQbHJ6Ema9oU",
  authDomain: "langxc-46763.firebaseapp.com",
  projectId: "langxc-46763",
  storageBucket: "langxc-46763.firebasestorage.app",
  messagingSenderId: "605821517608",
  appId: "1:605821517608:web:XXXXXXXXXX",  // ← Copy this
  measurementId: "G-XXXXXXXXXX"             // ← Copy this
};
```

8. **Copy the `appId` and `measurementId` values**

### 2. Update `web/index.html`

Replace lines 44-46 with the real values:

```javascript
messagingSenderId: "605821517608",           // ← Already correct
appId: "1:605821517608:web:YOUR_WEB_APP_ID", // ← Paste from Firebase Console
measurementId: "G-YOUR_MEASUREMENT_ID"       // ← Paste from Firebase Console
```

### 3. Update `lib/firebase_options.dart`

Replace lines 67-74 with:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyCjpvuWvcRucagAzKFwqelTQbHJ6Ema9oU',
  appId: '1:605821517608:web:YOUR_WEB_APP_ID',        // ← Paste here
  messagingSenderId: '605821517608',
  projectId: 'langxc-46763',
  authDomain: 'langxc-46763.firebaseapp.com',
  storageBucket: 'langxc-46763.firebasestorage.app',
  measurementId: 'G-YOUR_MEASUREMENT_ID',             // ← Paste here
);
```

### 4. Add Google Sign-In Web Client ID

1. In Firebase Console → **Authentication** → **Sign-in method**
2. Click **Google** provider
3. If not enabled, enable it
4. You'll see a **Web SDK configuration** section with **Web client ID**
5. Copy the Web client ID (looks like: `605821517608-xxxxxxxxx.apps.googleusercontent.com`)

6. Add this meta tag to `web/index.html` (after line 31, before `<title>`):

```html
<!-- Google Sign-In Web Client ID -->
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com" />
```

### 5. Test

After making these changes:

```bash
flutter run -d chrome
```

The authentication errors should be gone.

---

## Quick Reference

From your `google-services.json`:
- ✅ API Key: `AIzaSyCjpvuWvcRucagAzKFwqelTQbHJ6Ema9oU`
- ✅ Project ID: `langxc-46763`
- ✅ Project Number (messagingSenderId): `605821517608`
- ❌ Web App ID: **Need to register web app**
- ❌ Measurement ID: **Need to register web app**
- ❌ Web Client ID (Google Sign-In): **Get from Firebase Console → Authentication**

