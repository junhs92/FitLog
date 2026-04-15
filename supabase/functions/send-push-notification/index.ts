// send-push-notification Edge Function
// Sends a Firebase Cloud Messaging push notification to a single user.
// Called by NotificationService.sendReportReadyNotification() (and other senders)
// in lib/core/services/notification_service.dart around line 346.
//
// Required environment variables (set in Supabase dashboard → Edge Functions → Secrets):
//   SUPABASE_URL               — injected automatically by the Supabase runtime
//   SUPABASE_SERVICE_ROLE_KEY  — injected automatically by the Supabase runtime
//   FCM_PROJECT_ID             — Firebase project ID  (e.g. "fitlogpro-12345")
//   FCM_SERVICE_ACCOUNT_JSON   — full contents of the Firebase service-account JSON

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface SendPushRequest {
  userId: string
  title: string
  body: string
  data?: Record<string, string>
}

interface FcmTokenRow {
  token: string
  platform: string
}

// Minimal subset of a Google service-account JSON we actually need.
interface ServiceAccountJson {
  client_email: string
  private_key: string
}

// ---------------------------------------------------------------------------
// CORS headers — Flutter uses the Supabase client SDK which does not send
// browser pre-flight requests, but keeping CORS consistent with the other
// Edge Functions prevents surprises if a web client calls this directly.
// ---------------------------------------------------------------------------

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ---------------------------------------------------------------------------
// Google OAuth2 — obtain a short-lived access token for the FCM HTTP v1 API
// using a service-account JSON key (RS256 JWT → token exchange).
// ---------------------------------------------------------------------------

/** Build a base64url-encoded string (no padding). */
function base64url(data: ArrayBuffer): string {
  const bytes = new Uint8Array(data)
  let binary = ''
  for (const b of bytes) binary += String.fromCharCode(b)
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

/** Encode a plain string as base64url. */
function base64urlStr(str: string): string {
  return base64url(new TextEncoder().encode(str).buffer as ArrayBuffer)
}

/**
 * Exchange a service-account key for a short-lived Google OAuth2 access token
 * scoped to Firebase Cloud Messaging.
 */
async function getGoogleAccessToken(serviceAccount: ServiceAccountJson): Promise<string> {
  const now = Math.floor(Date.now() / 1000)

  // JWT header + payload
  const header = base64urlStr(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const payload = base64urlStr(JSON.stringify({
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  }))

  const signingInput = `${header}.${payload}`

  // Import the RSA private key
  const pemBody = serviceAccount.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '')
  const keyData = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    keyData.buffer as ArrayBuffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signingInput),
  )

  const jwt = `${signingInput}.${base64url(signature)}`

  // Token exchange
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }).toString(),
  })

  if (!tokenResponse.ok) {
    const err = await tokenResponse.text()
    throw new Error(`Google OAuth2 token exchange failed: ${err}`)
  }

  const { access_token } = await tokenResponse.json()
  return access_token as string
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

