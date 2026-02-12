# Firebase Storage CORS Setup

## Problem

When running the app on web (e.g. `http://localhost:62557`), uploading images to Firebase Storage for the Style Feed fails with:

```
Access to XMLHttpRequest at 'https://firebasestorage.googleapis.com/...' from origin 'http://localhost:62557' 
has been blocked by CORS policy: Response to preflight request doesn't pass access control check
```

## Solution

Configure CORS on your Firebase Storage bucket using the provided `cors.json` and `gsutil`.

### Step 1: Install Google Cloud SDK (required for `gcloud` and `gsutil`)

If you see **"gcloud is not recognized"** in PowerShell or Command Prompt, the SDK is not installed or not on your PATH.

**Windows:**

1. Download the **Google Cloud SDK installer** for Windows:  
   https://cloud.google.com/sdk/docs/install-sdk#windows  
   (direct: https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe)
2. Run the installer. When prompted, check **"Run gcloud init"** to finish setup.
3. **Close and reopen** your terminal (PowerShell/CMD) so `gcloud` and `gsutil` are on PATH.
4. If still not found, add the SDK path manually. Default install path is usually:
   - `C:\Users\<YourUsername>\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin`  
   Add this to your **System** or **User** PATH in Windows (Settings → System → About → Advanced system settings → Environment Variables).

**macOS / Linux:**  
Use the install script or package manager: https://cloud.google.com/sdk/docs/install

### Step 2: Authenticate and set project

In a **new** terminal (so `gcloud` is recognized):

```bash
gcloud auth login
gcloud config set project ai-styling-c45cf
```

### Step 3: Apply CORS configuration (from project root)

From the folder that contains `cors.json` (your project root). Use the **Firebase Storage bucket** name (often `*.firebasestorage.app`, not `*.appspot.com`):

```bash
gsutil cors set cors.json gs://ai-styling-c45cf.firebasestorage.app
```

If you get **404 The specified bucket does not exist**, list your buckets and use the name shown:

```bash
gsutil ls
```

Then run `gsutil cors set cors.json gs://YOUR_BUCKET_NAME` with the correct bucket.

### Step 4: Verify (optional)

```bash
gsutil cors get gs://ai-styling-c45cf.firebasestorage.app
```

### Included origins

`cors.json` allows requests from:

- **localhost / 127.0.0.1:** `3000`, `5000`, `8080`, `8888`, `5173`, `56832`, `58389`, `58639`, `59873`, `60978`, `61089`, `62557`, `62000`, `63000`
- **Production:** `https://ai-styling-c45cf.web.app`, `https://ai-styling-c45cf.firebaseapp.com`

If your app runs on a **different port** (check the browser URL bar), add `http://localhost:YOUR_PORT` and `http://127.0.0.1:YOUR_PORT` to the `origin` array in `cors.json`, then re-run the `gsutil cors set` command.

---

## OpenRouter API Timeout (AI Chat)

If the dashboard AI chat shows no response or times out:

1. **Check API key**: Ensure `OPENROUTER_API_KEY` is set (e.g. in `UserSecretsService` / environment).
2. **Network**: Confirm your machine can reach `https://openrouter.ai`.
3. **Key validity**: Verify the key at https://openrouter.ai/keys.
