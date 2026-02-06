// generate-html-report Edge Function
// Generates beautiful, shareable HTML workout reports

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface GenerateHtmlRequest {
  reportId: string
  sessionId?: string
}

interface SessionStats {
  totalSets: number
  totalReps: number
  totalVolume: number
  exerciseCount: number
  durationMinutes: number
  avgRpe?: number
}

interface Highlight {
  type: string
  title: string
  titleKo?: string
  description: string
  descriptionKo?: string
  exerciseName?: string
  data?: Record<string, unknown>
}

interface ExerciseData {
  name: string
  nameKo?: string
  muscleGroup?: string
  sets: SetData[]
  totalVolume: number
}

interface SetData {
  setNumber: number
  weight: number
  reps: number
  rpe?: number
  tags?: string[]
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    const { reportId, sessionId }: GenerateHtmlRequest = await req.json()

    if (!reportId && !sessionId) {
      return new Response(
        JSON.stringify({ error: 'Report ID or Session ID is required' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Fetch report data
    let report: Record<string, unknown> | null = null
    let targetSessionId = sessionId

    if (reportId) {
      const { data: reportData, error: reportError } = await supabase
        .from('session_reports')
        .select('*')
        .eq('id', reportId)
        .single()

      if (reportError || !reportData) {
        return new Response(
          JSON.stringify({ error: 'Report not found' }),
          {
            status: 404,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          }
        )
      }
      report = reportData
      targetSessionId = reportData.session_id
    }

    // Fetch session data with exercises and sets
    // Query format must match the Flutter app's working query
    const { data: session, error: sessionError } = await supabase
      .from('sessions')
      .select(`
        *,
        session_exercises(
          *,
          exercises(name, name_ko, muscle_group, secondary_muscles),
          set_records(*)
        ),
        clients:accounts!sessions_client_id_fkey(full_name, email),
        trainers:accounts!sessions_trainer_id_fkey(full_name)
      `)
      .eq('id', targetSessionId)
      .single()

    if (sessionError) {
      console.error('Session query error:', sessionError)
      return new Response(
        JSON.stringify({ error: 'Session not found', details: sessionError.message }),
        {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    if (!session) {
      return new Response(
        JSON.stringify({ error: 'Session not found', details: 'No data returned' }),
        {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Calculate stats and extract exercise data
    const { stats, exercises, highlights, musclesWorked } = processSessionData(session, report)

    // Format session date
    const sessionDate = new Date(session.started_at)
    const formattedDate = formatDate(sessionDate)

    // Build HTML content
    // Note: query aliases are `clients` and `trainers` (plural)
    const html = buildHtmlReport({
      clientName: (session.clients as Record<string, unknown>)?.full_name as string || 'Client',
      trainerName: (session.trainers as Record<string, unknown>)?.full_name as string || 'Trainer',
      sessionDate: formattedDate,
      stats,
      highlights: (report?.highlights as Highlight[]) || highlights,
      exercises,
      musclesWorked,
      trainerNotes: report?.trainer_comment as string | undefined,
    })

    // Generate unique filename
    const timestamp = Date.now()
    const fileName = `html-reports/${targetSessionId}_${timestamp}.html`

    // Convert HTML string to UTF-8 encoded bytes for proper Korean character support
    const encoder = new TextEncoder()
    const htmlBytes = encoder.encode(html)

    // Upload to Supabase Storage
    const { error: uploadError } = await supabase
      .storage
      .from('session-reports')
      .upload(fileName, htmlBytes, {
        contentType: 'text/html; charset=utf-8',
        upsert: true,
      })

    if (uploadError) {
      console.error('Upload error:', uploadError)
      return new Response(
        JSON.stringify({ error: 'Failed to upload HTML report' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Get public URL
    const { data: urlData } = supabase
      .storage
      .from('session-reports')
      .getPublicUrl(fileName)

    const htmlUrl = urlData.publicUrl

    // Update session_reports with HTML URL
    if (reportId) {
      await supabase
        .from('session_reports')
        .update({ html_url: htmlUrl })
        .eq('id', reportId)
    } else {
      // Create new report entry if needed
      await supabase
        .from('session_reports')
        .upsert({
          session_id: targetSessionId,
          html_url: htmlUrl,
        }, {
          onConflict: 'session_id',
        })
    }

    return new Response(
      JSON.stringify({
        success: true,
        htmlUrl,
        htmlContent: html,
        stats,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error generating HTML report:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

function processSessionData(session: Record<string, unknown>, report: Record<string, unknown> | null) {
  const sessionExercises = session.session_exercises as Array<Record<string, unknown>> || []

  let totalSets = 0
  let totalReps = 0
  let totalVolume = 0
  let rpeSum = 0
  let rpeCount = 0
  const exercises: ExerciseData[] = []
  const highlights: Highlight[] = []
  const musclesWorked: Set<string> = new Set()

  for (const sessionExercise of sessionExercises) {
    const setRecords = sessionExercise.set_records as Array<Record<string, unknown>> || []
    // Note: query uses `exercises(...)` without alias, so field is `exercises`
    const exercise = sessionExercise.exercises as Record<string, unknown>

    if (setRecords.length === 0) continue

    const sets: SetData[] = []
    let exerciseVolume = 0

    // Track muscles
    if (exercise?.muscle_group) {
      musclesWorked.add(exercise.muscle_group as string)
    }
    const secondaryMuscles = exercise?.secondary_muscles as string[] || []
    secondaryMuscles.forEach(m => musclesWorked.add(m))

    for (const setRecord of setRecords) {
      const weight = (setRecord.weight as number) || 0
      const reps = (setRecord.reps as number) || 0
      const rpe = setRecord.rpe as number | undefined
      const tags = setRecord.tags as string[] || []

      const volume = weight * reps
      exerciseVolume += volume
      totalVolume += volume
      totalSets++
      totalReps += reps

      if (rpe) {
        rpeSum += rpe
        rpeCount++
      }

      sets.push({
        setNumber: sets.length + 1,
        weight,
        reps,
        rpe,
        tags,
      })

      // Check for PR
      if (tags.includes('pr')) {
        highlights.push({
          type: 'pr',
          title: 'Personal Record!',
          titleKo: '개인 기록 달성!',
          description: `${exercise?.name || 'Exercise'}: ${weight}kg x ${reps} reps`,
          descriptionKo: `${exercise?.name_ko || exercise?.name || '운동'}: ${weight}kg x ${reps}회`,
          exerciseName: exercise?.name as string,
        })
      }
    }

    exercises.push({
      name: exercise?.name as string || 'Exercise',
      nameKo: exercise?.name_ko as string,
      muscleGroup: exercise?.muscle_group as string,
      sets,
      totalVolume: exerciseVolume,
    })
  }

  // Add volume highlight if high
  if (totalVolume > 5000) {
    highlights.push({
      type: 'effort',
      title: 'High Volume Session',
      titleKo: '고볼륨 세션',
      description: `${totalVolume.toLocaleString()}kg total volume`,
      descriptionKo: `총 볼륨 ${totalVolume.toLocaleString()}kg`,
    })
  }

  // Calculate duration
  const startedAt = new Date(session.started_at as string)
  const completedAt = session.completed_at ? new Date(session.completed_at as string) : new Date()
  const durationMinutes = Math.round((completedAt.getTime() - startedAt.getTime()) / 60000)

  const stats: SessionStats = {
    totalSets,
    totalReps,
    totalVolume,
    exerciseCount: exercises.length,
    durationMinutes,
    avgRpe: rpeCount > 0 ? Math.round((rpeSum / rpeCount) * 10) / 10 : undefined,
  }

  return { stats, exercises, highlights, musclesWorked: Array.from(musclesWorked) }
}

function formatDate(date: Date): string {
  const year = date.getFullYear()
  const month = date.getMonth() + 1
  const day = date.getDate()
  const weekdays = ['일', '월', '화', '수', '목', '금', '토']
  const weekday = weekdays[date.getDay()]

  return `${year}년 ${month}월 ${day}일 (${weekday})`
}

function getTagEmoji(tag: string): string {
  const tagEmojis: Record<string, string> = {
    pr: '🏆',
    form_issue: '⚠️',
    pain: '🤕',
    fatigue: '😓',
    good_condition: '💪',
    warmup: '🔥',
    drop_set: '⬇️',
    failure_set: '💀',
  }
  return tagEmojis[tag.toLowerCase()] || ''
}

function getHighlightStyle(type: string): { bg: string; border: string; icon: string } {
  const styles: Record<string, { bg: string; border: string; icon: string }> = {
    pr: { bg: '#fef9c3', border: '#eab308', icon: '🏆' },
    improvement: { bg: '#dcfce7', border: '#22c55e', icon: '📈' },
    consistency: { bg: '#dbeafe', border: '#3b82f6', icon: '💪' },
    effort: { bg: '#fce7f3', border: '#ec4899', icon: '⭐' },
    milestone: { bg: '#e0e7ff', border: '#6366f1', icon: '🎯' },
    caution: { bg: '#fee2e2', border: '#ef4444', icon: '⚠️' },
  }
  return styles[type] || { bg: '#f3f4f6', border: '#9ca3af', icon: '📌' }
}

interface HtmlReportData {
  clientName: string
  trainerName: string
  sessionDate: string
  stats: SessionStats
  highlights: Highlight[]
  exercises: ExerciseData[]
  musclesWorked: string[]
  trainerNotes?: string
}

function buildHtmlReport(data: HtmlReportData): string {
  const highlightsHtml = data.highlights.length > 0
    ? data.highlights.map(h => {
        const style = getHighlightStyle(h.type)
        return `
          <div class="highlight-card" style="background: ${style.bg}; border-left: 4px solid ${style.border};">
            <span class="highlight-icon">${style.icon}</span>
            <div class="highlight-content">
              <div class="highlight-title">${h.titleKo || h.title}</div>
              <div class="highlight-desc">${h.descriptionKo || h.description}</div>
            </div>
          </div>
        `
      }).join('')
    : ''

  const exercisesHtml = data.exercises.map(ex => {
    const setsHtml = ex.sets.map(set => {
      const weightStr = set.weight % 1 === 0 ? set.weight.toString() : set.weight.toFixed(1)
      const rpeStr = set.rpe ? `<span class="rpe-badge">RPE ${set.rpe}</span>` : ''
      const tagsStr = set.tags?.map(t => getTagEmoji(t)).filter(Boolean).join(' ') || ''

      return `
        <tr>
          <td class="set-number">${set.setNumber}</td>
          <td class="set-weight">${weightStr}kg</td>
          <td class="set-reps">${set.reps}회</td>
          <td class="set-rpe">${rpeStr}</td>
          <td class="set-tags">${tagsStr}</td>
        </tr>
      `
    }).join('')

    const volumeStr = ex.totalVolume.toLocaleString()

    return `
      <div class="exercise-card">
        <div class="exercise-header">
          <div class="exercise-name">${ex.nameKo || ex.name}</div>
          <div class="exercise-meta">
            <span class="muscle-badge">${ex.muscleGroup || 'General'}</span>
            <span class="volume-badge">볼륨: ${volumeStr}kg</span>
          </div>
        </div>
        <table class="sets-table">
          <thead>
            <tr>
              <th>세트</th>
              <th>무게</th>
              <th>횟수</th>
              <th>RPE</th>
              <th></th>
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
      <div class="trainer-notes">
        <div class="notes-header">
          <span class="notes-icon">📝</span>
          <span class="notes-title">트레이너 코멘트</span>
        </div>
        <div class="notes-content">${data.trainerNotes}</div>
      </div>
    `
    : ''

  const muscleMapHtml = data.musclesWorked.length > 0
    ? `
      <div class="muscles-section">
        <h3 class="section-title">운동 근육</h3>
        <div class="muscles-grid">
          ${data.musclesWorked.map(m => `<span class="muscle-tag">${m}</span>`).join('')}
        </div>
      </div>
    `
    : ''

  return `
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>운동 리포트 - ${data.sessionDate}</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, 'Noto Sans KR', sans-serif;
      line-height: 1.6;
      color: #1f2937;
      background: #f3f4f6;
      min-height: 100vh;
    }

    .container {
      max-width: 600px;
      margin: 0 auto;
      background: #ffffff;
      min-height: 100vh;
    }

    /* Header */
    .header {
      background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #a855f7 100%);
      padding: 40px 24px 48px;
      text-align: center;
      position: relative;
      overflow: hidden;
    }

    .header::before {
      content: '';
      position: absolute;
      top: -50%;
      left: -50%;
      width: 200%;
      height: 200%;
      background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 50%);
      animation: pulse 4s ease-in-out infinite;
    }

    @keyframes pulse {
      0%, 100% { transform: scale(1); }
      50% { transform: scale(1.1); }
    }

    .header-content {
      position: relative;
      z-index: 1;
    }

    .logo {
      font-size: 14px;
      color: rgba(255,255,255,0.8);
      margin-bottom: 8px;
      letter-spacing: 2px;
      text-transform: uppercase;
    }

    .header-title {
      font-size: 28px;
      font-weight: 700;
      color: white;
      margin-bottom: 8px;
    }

    .header-date {
      font-size: 16px;
      color: rgba(255,255,255,0.9);
      margin-bottom: 4px;
    }

    .header-duration {
      font-size: 14px;
      color: rgba(255,255,255,0.7);
    }

    /* Client Info */
    .client-info {
      padding: 20px 24px;
      background: #f9fafb;
      border-bottom: 1px solid #e5e7eb;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .client-name {
      font-size: 18px;
      font-weight: 600;
      color: #111827;
    }

    .trainer-name {
      font-size: 14px;
      color: #6b7280;
    }

    /* Stats Grid */
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 12px;
      padding: 24px;
      background: #ffffff;
    }

    .stat-card {
      background: linear-gradient(135deg, #f9fafb 0%, #f3f4f6 100%);
      border-radius: 12px;
      padding: 16px 12px;
      text-align: center;
      border: 1px solid #e5e7eb;
    }

    .stat-value {
      font-size: 24px;
      font-weight: 700;
      margin-bottom: 4px;
    }

    .stat-value.sets { color: #6366f1; }
    .stat-value.reps { color: #8b5cf6; }
    .stat-value.volume { color: #10b981; }
    .stat-value.exercises { color: #f59e0b; }

    .stat-label {
      font-size: 11px;
      color: #6b7280;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    /* Highlights */
    .highlights-section {
      padding: 0 24px 24px;
    }

    .section-title {
      font-size: 16px;
      font-weight: 600;
      color: #374151;
      margin-bottom: 12px;
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .highlight-card {
      display: flex;
      align-items: flex-start;
      gap: 12px;
      padding: 14px 16px;
      border-radius: 10px;
      margin-bottom: 10px;
    }

    .highlight-icon {
      font-size: 20px;
      flex-shrink: 0;
    }

    .highlight-content {
      flex: 1;
    }

    .highlight-title {
      font-size: 14px;
      font-weight: 600;
      color: #1f2937;
      margin-bottom: 2px;
    }

    .highlight-desc {
      font-size: 13px;
      color: #4b5563;
    }

    /* Muscles */
    .muscles-section {
      padding: 0 24px 24px;
    }

    .muscles-grid {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }

    .muscle-tag {
      background: #e0e7ff;
      color: #4338ca;
      padding: 6px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 500;
    }

    /* Exercises */
    .exercises-section {
      padding: 0 24px 24px;
    }

    .exercise-card {
      background: #ffffff;
      border: 1px solid #e5e7eb;
      border-radius: 12px;
      margin-bottom: 16px;
      overflow: hidden;
      box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    }

    .exercise-header {
      padding: 16px;
      border-bottom: 1px solid #f3f4f6;
    }

    .exercise-name {
      font-size: 16px;
      font-weight: 600;
      color: #111827;
      margin-bottom: 8px;
    }

    .exercise-meta {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }

    .muscle-badge {
      background: #f3f4f6;
      color: #6b7280;
      padding: 4px 10px;
      border-radius: 6px;
      font-size: 12px;
    }

    .volume-badge {
      background: #d1fae5;
      color: #065f46;
      padding: 4px 10px;
      border-radius: 6px;
      font-size: 12px;
      font-weight: 500;
    }

    .sets-table {
      width: 100%;
      border-collapse: collapse;
    }

    .sets-table th {
      background: #f9fafb;
      padding: 10px 12px;
      text-align: left;
      font-size: 11px;
      font-weight: 600;
      color: #6b7280;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .sets-table td {
      padding: 12px;
      border-top: 1px solid #f3f4f6;
      font-size: 14px;
    }

    .set-number {
      color: #9ca3af;
      font-weight: 500;
      width: 50px;
    }

    .set-weight {
      font-weight: 600;
      color: #111827;
    }

    .set-reps {
      color: #374151;
    }

    .rpe-badge {
      background: #fef3c7;
      color: #92400e;
      padding: 2px 8px;
      border-radius: 4px;
      font-size: 12px;
      font-weight: 500;
    }

    .set-tags {
      font-size: 16px;
    }

    /* Trainer Notes */
    .trainer-notes {
      margin: 0 24px 24px;
      background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
      border-radius: 12px;
      padding: 16px;
      border-left: 4px solid #f59e0b;
    }

    .notes-header {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 8px;
    }

    .notes-icon {
      font-size: 18px;
    }

    .notes-title {
      font-size: 14px;
      font-weight: 600;
      color: #92400e;
    }

    .notes-content {
      font-size: 14px;
      color: #78350f;
      line-height: 1.6;
    }

    /* Footer */
    .footer {
      padding: 24px;
      background: #f9fafb;
      text-align: center;
      border-top: 1px solid #e5e7eb;
    }

    .print-btn {
      background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
      color: white;
      border: none;
      padding: 14px 32px;
      border-radius: 10px;
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 8px;
      transition: transform 0.2s, box-shadow 0.2s;
    }

    .print-btn:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(99, 102, 241, 0.4);
    }

    .footer-branding {
      margin-top: 16px;
      font-size: 12px;
      color: #9ca3af;
    }

    .footer-branding a {
      color: #6366f1;
      text-decoration: none;
    }

    /* Print styles */
    @media print {
      body {
        background: white;
      }

      .container {
        max-width: 100%;
        box-shadow: none;
      }

      .header {
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
      }

      .stat-card {
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
      }

      .highlight-card {
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
      }

      .no-print {
        display: none !important;
      }

      .exercise-card {
        break-inside: avoid;
      }
    }

    /* Mobile responsive */
    @media (max-width: 480px) {
      .stats-grid {
        grid-template-columns: repeat(2, 1fr);
        gap: 8px;
        padding: 16px;
      }

      .stat-card {
        padding: 12px 8px;
      }

      .stat-value {
        font-size: 20px;
      }

      .header {
        padding: 32px 16px 40px;
      }

      .header-title {
        font-size: 24px;
      }

      .highlights-section,
      .muscles-section,
      .exercises-section {
        padding: 0 16px 20px;
      }

      .trainer-notes {
        margin: 0 16px 20px;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <!-- Header -->
    <div class="header">
      <div class="header-content">
        <div class="logo">FitLog Pro</div>
        <h1 class="header-title">💪 운동 리포트</h1>
        <div class="header-date">${data.sessionDate}</div>
        <div class="header-duration">운동 시간: ${data.stats.durationMinutes}분</div>
      </div>
    </div>

    <!-- Client Info -->
    <div class="client-info">
      <div>
        <div class="client-name">${data.clientName}님</div>
        <div class="trainer-name">담당: ${data.trainerName} 트레이너</div>
      </div>
    </div>

    <!-- Stats -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-value sets">${data.stats.totalSets}</div>
        <div class="stat-label">세트</div>
      </div>
      <div class="stat-card">
        <div class="stat-value reps">${data.stats.totalReps}</div>
        <div class="stat-label">횟수</div>
      </div>
      <div class="stat-card">
        <div class="stat-value volume">${data.stats.totalVolume.toLocaleString()}</div>
        <div class="stat-label">볼륨 (kg)</div>
      </div>
      <div class="stat-card">
        <div class="stat-value exercises">${data.stats.exerciseCount}</div>
        <div class="stat-label">운동</div>
      </div>
    </div>

    <!-- Highlights -->
    ${highlightsHtml ? `
    <div class="highlights-section">
      <h3 class="section-title">✨ 하이라이트</h3>
      ${highlightsHtml}
    </div>
    ` : ''}

    <!-- Muscles Worked -->
    ${muscleMapHtml}

    <!-- Exercises -->
    <div class="exercises-section">
      <h3 class="section-title">🏋️ 운동 상세</h3>
      ${exercisesHtml}
    </div>

    <!-- Trainer Notes -->
    ${trainerNotesHtml}

    <!-- Footer -->
    <div class="footer">
      <button class="print-btn no-print" onclick="window.print()">
        📄 PDF로 저장
      </button>
      <div class="footer-branding">
        <a href="https://fitlogpro.app">FitLog Pro</a>로 생성됨 · Keep pushing! 💪
      </div>
    </div>
  </div>
</body>
</html>
  `.trim()
}