serve(async (req) => {
  // CORS pre-flight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // ------------------------------------------------------------------
    // 1. Validate environment
    // ------------------------------------------------------------------
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    const fcmProjectId = Deno.env.get('FCM_PROJECT_ID')
    const fcmServiceAccountRaw = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')

    if (!supabaseUrl || !supabaseServiceKey) {
      console.error('Missing Supabase environment variables')
      return new Response(
        JSON.stringify({ error: 'Server configuration error: Supabase credentials missing' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    if (!fcmProjectId || !fcmServiceAccountRaw) {
      console.error('Missing FCM environment variables (FCM_PROJECT_ID or FCM_SERVICE_ACCOUNT_JSON)')
      return new Response(
        JSON.stringify({ error: 'Server configuration error: FCM credentials missing' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // ------------------------------------------------------------------
    // 2. Parse and validate request body
    // ------------------------------------------------------------------
    let requestBody: SendPushRequest
    try {
      requestBody = await req.json()
    } catch {
      return new Response(
        JSON.stringify({ error: 'Invalid JSON in request body' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const { userId, title, body: messageBody, data } = requestBody

    if (!userId || typeof userId !== 'string') {
      return new Response(
        JSON.stringify({ error: 'userId is required and must be a string' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }
    if (!title || typeof title !== 'string') {
      return new Response(
        JSON.stringify({ error: 'title is required and must be a string' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }
    if (!messageBody || typeof messageBody !== 'string') {
      return new Response(
        JSON.stringify({ error: 'body is required and must be a string' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // data values must be strings for FCM — coerce if necessary
    const fcmData: Record<string, string> = {}
    if (data && typeof data === 'object') {
      for (const [k, v] of Object.entries(data)) {
        fcmData[k] = String(v)
      }
    }

    // ------------------------------------------------------------------
    // 3. Look up FCM token(s) for the user (service-role bypasses RLS)
    // ------------------------------------------------------------------
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const { data: tokenRows, error: tokenError } = await supabase
      .from('user_fcm_tokens')
      .select('token, platform')
      .eq('user_id', userId)

    if (tokenError) {
      console.error('Failed to query user_fcm_tokens:', tokenError)
      return new Response(
        JSON.stringify({ error: 'Database error while fetching FCM tokens' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Graceful no-op: user has no registered device — not an error
    if (!tokenRows || tokenRows.length === 0) {
      console.warn(`No FCM tokens found for userId=${userId} — skipping push notification`)
      return new Response(
        JSON.stringify({ success: true, skipped: true, reason: 'No FCM tokens registered for this user' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // ------------------------------------------------------------------
    // 4. Obtain a Google OAuth2 access token for FCM HTTP v1
    // ------------------------------------------------------------------
    let serviceAccount: ServiceAccountJson
    try {
      serviceAccount = JSON.parse(fcmServiceAccountRaw) as ServiceAccountJson
    } catch {
      console.error('FCM_SERVICE_ACCOUNT_JSON is not valid JSON')
      return new Response(
        JSON.stringify({ error: 'Server configuration error: invalid FCM service account JSON' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    let accessToken: string
    try {
      accessToken = await getGoogleAccessToken(serviceAccount)
    } catch (err) {
      console.error('Failed to obtain Google access token:', err)
      return new Response(
        JSON.stringify({ error: 'Failed to authenticate with Firebase' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // ------------------------------------------------------------------
    // 5. Send notification to each registered device token
    //    Fan-out: a user may have multiple devices (iOS + Android).
    //    We fire them all and collect results; partial success is treated
    //    as overall success so the caller is not disrupted.
    // ------------------------------------------------------------------
    const fcmEndpoint =
      `https://fcm.googleapis.com/v1/projects/${fcmProjectId}/messages:send`

    const results: Array<{ token: string; platform: string; success: boolean; error?: string }> = []

    for (const row of tokenRows as FcmTokenRow[]) {
      const fcmPayload = {
        message: {
          token: row.token,
          notification: {
            title,
            body: messageBody,
          },
          // data fields are included only when the caller provided them
          ...(Object.keys(fcmData).length > 0 ? { data: fcmData } : {}),
          // Per-platform overrides for better defaults
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
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
        },
      }

      const fcmResponse = await fetch(fcmEndpoint, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(fcmPayload),
      })

      if (fcmResponse.ok) {
        const fcmResult = await fcmResponse.json()
        console.log(`FCM sent to ${row.platform} token (${row.token.slice(0, 12)}...): ${fcmResult.name}`)
        results.push({ token: row.token, platform: row.platform, success: true })
      } else {
        const fcmError = await fcmResponse.json()
        const errorCode = fcmError?.error?.details?.[0]?.errorCode ?? fcmError?.error?.status ?? 'UNKNOWN'
        console.error(`FCM error for ${row.platform} token:`, JSON.stringify(fcmError))

        // UNREGISTERED / INVALID_ARGUMENT with a bad token means the token is
        // stale. Remove it so future invocations skip this device.
        if (errorCode === 'UNREGISTERED' || errorCode === 'INVALID_ARGUMENT') {
          const { error: deleteError } = await supabase
            .from('user_fcm_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('token', row.token)

          if (deleteError) {
            console.error('Failed to remove stale FCM token:', deleteError)
          } else {
            console.log(`Removed stale FCM token for userId=${userId} platform=${row.platform}`)
          }
        }

        results.push({ token: row.token, platform: row.platform, success: false, error: errorCode })
      }
    }

    const successCount = results.filter((r) => r.success).length

    return new Response(
      JSON.stringify({
        success: true,
        sent: successCount,
        total: results.length,
        results,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )

  } catch (error) {
    console.error('Unexpected error in send-push-notification:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
