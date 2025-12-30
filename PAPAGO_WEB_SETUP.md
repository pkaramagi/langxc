# Papago API - Web Platform CORS Issue

## The Problem

The Papago API **does not support direct calls from web browsers** due to CORS (Cross-Origin Resource Sharing) restrictions. When you try to call the API from your Flutter web app, you'll see:

```
Access to fetch at 'https://openapi.naver.com/v1/papago/n2mt' has been blocked by CORS policy
```

This is a security restriction by Naver - the API is designed to be called from **backend servers only**, not from browsers.

---

## Current Status

✅ **Android/iOS**: Papago API works perfectly (no CORS restrictions on mobile)  
⚠️ **Web**: Currently using **mock translations** as a fallback  
❌ **Web with real API**: Requires a backend proxy (see solutions below)

---

## Solution Options

### Option 1: Mock Translations (Current - For Demo/Testing)

**Status**: ✅ Already implemented

The app automatically detects web platform and uses mock translations:
- A few common phrases are translated correctly
- Other text gets `[Mock Translation]` prefix
- Good for UI testing and development
- No setup needed

**Code**: See `lib/core/services/translation_service.dart`

---

### Option 2: Backend Proxy Server (Recommended for Production)

Create a simple backend server that calls Papago API on behalf of your web app.

#### A. Node.js/Express Proxy (Simplest)

1. **Create `backend/server.js`**:

```javascript
const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
app.use(cors());
app.use(express.json());

const PAPAGO_CLIENT_ID = 'jguso0raed';
const PAPAGO_CLIENT_SECRET = 'W6K8dAbPlJqPJZxc3VsUUqpd5WSbw2zU10tbLASj';

app.post('/api/translate', async (req, res) => {
  try {
    const { text, source, target } = req.body;
    
    const response = await axios.post(
      'https://openapi.naver.com/v1/papago/n2mt',
      new URLSearchParams({
        source,
        target,
        text
      }),
      {
        headers: {
          'X-Naver-Client-Id': PAPAGO_CLIENT_ID,
          'X-Naver-Client-Secret': PAPAGO_CLIENT_SECRET,
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      }
    );
    
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000, () => {
  console.log('Papago proxy running on http://localhost:3000');
});
```

2. **Install dependencies**:
```bash
cd backend
npm init -y
npm install express cors axios
```

3. **Run the server**:
```bash
node server.js
```

4. **Update Flutter app** (`lib/core/constants/app_constants.dart`):
```dart
static const String papagoApiUrl = kIsWeb 
    ? 'http://localhost:3000/api/translate'  // Proxy for web
    : 'https://openapi.naver.com/v1/papago/n2mt';  // Direct for mobile
```

5. **Update translation service** to handle the proxy response format.

---

#### B. Firebase Cloud Functions (Serverless)

1. **Create `functions/index.js`**:

```javascript
const functions = require('firebase-functions');
const axios = require('axios');

exports.translateText = functions.https.onCall(async (data, context) => {
  const { text, source, target } = data;
  
  const response = await axios.post(
    'https://openapi.naver.com/v1/papago/n2mt',
    new URLSearchParams({ source, target, text }),
    {
      headers: {
        'X-Naver-Client-Id': functions.config().papago.clientid,
        'X-Naver-Client-Secret': functions.config().papago.clientsecret,
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    }
  );
  
  return response.data;
});
```

2. **Deploy**:
```bash
firebase functions:config:set papago.clientid="jguso0raed" papago.clientsecret="W6K8dAbPlJqPJZxc3VsUUqpd5WSbw2zU10tbLASj"
firebase deploy --only functions
```

3. **Call from Flutter** using `cloud_functions` package.

---

### Option 3: Use Alternative Translation API

Consider switching to an API with CORS support for web:

- **Google Cloud Translation API** - Has CORS support, paid
- **LibreTranslate** - Open source, self-hostable
- **DeepL API** - High quality, has free tier

---

## Google Sign-In COOP Warnings

The "Cross-Origin-Opener-Policy" warnings you're seeing are **not errors** - they're browser security notices. Google Sign-In will still work despite these warnings.

**If you want to suppress them** (optional):

Add to `web/index.html` in `<head>`:
```html
<meta http-equiv="Cross-Origin-Opener-Policy" content="same-origin-allow-popups">
```

Or configure your web server headers (for production deployment).

---

## Testing the Current Setup

1. **On Android/iOS**: Real Papago translations work
2. **On Web**: Mock translations work (demo mode)
3. **With Backend Proxy**: Real translations work on all platforms

Run the app:
```bash
# Web (mock translations)
flutter run -d chrome

# Android (real translations)
flutter run -d <android-device-id>
```

---

## Recommended Approach

**For Development**: Use current mock translations (no setup needed)  
**For Production**: Implement Node.js proxy or Firebase Functions

The backend proxy is the cleanest solution and also adds:
- Rate limiting
- Usage tracking
- API key security (keys never exposed to browser)
- Ability to switch translation providers easily

---

## Questions?

- Backend proxy not working? Check CORS headers and port configuration
- Want to use a different translation API? Update `translation_service.dart`
- Need help with Firebase Functions? See Firebase docs: https://firebase.google.com/docs/functions

