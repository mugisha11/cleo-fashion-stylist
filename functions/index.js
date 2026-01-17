const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');

admin.initializeApp();

// Initialize Supabase client
const supabaseUrl = functions.config().supabase?.url || process.env.SUPABASE_URL;
const supabaseServiceKey = functions.config().supabase?.service_key || process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// OpenWeatherMap API key
const OPENWEATHER_API_KEY = functions.config().openweather?.api_key || process.env.OPENWEATHER_API_KEY;

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

// ============================================
// DAILY RECOMMENDATIONS SCHEDULER
// ============================================

/**
 * Cloud Function: generateDailyRecommendations (Cron Job)
 * 
 * Runs daily at 6:00 AM UTC to generate 3 outfit recommendations
 * for each eligible user based on:
 * - Wardrobe items
 * - Weather conditions
 * - Calendar events
 * - Try-on history
 * - User preferences
 * 
 * Schedule: every day at 06:00 UTC
 */
exports.generateDailyRecommendations = functions.pubsub
  .schedule('0 6 * * *') // Every day at 6:00 AM UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('Daily recommendations scheduler started at', new Date().toISOString());
    
    try {
      // Step 1: Get all eligible users
      const eligibleUsers = await getEligibleUsers();
      console.log(`Found ${eligibleUsers.length} eligible users`);
      
      if (eligibleUsers.length === 0) {
        console.log('No eligible users found. Exiting.');
        return null;
      }
      
      // Step 2: Process each user
      const results = {
        success: 0,
        failed: 0,
        skipped: 0,
        errors: []
      };
      
      for (const userId of eligibleUsers) {
        try {
          const today = new Date();
          const dateKey = today.toISOString().split('T')[0];
          
          // Check if recommendations already exist for today
          const { data: existing } = await supabase
            .from('daily_recommendations')
            .select('id')
            .eq('user_id', userId)
            .eq('recommended_for', dateKey)
            .maybeSingle();
          
          if (existing) {
            console.log(`Recommendations already exist for user ${userId} on ${dateKey}`);
            results.skipped++;
            continue;
          }
          
          // Generate recommendations for this user
          const recommendations = await generateRecommendationsForUser(userId, today);
          results.success++;
          console.log(`Successfully generated recommendations for user ${userId}`);
          
          // Link outfits to calendar events (AI-auto linking)
          await linkOutfitsToCalendar(userId, today, recommendations);
          
        } catch (error) {
          console.error(`Error processing user ${userId}:`, error);
          results.failed++;
          results.errors.push({
            userId,
            error: error.message
          });
          
          // Save error to database
          try {
            const dateKey = new Date().toISOString().split('T')[0];
            await supabase.from('daily_recommendations').insert({
              user_id: userId,
              recommended_for: dateKey,
              recommendations: [],
              status: 'failed',
              error_message: error.message,
            });
          } catch (dbError) {
            console.error('Failed to save error to database:', dbError);
          }
        }
      }
      
      console.log('Daily recommendations scheduler completed:', results);
      return results;
      
    } catch (error) {
      console.error('Fatal error in daily recommendations scheduler:', error);
      throw error;
    }
  });

/**
 * Get all eligible users for daily recommendations
 */
async function getEligibleUsers() {
  try {
    const { data: wardrobeItems, error } = await supabase
      .from('wardrobe_items')
      .select('user_id')
      .not('user_id', 'is', null);
    
    if (error) {
      console.error('Error fetching wardrobe items:', error);
      return [];
    }
    
    const userIds = [...new Set(wardrobeItems.map(item => item.user_id))];
    
    const eligibleUsers = [];
    for (const userId of userIds) {
      const { count } = await supabase
        .from('wardrobe_items')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', userId);
      
      if (count && count >= 1) {
        eligibleUsers.push(userId);
      }
    }
    
    return eligibleUsers;
  } catch (error) {
    console.error('Error getting eligible users:', error);
    return [];
  }
}

