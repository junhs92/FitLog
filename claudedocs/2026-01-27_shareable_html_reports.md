# Shareable HTML Session Reports

## Overview

This feature adds the ability to generate beautiful, shareable HTML reports for workout sessions that can be:
- Viewed in any browser via a public URL
- Downloaded/printed as PDF using the browser's print functionality
- Shared via any messaging platform (KakaoTalk, WhatsApp, etc.)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Report Sharing Flow                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  User taps "Share Link" → generateHtmlReport() called            │
│                                        ↓                          │
│                         Edge Function: generate-html-report       │
│                                        ↓                          │
│                    ┌────────────────────────────────┐            │
│                    │   Beautiful HTML Report Page   │            │
│                    │   - Gradient header            │            │
│                    │   - Client/Trainer info        │            │
│                    │   - Stats grid (sets/reps/vol) │            │
│                    │   - Visual highlights          │            │
│                    │   - Exercise details           │            │
│                    │   - Trainer notes              │            │
│                    │   - Print/Download button      │            │
│                    └────────────────────────────────┘            │
│                                        ↓                          │
│                 Upload to Supabase Storage (session-reports)      │
│                                        ↓                          │
│                      Public URL returned to Flutter app           │
│                                        ↓                          │
│                  Native Share dialog with URL (share_plus)        │
└─────────────────────────────────────────────────────────────────┘
```

## Files Changed/Created

### New Files

1. **`supabase/functions/generate-html-report/index.ts`**
   - New edge function that generates beautiful HTML reports
   - Fetches session data with exercises and sets
   - Calculates stats (sets, reps, volume, duration)
   - Generates self-contained HTML with embedded CSS
   - Uploads to Supabase Storage and returns public URL

2. **`supabase/migrations/20260127_100000_add_html_url_to_session_reports.sql`**
   - Adds `html_url` column to `session_reports` table

### Modified Files

1. **`lib/features/ai_report/domain/entities/session_report.dart`**
   - Added `htmlUrl` field to `SessionReportEntity`
   - Updated `copyWith` method

2. **`lib/features/ai_report/data/models/session_report_model.dart`**
   - Added `htmlUrl` to constructor
   - Updated `fromJson` and `toJson` methods
   - Updated `fromEntity` factory

3. **`lib/features/ai_report/domain/repositories/report_repository.dart`**
   - Added `generateHtmlReport` method signature

4. **`lib/features/ai_report/data/repositories/report_repository_impl.dart`**
   - Implemented `generateHtmlReport` method

5. **`lib/features/ai_report/data/datasources/report_remote_datasource.dart`**
   - Added `generateHtmlReport` method that calls edge function

6. **`lib/features/ai_report/presentation/providers/report_provider.dart`**
   - Added `generateHtmlReport` method to notifier

7. **`lib/features/ai_report/presentation/screens/report_view_screen.dart`**
   - Added `share_plus` import
   - Added "Share Link" button to bottom actions
   - Added `_generateAndShareLink` method

## HTML Report Features

### Visual Design
- **Header**: Purple gradient background with FitLog Pro branding
- **Stats Grid**: 4-column grid showing sets, reps, volume, and exercise count
- **Highlights**: Color-coded cards for PRs, high volume, etc.
- **Exercise Cards**: Detailed set-by-set breakdown with RPE and tags
- **Trainer Notes**: Highlighted section with trainer comments

### Technical Features
- **Responsive**: Mobile-first design, adapts to screen size
- **Print-optimized**: `@media print` styles for clean PDF output
- **Self-contained**: No external CSS/JS dependencies
- **Korean localization**: Full Korean language support

## Usage

1. Complete a workout session
2. Navigate to Report View screen
3. Tap "Share Link" button
4. Wait for HTML generation (shows loading indicator)
5. Native share sheet opens with the URL
6. Share via KakaoTalk, WhatsApp, or copy link

## Storage

HTML reports are stored in:
- **Supabase Storage bucket**: `session-reports`
- **Path**: `html-reports/{sessionId}_{timestamp}.html`
- **Access**: Public (anyone with link can view)
- **Expiration**: Never (reports stay accessible indefinitely)

## Dependencies

- `share_plus: ^10.0.0` (already in pubspec.yaml)
- Supabase Storage bucket `session-reports` must exist
