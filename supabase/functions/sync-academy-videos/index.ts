// Sync Academy Videos Edge Function
// Fetches latest videos from YouTube RSS feeds (no API key needed)
// and upserts into academy_videos table.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface ChannelRow {
  channel_id: string;
  channel_name: string;
  channel_name_ko: string | null;
  category: string;
}

interface RssVideoEntry {
  videoId: string;
  title: string;
  published: string;
  thumbnailUrl: string;
  description: string;
  viewCount: number;
}

/** Extract text content between XML tags */
function extractTag(xml: string, tag: string): string {
  const match = xml.match(new RegExp(`<${tag}[^>]*>([\\s\\S]*?)</${tag}>`));
  return match ? match[1].trim() : '';
}

/** Extract attribute value from an XML tag */
function extractAttr(xml: string, tag: string, attr: string): string {
  const match = xml.match(new RegExp(`<${tag}[^>]*${attr}="([^"]*)"[^>]*/?>`, 's'));
  return match ? match[1] : '';
}

/** Decode common HTML entities */
function decodeEntities(text: string): string {
  return text
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'");
}

/** Parse YouTube RSS feed XML into video entries */
function parseRssFeed(xml: string): RssVideoEntry[] {
  const entries: RssVideoEntry[] = [];

  // Split on <entry> tags
  const entryBlocks = xml.split('<entry>').slice(1); // skip preamble before first <entry>

  for (const block of entryBlocks) {
    const entryXml = block.split('</entry>')[0];

    const videoId = extractTag(entryXml, 'yt:videoId');
    const title = decodeEntities(extractTag(entryXml, 'title'));
    const published = extractTag(entryXml, 'published');

    // media:thumbnail url attribute
    const thumbnailUrl = extractAttr(entryXml, 'media:thumbnail', 'url');

    // media:description
    const description = decodeEntities(extractTag(entryXml, 'media:description')).substring(0, 500);

    // media:statistics views attribute
    const viewsStr = extractAttr(entryXml, 'media:statistics', 'views');
    const viewCount = viewsStr ? parseInt(viewsStr, 10) : 0;

    if (videoId && title && published) {
      entries.push({
        videoId,
        title,
        published,
        thumbnailUrl: thumbnailUrl || `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`,
        description,
        viewCount: isNaN(viewCount) ? 0 : viewCount,
      });
    }
  }

  return entries;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Create service_role client for full DB access
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    // 1. Read active channels
    const { data: channels, error: channelsError } = await supabaseClient
      .from('academy_channels')
      .select('channel_id, channel_name, channel_name_ko, category')
      .eq('is_active', true);

    if (channelsError) throw channelsError;
    if (!channels || channels.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No active channels found' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const typedChannels = channels as ChannelRow[];
    let totalUpserted = 0;

    // 2. For each channel, fetch RSS feed
    for (const channel of typedChannels) {
      try {
        const rssUrl = `https://www.youtube.com/feeds/videos.xml?channel_id=${channel.channel_id}`;
        const rssRes = await fetch(rssUrl);

        if (!rssRes.ok) {
          console.error(`RSS fetch failed for ${channel.channel_id}: ${rssRes.status}`);
          continue;
        }

        const rssXml = await rssRes.text();
        const entries = parseRssFeed(rssXml);

        if (entries.length === 0) continue;

        // 3. Build upsert rows
        const rows = entries.map((entry) => ({
          video_id: entry.videoId,
          channel_id: channel.channel_id,
          title: entry.title,
          description: entry.description || null,
          thumbnail_url: entry.thumbnailUrl,
          category: channel.category,
          published_at: entry.published,
          view_count: entry.viewCount,
          duration: null, // RSS feeds don't provide duration
          updated_at: new Date().toISOString(),
        }));

        // 4. Upsert into academy_videos
        const { error: upsertError } = await supabaseClient
          .from('academy_videos')
          .upsert(rows, { onConflict: 'video_id' });

        if (upsertError) {
          console.error(`Upsert error for ${channel.channel_id}:`, upsertError);
        } else {
          totalUpserted += rows.length;
        }
      } catch (channelErr) {
        console.error(`Error processing channel ${channel.channel_id}:`, channelErr);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        channelsProcessed: typedChannels.length,
        videosUpserted: totalUpserted,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (error) {
    console.error('sync-academy-videos error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  }
});