/**
 * Generate recommendations for a single user
 */
async function generateRecommendationsForUser(userId, date) {
  const dateKey = date.toISOString().split('T')[0];
  
  try {
    // Step 1: Load user context
    const context = await loadUserContext(userId, date);
    
    // Step 2: Validate wardrobe
    if (context.wardrobe.length < 1) {
      throw new Error('User has insufficient wardrobe items');
    }
    
    // Step 3: Call Supabase Edge Function
    const { data, error } = await supabase.functions.invoke('generate-daily-recommendations', {
      body: {
        user_id: userId,
        date: dateKey,
      }
    });
    
    if (error) {
      throw new Error(`Edge function error: ${error.message}`);
    }
    
    if (!data || !data.recommendations || data.recommendations.length !== 3) {
      throw new Error(`Invalid recommendations: expected 3, got ${data?.recommendations?.length || 0}`);
    }
    
    // Step 4: Validate recommendations
    const validatedRecommendations = validateRecommendations(data.recommendations, context.wardrobe);
    
    if (validatedRecommendations.length !== 3) {
      throw new Error(`Validation failed: expected 3 valid recommendations, got ${validatedRecommendations.length}`);
    }
    
    // Step 5: Save to database
    const { error: insertError } = await supabase
      .from('daily_recommendations')
      .insert({
        user_id: userId,
        recommended_for: dateKey,
        recommendations: validatedRecommendations,
        weather_data: context.weather,
        calendar_context: context.calendar,
        tryon_history_count: context.tryOns.length,
        status: 'generated',
      });
    
    if (insertError) {
      throw new Error(`Database insert error: ${insertError.message}`);
    }
    
    // Step 6: Send notification
    await sendRecommendationNotification(userId, validatedRecommendations);
    
    return validatedRecommendations;
    
  } catch (error) {
    console.error(`Error generating recommendations for user ${userId}:`, error);
    throw error;
  }
}

/**
 * Load user context (wardrobe, calendar, weather, try-ons)
 */
async function loadUserContext(userId, date) {
  const dateKey = date.toISOString().split('T')[0];
  const nextDay = new Date(date);
  nextDay.setDate(nextDay.getDate() + 1);
  const nextDayKey = nextDay.toISOString().split('T')[0];
  
  const { data: wardrobe } = await supabase
    .from('wardrobe_items')
    .select('*')
    .eq('user_id', userId);
  
  const { data: calendar } = await supabase
    .from('calendar_days')
    .select('*')
    .eq('user_id', userId)
    .gte('date', dateKey)
    .lt('date', nextDayKey);
  
  const sevenDaysAgo = new Date(date);
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
  
  const { data: tryOns } = await supabase
    .from('tryon_sessions')
    .select('*')
    .eq('user_id', userId)
    .gte('created_at', sevenDaysAgo.toISOString())
    .order('created_at', { ascending: false })
    .limit(20);
  
  const { data: preferences } = await supabase
    .from('user_preferences')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle();
  
  const weather = await getWeatherData(userId, date);
  
  return {
    wardrobe: wardrobe || [],
    calendar: calendar || [],
    tryOns: tryOns || [],
    preferences: preferences || null,
    weather: weather,
  };
}

/**
 * Get weather data for user location
 */
