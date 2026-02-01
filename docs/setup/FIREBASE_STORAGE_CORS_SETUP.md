# Firebase Storage CORS Setup

## Problem

When running the app on web (e.g. `http://localhost:62557`), uploading images to Firebase Storage for the Style Feed fails with:

```
Access to XMLHttpRequest at 'https://firebasestorage.googleapis.com/...' from origin 'http://localhost:62557' 
has been blocked by CORS policy: Response to preflight request doesn't pass access control check
```

## Solution

Configure CORS on your Firebase Storage bucket using the provided `cors.json` and `gsutil`.

1. **Ensure Google Cloud SDK is installed** (includes `gsutil`)
   - Download: https://cloud.google.com/sdk/docs/install

2. **Authenticate and set project**
   ```bash
   gcloud auth login
   gcloud config set project ai-styling-c45cf
   ```

3. **Apply CORS configuration** (from project root)
   ```bash
   gsutil cors set cors.json gs://ai-styling-c45cf.appspot.com
   ```

4. **Verify** (optional)
   ```bash
   gsutil cors get gs://ai-styling-c45cf.appspot.com
   ```

### Included origins

`cors.json` allows requests from:

- `http://localhost:3000`, `5000`, `58389`, `62557`
- `http://127.0.0.1:*` (same ports)
- `https://ai-styling-c45cf.web.app`
- `https://ai-styling-c45cf.firebaseapp.com`

If you use a different port, add it to the `origin` array in `cors.json` and re-run the setup.

---

## OpenRouter API Timeout (AI Chat)

If the dashboard AI chat shows no response or times out:

1. **Check API key**: Ensure `OPENROUTER_API_KEY` is set (e.g. in `UserSecretsService` / environment).
2. **Network**: Confirm your machine can reach `https://openrouter.ai`.
3. **Key validity**: Verify the key at https://openrouter.ai/keys.
