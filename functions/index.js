const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function: generateOutfitRecommendations
 * 
 * Generates AI-powered outfit recommendations based on:
 * - User onboarding data (fashion style, colors, occasions, etc.)
 * - User's wardrobe items
 * 
 * Input:
 * {
 *   userId: string,
 *   onboardingData: {
 *     fashionStyle: string,
 *     favoriteColors: string,
 *     occasion: string,
 *     budget: string,
 *     shoppingFrequency: string,
 *     styleInspiration: string,
 *     bodyInputs: {
 *       height: number,
 *       gender: string,
 *       bodyType: string
 *     }
 *   },
 *   wardrobeItems: Array<{
 *     id: string,
 *     category: string,
 *     colorTags: string[],
 *     brand: string?
 *   }>
 * }
 * 
 * Output:
 * {
 *   recommendations: Array<{
 *     name: string,
 *     itemIds: string[],
 *     confidence: number (0-1),
 *     reasoning: string
 *   }>
 * }
 */
exports.generateOutfitRecommendations = functions.https.onCall(async (data, context) => {
  // Validate authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to get recommendations'
    );
  }

  // Validate input
  if (!data.userId || !data.onboardingData || !data.wardrobeItems) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields: userId, onboardingData, or wardrobeItems'
    );
  }

  const { userId, onboardingData, wardrobeItems } = data;

  // Validate onboarding data structure
  const requiredOnboardingFields = [
    'fashionStyle',
    'favoriteColors',
    'occasion',
    'budget',
    'shoppingFrequency',
    'styleInspiration',
    'bodyInputs'
  ];

  for (const field of requiredOnboardingFields) {
    if (!onboardingData[field]) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Missing required onboarding field: ${field}`
      );
    }
  }

  try {
    // Mock AI recommendation engine
    // In production, this would call an actual AI service (e.g., OpenAI, custom ML model)
    const recommendations = generateMockRecommendations(onboardingData, wardrobeItems);

    return {
      recommendations: recommendations,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };
  } catch (error) {
    console.error('Error generating recommendations:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to generate recommendations',
      error.message
    );
  }
});

/**
 * Mock AI recommendation engine
 * In production, replace with actual AI/ML service
 */
function generateMockRecommendations(onboardingData, wardrobeItems) {
  const recommendations = [];
  
  if (wardrobeItems.length === 0) {
    return recommendations;
  }

  // Group items by category
  const itemsByCategory = {};
  wardrobeItems.forEach(item => {
    const category = item.category.toLowerCase();
    if (!itemsByCategory[category]) {
      itemsByCategory[category] = [];
    }
    itemsByCategory[category].push(item);
  });

  // Generate recommendations based on fashion style
  const fashionStyle = onboardingData.fashionStyle.toLowerCase();
  const occasion = onboardingData.occasion.toLowerCase();

  // Casual outfit recommendation
  if (itemsByCategory['top'] && itemsByCategory['bottom']) {
    const top = itemsByCategory['top'][0];
    const bottom = itemsByCategory['bottom'][0];
    
    let confidence = 0.8;
    let reasoning = `A ${onboardingData.fashionStyle} look perfect for ${onboardingData.occasion}.`;

    // Adjust confidence based on color matching
    if (onboardingData.favoriteColors && 
        top.colorTags.some(color => 
          onboardingData.favoriteColors.toLowerCase().includes(color.toLowerCase())
        )) {
      confidence = 0.9;
      reasoning += ' Colors match your preferences.';
    }

    recommendations.push({
      name: `${onboardingData.fashionStyle} ${onboardingData.occasion}`,
      itemIds: [top.id, bottom.id],
      confidence: confidence,
      reasoning: reasoning,
    });
  }

  // Complete outfit (top + bottom + shoes)
  if (itemsByCategory['top'] && itemsByCategory['bottom'] && itemsByCategory['shoes']) {
    const top = itemsByCategory['top'][0];
    const bottom = itemsByCategory['bottom'][0];
    const shoes = itemsByCategory['shoes'][0];

    recommendations.push({
      name: 'Complete Outfit',
      itemIds: [top.id, bottom.id, shoes.id],
      confidence: 0.85,
      reasoning: `A well-balanced ${onboardingData.fashionStyle} outfit with all elements. Perfect for ${onboardingData.occasion}.`,
    });
  }

  // Accessories recommendation
  if (itemsByCategory['accessories'] && itemsByCategory['top']) {
    const accessory = itemsByCategory['accessories'][0];
    const top = itemsByCategory['top'][0];

    recommendations.push({
      name: 'Accessorized Look',
      itemIds: [top.id, accessory.id],
      confidence: 0.75,
      reasoning: `Add some flair to your ${onboardingData.fashionStyle} style with this accessory.`,
    });
  }

  // Sort by confidence (highest first)
  recommendations.sort((a, b) => b.confidence - a.confidence);

  // Return top 5 recommendations
  return recommendations.slice(0, 5);
}