async function getWeatherData(userId, date) {
  try {
    const { data: preferences } = await supabase
      .from('user_preferences')
      .select('preferences')
      .eq('user_id', userId)
      .maybeSingle();
    
    const location = preferences?.preferences?.location || 'New York,US';
    const [city, country] = location.split(',');
    
    if (!OPENWEATHER_API_KEY) {
      return {
        temperature: 20,
        condition: 'clear',
        description: 'Clear sky',
        humidity: 60,
        windSpeed: 10,
      };
    }
    
    const url = `https://api.openweathermap.org/data/2.5/weather?q=${city},${country}&appid=${OPENWEATHER_API_KEY}&units=metric`;
    const response = await fetch(url);
    
    if (!response.ok) {
      throw new Error(`Weather API error: ${response.statusText}`);
    }
    
    const data = await response.json();
    
    return {
      temperature: data.main.temp,
      condition: data.weather[0].main.toLowerCase(),
      description: data.weather[0].description,
      humidity: data.main.humidity,
      windSpeed: data.wind?.speed || 0,
      location: `${city}, ${country}`,
    };
    
  } catch (error) {
    console.error('Error fetching weather:', error);
    return {
      temperature: 20,
      condition: 'clear',
      description: 'Clear sky',
      humidity: 60,
      windSpeed: 10,
    };
  }
}

/**
 * Validate recommendations before saving
 */
function validateRecommendations(recommendations, wardrobe) {
  const valid = [];
  const wardrobeItemIds = new Set(wardrobe.map(item => item.id));
  
  for (const rec of recommendations) {
    if (!rec.outfit_id || !rec.title || !rec.reasoning || !rec.outfit_item_ids) {
      console.warn('Invalid recommendation: missing required fields', rec);
      continue;
    }
    
    if (typeof rec.confidence !== 'number' || rec.confidence < 0 || rec.confidence > 1) {
      console.warn('Invalid recommendation: invalid confidence score', rec);
      continue;
    }
    
    const allItemsExist = rec.outfit_item_ids.every(itemId => wardrobeItemIds.has(itemId));
    if (!allItemsExist) {
      console.warn('Invalid recommendation: contains non-existent items', rec);
      continue;
    }
    
    valid.push(rec);
  }
  
  return valid;
}

// ============================================
// SMART NOTIFICATION SYSTEM
// ============================================

/**
 * Send push notification to user about new recommendations
 * Uses smart notification decision engine to prevent spam
 */
