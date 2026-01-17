#!/usr/bin/env python3
"""
Script to create Supabase storage policies for the wardrobe bucket.
"""

import os
import sys
import requests
import argparse

# Fix Windows encoding
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

SUPABASE_URL = "https://kjiqtspkvnwgjoerpyxb.supabase.co"

def create_policy(service_key: str, policy_name: str, operation: str, policy_sql: str) -> bool:
    """Create a storage policy using Supabase REST API."""
    url = f"{SUPABASE_URL}/rest/v1/rpc/exec_sql"
    headers = {
        "Authorization": f"Bearer {service_key}",
        "Content-Type": "application/json",
        "apikey": service_key,
        "Prefer": "return=minimal"
    }
    
    # SQL to create the policy
    sql = f"""
    CREATE POLICY IF NOT EXISTS "{policy_name}"
    ON storage.objects
    FOR {operation}
    TO authenticated
    USING ({policy_sql});
    """
    
    payload = {"query": sql}
    
    try:
        print(f"Creating policy: {policy_name} ({operation})...")
        response = requests.post(url, json=payload, headers=headers, timeout=10)
        
        if response.status_code in [200, 201, 204]:
            print(f"  [OK] Policy '{policy_name}' created successfully")
            return True
        else:
            print(f"  [ERROR] Failed: HTTP {response.status_code}")
            print(f"  Response: {response.text}")
            return False
    except Exception as e:
        print(f"  [ERROR] Exception: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Create Supabase storage policies')
    parser.add_argument('--key', help='Supabase service role key', required=True)
    args = parser.parse_args()
    
    print("Setting up storage policies for 'wardrobe' bucket...")
    print("=" * 60)
    
    policies = [
        {
            "name": "Allow authenticated uploads",
            "operation": "INSERT",
            "sql": "(bucket_id = 'wardrobe'::text) AND (auth.role() = 'authenticated'::text)"
        },
        {
            "name": "Allow authenticated reads",
            "operation": "SELECT",
            "sql": "(bucket_id = 'wardrobe'::text) AND (auth.role() = 'authenticated'::text)"
        },
        {
            "name": "Allow users to delete own files",
            "operation": "DELETE",
            "sql": "(bucket_id = 'wardrobe'::text) AND (auth.role() = 'authenticated'::text)"
        }
    ]
    
    success_count = 0
    for policy in policies:
        if create_policy(args.key, policy["name"], policy["operation"], policy["sql"]):
            success_count += 1
        print()
    
    print("=" * 60)
    if success_count == len(policies):
        print("All policies created successfully!")
    else:
        print(f"Created {success_count}/{len(policies)} policies.")
        print("You may need to create the remaining policies via Supabase Dashboard.")

if __name__ == "__main__":
    main()
