# Quick Start Guide - AI Wardrobe Descriptions & Recommendations

## 🚀 Setup Instructions

### 1. Start the Backend Server

```bash
# Navigate to backend directory
cd backend

# Install dependencies (if not already done)
pip install -r requirements.txt

# Set environment variables (Windows PowerShell)
$env:OPENROUTER_API_KEY="your-openrouter-key"
$env:OPENAI_API_KEY="your-openai-key"

# Run the backend
python -m app.main
# OR: python app/main.py
```

Backend will be available at: `http://localhost:8000`

### 2. Verify Backend is Running

```bash
# In another terminal, test the health endpoint
curl http://localhost:8000/health

# Should return: {"status":"healthy","version":"...","gpu_available":false}
```

### 3. Run Flutter App

```bash
# In the Cleo-fashion-main directory
flutter run

# Choose Chrome (web) or Windows when prompted
```

### 4. Test the Feature

1. Navigate to **Wardrobe** tab in the app
2. Click on any clothing item
3. **Item Details screen opens** with:
   - Item image at top
   - **Professional Description** section (loading... spinner)
   - **Outfit Ideas** section (loading... spinner)
   - Category, quick facts, etc. below

4. Wait 3-5 seconds for AI to generate:
   - Professional description
   - 3 outfit recommendations

## 🔧 Configuration

### API Keys Required

You need two API keys:

1. **OpenRouter API Key** (for Gemini Nano - FREE tier)
   - Sign up at: https://openrouter.ai
   - Copy your API key from dashboard
   - Set: `OPENROUTER_API_KEY=sk-or-...`

2. **OpenAI API Key** (backup/fallback)
   - Sign up at: https://platform.openai.com
   - Create API key: https://platform.openai.com/account/api-keys
   - Set: `OPENAI_API_KEY=sk-...`

### Environment Variables

#### On Windows (PowerShell):
```powershell
# Set for current session
$env:OPENROUTER_API_KEY="your-key-here"
$env:OPENAI_API_KEY="your-key-here"

# Verify they're set
Get-Item env:OPENROUTER_API_KEY
Get-Item env:OPENAI_API_KEY
```

#### On Windows (Command Prompt):
```cmd
set OPENROUTER_API_KEY=your-key-here
set OPENAI_API_KEY=your-key-here
```

#### On Linux/Mac:
```bash
export OPENROUTER_API_KEY="your-key-here"
export OPENAI_API_KEY="your-key-here"
```

### Permanent Setup (Windows)

1. Right-click Computer → Properties
2. Click "Advanced system settings"
3. Click "Environment Variables"
4. Under "User variables", click "New"
5. Variable name: `OPENROUTER_API_KEY`
6. Variable value: `your-actual-key`
7. Click OK, add `OPENAI_API_KEY` same way
8. Restart terminal/IDE

## 📱 Using the Feature

### Step-by-Step

1. **Open Wardrobe Screen**
   - Tap "Wardrobe" tab at bottom

2. **Select an Item**
   - Tap any clothing item card

3. **View Details**
   - Item image displays
   - Description section appears with loading spinner
   - Outfit ideas section appears with loading spinner

4. **Wait for AI Generation** (3-5 seconds typically)
   - Description loads with professional styling tips
   - Outfit recommendations appear with:
     - Outfit name (e.g., "Casual Weekend Look")
     - Description of the vibe
     - Why it works with the item

5. **Scroll Down**
   - See category, quick facts, brand, date added
   - Technical details minimized

## 🐛 Troubleshooting

### Issue: "Unable to generate description"

**Solution**:
1. Check backend is running: `curl http://localhost:8000/health`
2. Verify API keys are set:
   ```powershell
   $env:OPENROUTER_API_KEY
   $env:OPENAI_API_KEY
   ```
3. Check backend logs for errors
4. If backends fail, fallback description should still show

### Issue: Sections show "No description/recommendations available"

**Possible causes**:
- Backend not running
- API keys not configured
- Network connection issue
- API rate limit exceeded

**Solutions**:
1. Start backend: `python -m app.main`
2. Check/set API keys
3. Check internet connection
4. Wait a minute and try again

### Issue: Slow loading (>10 seconds)

**Causes**:
- First-time model load (normal, 5-10 seconds)
- Network latency
- API server responding slow

**Solutions**:
- Be patient on first load
- Check internet speed
- Try with fewer wardrobe items (max 20 sent)

### Issue: "Address already in use" on port 8000

**Solution**:
```bash
# Kill process using port 8000
# Windows PowerShell:
Get-Process -Id (Get-NetTCPConnection -LocalPort 8000).OwningProcess | Stop-Process -Force

# Then restart: python -m app.main
```

## 📊 What's Being Sent to AI

### For Descriptions
```json
{
  "category": "Tops",
  "subcategory": "T-Shirt",
  "brand": "Nike",
  "fit": "Regular",
  "fabric": "Cotton",
  "pattern": "Solid",
  "colors": ["Blue", "White"],
  "occasion": ["Casual"],
  "season": ["Summer"]
}
```

### For Recommendations
Same as above, PLUS:
- Up to 20 items from user's wardrobe
- Colors and patterns of other items
- Occasion/season tags

**Privacy Note**: Only item metadata sent, NOT actual images after initial processing

## 🎯 Expected Results

### Professional Description
✅ Should describe the item in 2-3 sentences
✅ Should mention styling options
✅ Should be user-friendly (no technical jargon)
✅ Should highlight versatility

### Outfit Recommendations
✅ 3 different outfit ideas
✅ Each with a catchy title
✅ Description of the vibe/occasion
✅ Explanation of why it works
✅ Ready-to-wear suggestions

## 📈 Performance Tips

1. **First Load**: 5-10 seconds (model initialization)
2. **Subsequent Loads**: 2-3 seconds (models cached)
3. **Consider Caching**: Save generated descriptions in Firestore

## 🔗 API Endpoints

```
POST http://localhost:8000/wardrobe-ai/description
POST http://localhost:8000/wardrobe-ai/recommendations
```

Test with curl:
```bash
curl -X POST http://localhost:8000/wardrobe-ai/description \
  -H "Content-Type: application/json" \
  -d '{"item": {"category": "Tops", "colors": ["Blue"], "occasion": []}}'
```

## 📞 Support

If issues persist:
1. Check logs in backend terminal
2. Verify network connectivity
3. Confirm API keys are valid
4. Check Flutter app logs (Ctrl+Shift+D in VS Code)
5. Ensure backend port 8000 is not blocked by firewall

## ✅ Success Indicators

- [ ] Backend starts without errors
- [ ] `http://localhost:8000/health` returns JSON
- [ ] Click wardrobe item → shows loading spinners
- [ ] After 3-5 seconds → description appears
- [ ] After 3-5 seconds → outfit ideas appear
- [ ] Descriptions are professional and relevant
- [ ] Recommendations make sense for the item

Congratulations! You're all set to use AI-powered wardrobe descriptions and recommendations! 🎉
