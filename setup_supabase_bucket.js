/**
 * Automated script to create Supabase storage buckets.
 * This script will create the 'wardrobe' bucket in Supabase.
 * 
 * Usage:
 *   node setup_supabase_bucket.js --key "your_service_role_key"
 *   node setup_supabase_bucket.js --interactive
 *   SUPABASE_SERVICE_KEY="your_key" node setup_supabase_bucket.js
 */

const { createClient } = require('@supabase/supabase-js');
const readline = require('readline');

// Supabase configuration
const SUPABASE_URL = 'https://kjiqtspkvnwgjoerpyxb.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_A4DglmUBJorcilVMduJA4Q_ZTguPkKI';

// Get service role key from command line or environment
function getServiceKey() {
  const args = process.argv.slice(2);
  
  // Check for --key argument
  const keyIndex = args.indexOf('--key');
  if (keyIndex !== -1 && args[keyIndex + 1]) {
    return args[keyIndex + 1];
  }
  
  // Check for --interactive flag
  if (args.includes('--interactive')) {
    return null; // Will prompt
  }
  
  // Check environment variable
  return process.env.SUPABASE_SERVICE_KEY || '';
}

// Prompt for service key
function promptForKey() {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
    
    rl.question('Enter your Supabase service role key: ', (answer) => {
      rl.close();
      resolve(answer);
    });
  });
}

// Create bucket using Supabase client
async function createBucket(serviceKey, bucketName, options = {}) {
  try {
    // Create Supabase client with service role key (admin access)
    const supabase = createClient(SUPABASE_URL, serviceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    });

    console.log(`📦 Creating bucket '${bucketName}'...`);

    // Use the storage API to create bucket
    // Note: The Supabase JS client doesn't have a direct method for creating buckets
    // So we'll use the REST API directly
    const response = await fetch(`${SUPABASE_URL}/storage/v1/bucket`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${serviceKey}`,
        'Content-Type': 'application/json',
        'apikey': serviceKey
      },
      body: JSON.stringify({
        name: bucketName,
        public: options.public !== false,
        file_size_limit: options.fileSizeLimit || 5242880,
        allowed_mime_types: options.allowedMimeTypes || []
      })
    });

    if (response.ok) {
      console.log(`✅ Successfully created bucket: ${bucketName}`);
      return true;
    } else if (response.status === 409) {
      console.log(`ℹ️  Bucket '${bucketName}' already exists (that's okay!)`);
      return true;
    } else {
      const errorData = await response.json().catch(() => ({ message: response.statusText }));
      console.log(`❌ Failed to create bucket: HTTP ${response.status}`);
      console.log(`   Error: ${errorData.message || response.statusText}`);
      return false;
    }
  } catch (error) {
    console.log(`❌ Error creating bucket: ${error.message}`);
    return false;
  }
}

// Main function
async function main() {
  console.log('🚀 Setting up Supabase Storage Buckets...');
  console.log('='.repeat(60));

  // Get service key
  let serviceKey = getServiceKey();
  
  if (!serviceKey) {
    console.log('\n📝 To get your service role key:');
    console.log('   1. Go to: https://supabase.com/dashboard/project/kjiqtspkvnwgjoerpyxb/settings/api');
    console.log('   2. Find the "service_role" key (secret - starts with "eyJ...")');
    console.log('   3. Copy it\n');
    
    const args = process.argv.slice(2);
    if (args.includes('--interactive')) {
      serviceKey = await promptForKey();
    } else {
      console.log('❌ Error: SUPABASE_SERVICE_KEY not found!');
      console.log('\n💡 Run with one of these options:');
      console.log('   node setup_supabase_bucket.js --key "your_key_here"');
      console.log('   node setup_supabase_bucket.js --interactive');
      console.log('   SUPABASE_SERVICE_KEY="your_key" node setup_supabase_bucket.js');
      process.exit(1);
    }
  }

  if (!serviceKey) {
    console.log('❌ No service key provided');
    process.exit(1);
  }

  // Create wardrobe bucket
  const success = await createBucket(serviceKey, 'wardrobe', {
    public: true,
    fileSizeLimit: 5242880, // 5MB
    allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp']
  });

  if (success) {
    console.log('\n' + '='.repeat(60));
    console.log('✅ Bucket created successfully!');
    console.log('\n📋 Next step: Set up storage policies');
    console.log('\n   1. Go to: https://supabase.com/dashboard/project/kjiqtspkvnwgjoerpyxb/storage/buckets/wardrobe/policies');
    console.log('   2. Click "New Policy" and create 3 policies:');
    console.log('\n   📌 Policy 1: Allow authenticated uploads');
    console.log('      - Name: Allow authenticated uploads');
    console.log('      - Operation: INSERT');
    console.log('      - SQL: (bucket_id = \'wardrobe\'::text) AND (auth.role() = \'authenticated\'::text)');
    console.log('\n   📌 Policy 2: Allow authenticated reads');
    console.log('      - Name: Allow authenticated reads');
    console.log('      - Operation: SELECT');
    console.log('      - SQL: (bucket_id = \'wardrobe\'::text) AND (auth.role() = \'authenticated\'::text)');
    console.log('\n   📌 Policy 3: Allow users to delete own files');
    console.log('      - Name: Allow users to delete own files');
    console.log('      - Operation: DELETE');
    console.log('      - SQL: (bucket_id = \'wardrobe\'::text) AND (auth.role() = \'authenticated\'::text)');
    console.log('\n✅ After setting up policies, try uploading a wardrobe item!');
  } else {
    console.log('\n❌ Failed to create bucket.');
    console.log('\n💡 Alternative: Create the bucket manually via Dashboard:');
    console.log('   https://supabase.com/dashboard/project/kjiqtspkvnwgjoerpyxb/storage/buckets');
  }

  console.log('\n' + '='.repeat(60));
}

// Run the script
main().catch(console.error);
