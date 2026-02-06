import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const imageUrl = url.searchParams.get('url')

    if (!imageUrl) {
      return new Response(
        JSON.stringify({ error: 'Missing url parameter' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Only allow exercisedb.dev CDN and video CDN for security
    const allowedDomains = [
      'https://cdn.exercisedb.dev/',
      'https://v2.exercisedb.io/',
    ]
    const isAllowed = allowedDomains.some(domain => imageUrl.startsWith(domain))

    if (!isAllowed) {
      return new Response(
        JSON.stringify({ error: 'Invalid media source' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Fetch the media from the CDN (images or videos)
    const response = await fetch(imageUrl)

    if (!response.ok) {
      return new Response(
        JSON.stringify({ error: 'Failed to fetch media' }),
        { status: response.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const mediaData = await response.arrayBuffer()
    const contentType = response.headers.get('Content-Type') || 'application/octet-stream'

    return new Response(mediaData, {
      headers: {
        ...corsHeaders,
        'Content-Type': contentType,
        'Cache-Control': 'public, max-age=86400', // Cache for 24 hours
      }
    })
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
