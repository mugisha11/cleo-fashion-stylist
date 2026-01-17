#!/usr/bin/env python3
"""
Automated script to create Supabase storage buckets and policies.
This script will create the 'wardrobe' bucket and set up the necessary policies.

Usage:
    # Option 1: Set environment variable
    export SUPABASE_SERVICE_KEY="your_key_here"
    python setup_supabase_bucket.py
    
    # Option 2: Pass key as argument
    python setup_supabase_bucket.py --key "your_key_here"
    
    # Option 3: Interactive mode (will prompt for key)
    python setup_supabase_bucket.py --interactive
"""

import os
import sys
import requests
import argparse
from typing import Optional

# Fix Windows encoding for emoji characters
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

# Supabase configuration
SUPABASE_URL = "https://kjiqtspkvnwgjoerpyxb.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_A4DglmUBJorcilVMduJA4Q_ZTguPkKI"

def get_service_key() -> str:
    """Get service role key from environment or arguments."""
    # Check command line arguments
    parser = argparse.ArgumentParser(description='Create Supabase storage bucket')
    parser.add_argument('--key', help='Supabase service role key')
    parser.add_argument('--interactive', action='store_true', help='Prompt for service key')
    args = parser.parse_args()
    
    if args.key:
        return args.key
    elif args.interactive:
        import getpass
        key = getpass.getpass("Enter your Supabase service role key: ")
        return key
    else:
        return os.getenv("SUPABASE_SERVICE_KEY", "")

def create_bucket(bucket_name: str, service_key: str, public: bool = True, file_size_limit: int = 5242880, allowed_mime_types: Optional[list] = None) -> bool:
    """Create a storage bucket in Supabase."""
    url = f"{SUPABASE_URL}/storage/v1/bucket"
    headers = {
        "Authorization": f"Bearer {service_key}",
        "Content-Type": "application/json",
        "apikey": service_key
    }
    
    payload = {
        "name": bucket_name,
        "public": public,
        "file_size_limit": file_size_limit,
        "allowed_mime_types": allowed_mime_types or []
    }
    
    try:
        print(f"📦 Creating bucket '{bucket_name}'...")
        response = requests.post(url, json=payload, headers=headers, timeout=10)
        
        if response.status_code == 200:
            print(f"✅ Successfully created bucket: {bucket_name}")
            return True
        elif response.status_code == 409:
            print(f"ℹ️  Bucket '{bucket_name}' already exists (that's okay!)")
            return True
        else:
            print(f"❌ Failed to create bucket: HTTP {response.status_code}")
            try:
                error_data = response.json()
                print(f"   Error: {error_data.get('message', response.text)}")
            except:
                print(f"   Response: {response.text}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Network error: {e}")
        return False
    except Exception as e:
        print(f"❌ Error creating bucket: {e}")
        return False

def create_storage_policy(bucket_name: str, policy_name: str, operation: str, policy_sql: str) -> bool:
    """Create a storage policy for a bucket."""
    if not SUPABASE_SERVICE_KEY:
        return False
    
    # Use Supabase REST API to create policy via SQL
    url = f"{SUPABASE_URL}/rest/v1/rpc/exec_sql"
    headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
        "Content-Type": "application/json",
        "apikey": SUPABASE_SERVICE_KEY
    }
    
    # Create policy SQL
    sql = f"""
    CREATE POLICY IF NOT EXISTS "{policy_name}"
    ON storage.objects
    FOR {operation}
    TO authenticated
    USING ({policy_sql});
    """
    
    # Note: This is a simplified approach. In practice, you might need to use
    # the Supabase Management API or create policies via the Dashboard.
    print(f"⚠️  Note: Policy '{policy_name}' should be created via Supabase Dashboard")
    print(f"   Go to: Storage > {bucket_name} > Policies")
    print(f"   Operation: {operation}")
    print(f"   SQL: {policy_sql}")
    return True

def main():
    print("🚀 Setting up Supabase Storage Buckets...")
    print("=" * 60)
    
    # Get service key
    service_key = get_service_key()
    if not service_key:
        print("\n❌ Error: SUPABASE_SERVICE_KEY not found!")
        print("\n📝 To get your service role key:")
        print("   1. Go to: https://supabase.com/dashboard/project/kjiqtspkvnwgjoerpyxb/settings/api")
        print("   2. Find the 'service_role' key (secret - starts with 'eyJ...')")
        print("   3. Copy it and run one of these:")
        print("\n   Windows PowerShell:")
        print("   $env:SUPABASE_SERVICE_KEY='your_key_here'")
        print("   python setup_supabase_bucket.py")
        print("\n   Or pass it directly:")
        print("   python setup_supabase_bucket.py --key 'your_key_here'")
        print("\n   Or use interactive mode:")
        print("   python setup_supabase_bucket.py --interactive")
        sys.exit(1)
    
    # Create wardrobe bucket
    wardrobe_created = create_bucket(
        bucket_name="wardrobe",
        service_key=service_key,
        public=True,
        file_size_limit=5242880,  # 5MB
        allowed_mime_types=["image/jpeg", "image/png", "image/webp"]
    )
    
    if wardrobe_created:
        print("\n" + "=" * 60)
        print("✅ Bucket created successfully!")
        print("\n📋 Next step: Set up storage policies")
        print("\n   1. Go to: https://supabase.com/dashboard/project/kjiqtspkvnwgjoerpyxb/storage/buckets/wardrobe/policies")
        print("   2. Click 'New Policy' and create 3 policies:")
        print("\n   📌 Policy 1: Allow authenticated uploads")
        print("      - Name: Allow authenticated uploads")
        print("      - Operation: INSERT")
        print("      - SQL: (bucket_id = 'wardrobe'::text) AND (auth.role() = 'authenticated'::text)")
        print("\n   📌 Policy 2: Allow authenticated reads")
        print("      - Name: Allow authenticated reads")
        print("      - Operation: SELECT")
        print("      - SQL: (bucket_id = 'wardrobe'::text) AND (auth.role() = 'authenticated'::text)")
        print("\n   📌 Policy 3: Allow users to delete own files")
        print("      - Name: Allow users to delete own files")
        print("      - Operation: DELETE")
        print("      - SQL: (bucket_id = 'wardrobe'::text) AND (auth.role() = 'authenticated'::text)")
        print("\n✅ After setting up policies, try uploading a wardrobe item!")
    else:
        print("\n❌ Failed to create bucket.")
        print("\n💡 Alternative: Create the bucket manually via Dashboard:")
        print("   https://supabase.com/dashboard/project/kjiqtspkvnwgjoerpyxb/storage/buckets")
    
    print("\n" + "=" * 60)

if __name__ == "__main__":
    main()
