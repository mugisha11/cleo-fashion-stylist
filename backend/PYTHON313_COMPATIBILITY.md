# Python 3.13 Compatibility Fixes

## Issue
The original `requirements.txt` had pinned versions that don't support Python 3.13:
- `numpy==1.24.3` - No wheels for Python 3.13
- `Pillow==10.1.0` - Build issues with Python 3.13
- `scipy==1.11.4` - May have compatibility issues

## Solution
Updated to use Python 3.13 compatible versions:

### Updated Versions
- **numpy**: `>=1.26.0,<3.0` → Installed: `2.3.5`
- **Pillow**: `>=10.2.0` → Installed: `12.0.0`
- **scipy**: `>=1.11.0` → Installed: `1.16.3`

### Installation
```bash
cd backend
python -m pip install -r requirements.txt
```

## Notes
- Python 3.13 is very new, so some packages may still have compatibility issues
- If you encounter issues, consider using Python 3.11 or 3.12 for better package compatibility
- The updated requirements use `>=` constraints to allow pip to find compatible versions

## Alternative: Use Python 3.11 or 3.12
If you continue to have issues, consider using Python 3.11 or 3.12:
```bash
# Install Python 3.11 or 3.12
# Then create a virtual environment
python3.11 -m venv venv
# or
python3.12 -m venv venv

# Activate and install
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate  # Windows

pip install -r requirements.txt
```