async function sendRecommendationNotification(userId, recommendations) {
  try {
    // Step 1: Check notification decision engine
    const shouldSend = await shouldSendNotification(userId, 'daily_outfit', {
      recommendationsCount: recommendations.length,
      hasTryOnImages: recommendations.some(r => r.tryon_image_url),
    });
    
    if (!shouldSend) {
      console.log(`Notification decision engine blocked notification for user ${userId}`);
      return;
    }
    
    // Step 2: Get user's FCM token from Firestore
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;
    
    if (!fcmToken) {
      console.log(`No FCM token found for user ${userId}, skipping notification`);
      return;
    }
    
    // Step 3: Create notification record in Supabase
    const notificationId = await createNotificationRecord(userId, {
      type: 'daily_outfit',
      title: '✨ Your 3 outfits for today are ready',
      body: `Perfectly matched for your plans — see your AI-styled looks!`,
      payload: {
        deepLink: 'dashboard',
        screen: 'daily_recommendations',
        date: new Date().toISOString().split('T')[0],
        recommendationsCount: recommendations.length,
      },
      contentValueScore: calculateContentValueScore(recommendations),
    });
    
    // Step 4: Send FCM push notification
    const message = {
      notification: {
        title: '✨ Your 3 outfits for today are ready',
        body: `Perfectly matched for your plans — see your AI-styled looks!`,
      },
      data: {
        type: 'daily_outfit',
        notificationId: notificationId,
        deepLink: 'dashboard',
        screen: 'daily_recommendations',
        date: new Date().toISOString().split('T')[0],
      },
      token: fcmToken,
      android: {
        priority: 'high',
        notification: {
          channelId: 'daily_outfits',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };
    
    const fcmResponse = await admin.messaging().send(message);
    console.log(`FCM notification sent to user ${userId}:`, fcmResponse);
    
    // Step 5: Update notification record and delivery log
    await supabase
      .from('notifications')
      .update({ 
        is_sent: true,
        sent_at: new Date().toISOString(),
      })
      .eq('id', notificationId);
    
    await supabase
      .from('notification_delivery_log')
      .insert({
        notification_id: notificationId,
        user_id: userId,
        delivery_method: 'fcm',
        delivery_status: 'sent',
        fcm_token: fcmToken,
        delivered_at: new Date().toISOString(),
      });
    
    // Step 6: Update daily_recommendations notified_at timestamp
    const dateKey = new Date().toISOString().split('T')[0];
    await supabase
      .from('daily_recommendations')
      .update({ notified_at: new Date().toISOString(), status: 'notified' })
      .eq('user_id', userId)
      .eq('recommended_for', dateKey);
    
  } catch (error) {
    console.error(`Error sending notification to user ${userId}:`, error);
  }
}

/**
 * Smart Notification Decision Engine
 */
async function shouldSendNotification(userId, notificationType, context = {}) {
  try {
    const { data: preferences } = await supabase
      .from('user_notification_preferences')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle();
    
    if (!preferences || !preferences.notifications_enabled) {
      return false;
    }
    
    const typeEnabled = preferences[`${notificationType}_enabled`] !== false;
    if (!typeEnabled) {
      return false;
    }
    
    const sameTypeSentToday = await checkSameTypeSentToday(userId, notificationType);
    if (sameTypeSentToday) {
      return false;
    }
    
    const contentValueScore = context.contentValueScore || calculateContentValueScore(context);
    if (contentValueScore < 0.6) {
      return false;
    }
    
    if (isQuietHours(preferences)) {
      return false;
    }
    
    return true;
  } catch (error) {
    console.error(`Error in notification decision engine:`, error);
    return true; // Fail open
  }
}

async function checkSameTypeSentToday(userId, notificationType) {
  try {
    const { data } = await supabase
      .from('notifications')
      .select('id')
      .eq('user_id', userId)
      .eq('type', notificationType)
      .eq('is_sent', true)
      .gte('created_at', new Date().toISOString().split('T')[0])
      .limit(1);
    
    return data && data.length > 0;
  } catch (error) {
    return false;
  }
}

function calculateContentValueScore(context) {
  let score = 0.5;
  if (context.recommendationsCount >= 3) score += 0.2;
  if (context.hasTryOnImages) score += 0.15;
  if (context.weatherMatch) score += 0.1;
  if (context.calendarMatch) score += 0.05;
  return Math.min(1.0, score);
}

function isQuietHours(preferences) {
  if (!preferences || !preferences.quiet_hours_start || !preferences.quiet_hours_end) {
    return false;
  }
  
  const now = new Date();
  const currentTime = now.getHours() * 60 + now.getMinutes();
  const startTime = parseTime(preferences.quiet_hours_start);
  const endTime = parseTime(preferences.quiet_hours_end);
  
  if (startTime > endTime) {
    return currentTime >= startTime || currentTime <= endTime;
  } else {
    return currentTime >= startTime && currentTime <= endTime;
  }
}

function parseTime(timeString) {
  const [hours, minutes] = timeString.split(':').map(Number);
  return hours * 60 + minutes;
}

async function createNotificationRecord(userId, notificationData) {
  try {
    const { data, error } = await supabase
      .from('notifications')
      .insert({
        user_id: userId,
        type: notificationData.type,
        title: notificationData.title,
        body: notificationData.body,
        payload: notificationData.payload || {},
        content_value_score: notificationData.contentValueScore || 0.8,
        same_type_sent_today: await checkSameTypeSentToday(userId, notificationData.type),
      })
      .select('id')
      .single();
    
    if (error) throw error;
    return data.id;
  } catch (error) {
    console.error('Error creating notification record:', error);
    throw error;
  }
}

// ============================================
// CALENDAR ↔ OUTFIT LINKING
// ============================================

/**
 * Link outfits to calendar events (AI-auto linking)
 */
async function linkOutfitsToCalendar(userId, date, recommendations) {
  try {
    const dateKey = date.toISOString().split('T')[0];
    
    const { data: calendarEvents } = await supabase
      .from('calendar_days')
      .select('*')
      .eq('user_id', userId)
      .eq('date', dateKey);
    
    if (!calendarEvents || calendarEvents.length === 0) {
      return;
    }
    
    for (const event of calendarEvents) {
      if (event.linked_outfit_id) {
        continue;
      }
      
      const bestOutfit = findBestOutfitForEvent(event, recommendations);
      
      if (bestOutfit) {
        await supabase
          .from('calendar_days')
          .update({
            linked_outfit_id: bestOutfit.outfit_id,
            linked_outfit_name: bestOutfit.title,
            linked_outfit_image_url: bestOutfit.tryon_image_url,
            outfit_linking_method: 'ai_auto',
            outfit_linked_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          })
          .eq('id', event.id);
        
        // Log linking history
        await supabase
          .from('outfit_linking_history')
          .insert({
            user_id: userId,
            calendar_event_id: event.id,
            outfit_id: bestOutfit.outfit_id,
            linking_method: 'ai_auto',
            confidence_score: bestOutfit.confidence,
          });
        
        await checkAndSendEventReminder(userId, event, bestOutfit);
      }
    }
  } catch (error) {
    console.error(`Error linking outfits to calendar:`, error);
  }
}

function findBestOutfitForEvent(event, recommendations) {
  if (!recommendations || recommendations.length === 0) {
    return null;
  }
  
  const eventType = (event.event_type || 'casual').toLowerCase();
  
  const scored = recommendations.map(rec => {
    let score = rec.confidence || 0.5;
    if (rec.event_match && rec.event_match.toLowerCase() === eventType) {
      score += 0.3;
    }
    if (eventType === 'formal' && rec.confidence > 0.8) {
      score += 0.2;
    }
    if (rec.tryon_image_url) {
      score += 0.1;
    }
    return { ...rec, matchScore: score };
  });
  
  scored.sort((a, b) => b.matchScore - a.matchScore);
  return scored[0];
}

async function checkAndSendEventReminder(userId, event, outfit) {
  try {
    let eventTime = null;
    if (event.start_time) {
      eventTime = new Date(event.start_time);
    } else if (event.date) {
      eventTime = new Date(event.date);
      eventTime.setHours(9, 0, 0, 0);
    } else {
      return;
    }
    
    const now = new Date();
    const hoursUntilEvent = (eventTime - now) / (1000 * 60 * 60);
    
    if (hoursUntilEvent >= 1 && hoursUntilEvent <= 3) {
      const shouldSend = await shouldSendNotification(userId, 'event_outfit', {
        eventName: event.event_name || 'Event',
        hasOutfit: !!outfit,
        hoursUntilEvent: hoursUntilEvent,
      });
      
      if (shouldSend) {
        await sendEventReminderNotification(userId, event, outfit);
      }
    }
  } catch (error) {
    console.error(`Error checking event reminder:`, error);
  }
}

async function sendEventReminderNotification(userId, event, outfit) {
  try {
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;
    
    if (!fcmToken) return;
    
    const eventName = event.event_name || 'Your event';
    const message = {
      notification: {
        title: `👔 Your outfit for '${eventName}' is ready`,
        body: `Want to review or try it on?`,
      },
      data: {
        type: 'event_outfit',
        deepLink: 'calendar',
        screen: 'event_detail',
        eventId: event.id,
        outfitId: outfit.outfit_id,
      },
      token: fcmToken,
    };
    
    await admin.messaging().send(message);
    
    await createNotificationRecord(userId, {
      type: 'event_outfit',
      title: message.notification.title,
      body: message.notification.body,
      payload: message.data,
      contentValueScore: 0.85,
    });
  } catch (error) {
    console.error(`Error sending event reminder:`, error);
  }
}
