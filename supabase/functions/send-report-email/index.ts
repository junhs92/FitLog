// send-report-email Edge Function
// Sends workout reports via email using Resend API

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface SendEmailRequest {
  sessionId: string
  recipientEmail?: string
  includeHighlights?: boolean
  trainerNotes?: string
}

interface Highlight {
  type: string
  title: string
  description: string
}

interface SessionStats {
  totalSets: number
  totalReps: number
  totalVolume: number
  exerciseCount: number
  avgRpe?: number
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const resendApiKey = Deno.env.get('RESEND_API_KEY')
    if (!resendApiKey) {
      return new Response(
        JSON.stringify({ error: 'Resend API key not configured' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    const {
      sessionId,
      recipientEmail,
      includeHighlights = true,
      trainerNotes,
    }: SendEmailRequest = await req.json()

    if (!sessionId) {
      return new Response(
        JSON.stringify({ error: 'Session ID is required' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Fetch session data
    const { data: session, error: sessionError } = await supabase
      .from('sessions')
      .select(`
        *,
        client:accounts!sessions_client_id_fkey(full_name, email),
        trainer:accounts!sessions_trainer_id_fkey(full_name),
        session_exercises(
          *,
          exercise:exercises(*),
          exercise_sets(*)
        )
      `)
      .eq('id', sessionId)
      .single()

    if (sessionError || !session) {
      return new Response(
        JSON.stringify({ error: 'Session not found' }),
        {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Determine recipient email
    const toEmail = recipientEmail || session.client?.email
    if (!toEmail) {
      return new Response(
        JSON.stringify({ error: 'No recipient email available' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Fetch PDF URL if available
    const { data: reportData } = await supabase
      .from('session_reports')
      .select('pdf_url')
      .eq('session_id', sessionId)
      .single()

    // Calculate session stats
    const stats = calculateSessionStats(session.session_exercises)
    const highlights = extractHighlights(session.session_exercises)

    // Format session date
    const sessionDate = new Date(session.started_at).toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    })

    // Build email HTML
    const emailHtml = buildEmailHtml({
      clientName: session.client?.full_name || 'Client',
      trainerName: session.trainer?.full_name || 'Trainer',
      sessionDate,
      stats,
      highlights: includeHighlights ? highlights : [],
      trainerNotes,
      pdfUrl: reportData?.pdf_url,
      exercises: session.session_exercises,
    })

    // Send email via Resend
    const emailResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'FitLog Pro <noreply@fitlogpro.app>',
        to: [toEmail],
        subject: `Workout Report - ${sessionDate}`,
        html: emailHtml,
      }),
    })

    if (!emailResponse.ok) {
      const errorData = await emailResponse.json()
      console.error('Resend error:', errorData)
      return new Response(
        JSON.stringify({ error: 'Failed to send email' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    const emailResult = await emailResponse.json()

    // Update session_reports with email sent status
    await supabase
      .from('session_reports')
      .upsert({
        session_id: sessionId,
        email_sent_at: new Date().toISOString(),
        email_recipient: toEmail,
      })

    return new Response(
      JSON.stringify({
        success: true,
        emailId: emailResult.id,
        recipient: toEmail,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error sending email:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

function calculateSessionStats(sessionExercises: any[]): SessionStats {
  let totalSets = 0
  let totalReps = 0
  let totalVolume = 0
  let rpeSum = 0
  let rpeCount = 0

  for (const exercise of sessionExercises) {
    for (const set of exercise.exercise_sets || []) {
      totalSets++
      totalReps += set.reps
      totalVolume += set.weight * set.reps

      if (set.rpe) {
        rpeSum += set.rpe
        rpeCount++
      }
    }
  }

  return {
    totalSets,
    totalReps,
    totalVolume,
    exerciseCount: sessionExercises.length,
    avgRpe: rpeCount > 0 ? rpeSum / rpeCount : undefined,
  }
}

function extractHighlights(sessionExercises: any[]): Highlight[] {
  const highlights: Highlight[] = []

  for (const exercise of sessionExercises) {
    for (const set of exercise.exercise_sets || []) {
      if (set.is_pr) {
        highlights.push({
          type: 'pr',
          title: `New PR: ${exercise.exercise?.name || 'Exercise'}`,
          description: `${set.weight}kg x ${set.reps} reps`,
        })
      }
    }
  }

  return highlights
}

interface EmailData {
  clientName: string
  trainerName: string
  sessionDate: string
  stats: SessionStats
  highlights: Highlight[]
  trainerNotes?: string
  pdfUrl?: string
  exercises: any[]
}

function buildEmailHtml(data: EmailData): string {
  const highlightsHtml = data.highlights.length > 0
    ? `
      <div style="background: #f0fdf4; border-left: 4px solid #22c55e; padding: 16px; margin: 20px 0; border-radius: 4px;">
        <h3 style="margin: 0 0 12px 0; color: #166534;">🎉 Session Highlights</h3>
        ${data.highlights.map(h => `
          <div style="margin-bottom: 8px;">
            <strong>${h.title}</strong><br/>
            <span style="color: #6b7280;">${h.description}</span>
          </div>
        `).join('')}
      </div>
    `
    : ''

  const exercisesHtml = data.exercises.map(ex => {
    const setsHtml = (ex.exercise_sets || []).map((set: any) => `
      <tr>
        <td style="padding: 8px; border-bottom: 1px solid #e5e7eb;">Set ${set.set_number}</td>
        <td style="padding: 8px; border-bottom: 1px solid #e5e7eb;">${set.weight} kg</td>
        <td style="padding: 8px; border-bottom: 1px solid #e5e7eb;">${set.reps}</td>
        <td style="padding: 8px; border-bottom: 1px solid #e5e7eb;">${set.rpe || '-'}</td>
        <td style="padding: 8px; border-bottom: 1px solid #e5e7eb;">${set.is_pr ? '🏆 PR!' : ''}</td>
      </tr>
    `).join('')

    return `
      <div style="margin: 20px 0; background: #f9fafb; border-radius: 8px; padding: 16px;">
        <h4 style="margin: 0 0 12px 0; color: #374151;">${ex.exercise?.name || 'Exercise'}</h4>
        <p style="margin: 0 0 12px 0; color: #6b7280; font-size: 14px;">${ex.exercise?.muscle_group || 'General'}</p>
        <table style="width: 100%; border-collapse: collapse;">
          <thead>
            <tr style="background: #e5e7eb;">
              <th style="padding: 8px; text-align: left; font-size: 12px;">Set</th>
              <th style="padding: 8px; text-align: left; font-size: 12px;">Weight</th>
              <th style="padding: 8px; text-align: left; font-size: 12px;">Reps</th>
              <th style="padding: 8px; text-align: left; font-size: 12px;">RPE</th>
              <th style="padding: 8px; text-align: left; font-size: 12px;"></th>
            </tr>
          </thead>
          <tbody>
            ${setsHtml}
          </tbody>
        </table>
      </div>
    `
  }).join('')

  const trainerNotesHtml = data.trainerNotes
    ? `
      <div style="background: #fef3c7; border-left: 4px solid #f59e0b; padding: 16px; margin: 20px 0; border-radius: 4px;">
        <h3 style="margin: 0 0 12px 0; color: #92400e;">📝 Trainer Notes</h3>
        <p style="margin: 0; color: #78350f;">${data.trainerNotes}</p>
      </div>
    `
    : ''

  const pdfButtonHtml = data.pdfUrl
    ? `
      <div style="text-align: center; margin: 24px 0;">
        <a href="${data.pdfUrl}" style="display: inline-block; background: #2563eb; color: white; padding: 12px 24px; border-radius: 6px; text-decoration: none; font-weight: 600;">
          📄 Download PDF Report
        </a>
      </div>
    `
    : ''

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #374151; max-width: 600px; margin: 0 auto; padding: 20px;">

      <!-- Header -->
      <div style="background: linear-gradient(135deg, #2563eb 0%, #7c3aed 100%); padding: 32px; border-radius: 12px; text-align: center; margin-bottom: 24px;">
        <h1 style="color: white; margin: 0; font-size: 24px;">💪 Workout Report</h1>
        <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0 0;">${data.sessionDate}</p>
      </div>

      <!-- Client info -->
      <div style="margin-bottom: 24px;">
        <p style="margin: 0; color: #6b7280;">Hi <strong>${data.clientName}</strong>,</p>
        <p style="margin: 8px 0 0 0; color: #6b7280;">Here's your workout summary from your session with ${data.trainerName}.</p>
      </div>

      <!-- Stats -->
      <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; margin-bottom: 24px;">
        <div style="background: #f3f4f6; padding: 16px; border-radius: 8px; text-align: center;">
          <div style="font-size: 24px; font-weight: bold; color: #2563eb;">${data.stats.totalSets}</div>
          <div style="font-size: 12px; color: #6b7280;">Total Sets</div>
        </div>
        <div style="background: #f3f4f6; padding: 16px; border-radius: 8px; text-align: center;">
          <div style="font-size: 24px; font-weight: bold; color: #7c3aed;">${data.stats.totalReps}</div>
          <div style="font-size: 12px; color: #6b7280;">Total Reps</div>
        </div>
        <div style="background: #f3f4f6; padding: 16px; border-radius: 8px; text-align: center;">
          <div style="font-size: 24px; font-weight: bold; color: #059669;">${data.stats.totalVolume.toLocaleString()}</div>
          <div style="font-size: 12px; color: #6b7280;">Volume (kg)</div>
        </div>
        <div style="background: #f3f4f6; padding: 16px; border-radius: 8px; text-align: center;">
          <div style="font-size: 24px; font-weight: bold; color: #dc2626;">${data.stats.exerciseCount}</div>
          <div style="font-size: 12px; color: #6b7280;">Exercises</div>
        </div>
      </div>

      ${highlightsHtml}

      ${trainerNotesHtml}

      <!-- Exercises -->
      <h3 style="color: #374151; border-bottom: 2px solid #e5e7eb; padding-bottom: 8px;">Exercise Details</h3>
      ${exercisesHtml}

      ${pdfButtonHtml}

      <!-- Footer -->
      <div style="margin-top: 32px; padding-top: 16px; border-top: 1px solid #e5e7eb; text-align: center; color: #9ca3af; font-size: 12px;">
        <p>Generated by FitLog Pro</p>
        <p>Keep pushing! 💪</p>
      </div>

    </body>
    </html>
  `
}
