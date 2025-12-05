# FitLog Pro

## AI-Powered Personal Training Management Platform

### Product Requirements Document (PRD)

**Version:** 1.2  
**Date:** December 2025  
**Status:** Draft  
**Document Owner:** Product Team  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement](#2-problem-statement)
3. [Target Users](#3-target-users)
4. [Architecture Decision](#4-architecture-decision)
5. [Core Features - Trainer](#5-core-features---trainer)
6. [Core Features - Client (FitLog Life)](#6-core-features---client-fitlog-life)
7. [AI Exercise Intelligence](#7-ai-exercise-intelligence)
8. [Trainer Education & Certification](#8-trainer-education--certification-fitlog-academy)
9. [User Stories](#9-user-stories)
10. [Technical Architecture](#10-technical-architecture)
11. [Success Metrics & KPIs](#11-success-metrics--kpis)
12. [Product Roadmap](#12-product-roadmap)
13. [Risks & Mitigation](#13-risks--mitigation)
14. [Appendix](#14-appendix)

---

## 1. Executive Summary

FitLog Pro is a comprehensive mobile and web application designed to revolutionize the personal training industry by bridging the gap between trainers and clients through intelligent data collection, automated session logging, and AI-powered workout generation.

The platform addresses three critical pain points in the personal training ecosystem: inconsistent lifestyle tracking, time-consuming post-session documentation, and the steep learning curve for new trainers in creating effective workout programs.

**Key Innovation:** Zero-typing interface using buttons, sliders, and a pre-built content library enables trainers to log sessions in seconds, not minutes.

**What's New in v1.2:**
- Single app architecture with role-based views (trainer vs. client)
- FitLog Life: Client lifestyle tracking module
- AI Exercise Reasoning: Transparent explanations for AI-recommended exercises
- Exercise Swap Feature: Trainer-driven customization of AI programs
- Session-time Alternative Recommendations: Real-time exercise adjustments based on client difficulty
- FitLog Academy: Structured trainer education with certification and feature gating

### Document Information

| Field | Details |
|-------|---------|
| **Document Owner** | Product Team |
| **Target Launch** | Q1 2026 (MVP) |
| **Target Users** | Personal Trainers & Their Clients |
| **Platform** | iOS, Android, Web |

---

## 2. Problem Statement

The personal training industry faces significant operational challenges that impact both service quality and business scalability. Our research has identified three core problems:

### Problem 1: Fragmented Lifestyle Tracking

Both trainers and clients currently rely on scattered methods to track lifestyle patterns, including random photo albums for meal tracking, mental notes, and inconsistent communication. This fragmentation leads to incomplete client profiles and suboptimal training outcomes.

**Key Issues:**
- Clients forget to log meals or take photos consistently
- Trainers lack visibility into client behavior between sessions
- No centralized system to correlate lifestyle data with training progress

### Problem 2: Post-Session Documentation Burden

After completing training sessions, trainers rarely have adequate time to create detailed session summaries and personalized guidance for clients. This documentation, which could be a premium differentiator, is often neglected or done hastily.

**Key Issues:**
- Trainers see 12-15 clients per day, 7 days per week - extremely high workload
- Only 5-10 minutes between sessions - including personal breaks
- Realistically less than 3-5 minutes available for any documentation
- Detailed session logs take 10-15 minutes to write properly - impossible with current constraints

### Problem 3: New Trainer Experience Gap

Trainers new to the field often struggle to create appropriate workout programs tailored to individual client needs. They tend to rely heavily on generic routines or their personal workout preferences rather than evidence-based programming.

**Key Issues:**
- New trainers average 2-3 years to develop strong programming intuition
- Client retention suffers due to suboptimal workout design
- Knowledge transfer from experienced trainers is inconsistent

---

## 3. Target Users

### 3.1 Primary Users: Personal Trainers

| Attribute | Description |
|-----------|-------------|
| **Demographics** | Age 22-45, certified personal trainers, gym employees or independent contractors |
| **Experience Level** | 0-10+ years; primary focus on trainers with 0-3 years experience |
| **Client Load** | 12-15 clients per day, 7 days per week (80-100+ sessions weekly) |
| **Pain Points** | Time management, client retention, programming variety, documentation, burnout |
| **Tech Comfort** | Moderate to high; daily smartphone users |

### 3.2 Secondary Users: Clients

| Attribute | Description |
|-----------|-------------|
| **Demographics** | Age 18-65, diverse fitness levels, health-conscious individuals |
| **Goals** | Weight loss, muscle gain, rehabilitation, athletic performance, general fitness |
| **Expectations** | Personalized attention, progress tracking, clear guidance, accountability |
| **Tech Comfort** | Varies widely; app must be intuitive for all levels |

---

## 4. Architecture Decision

### Single App with Role-Based Views

After careful consideration, we have chosen to implement a **single unified application** with role-based views rather than separate apps for trainers and clients.

### Decision Rationale

| Factor | Two Separate Apps | Single App (Chosen) |
|--------|-------------------|---------------------|
| **Development** | Duplicate codebases, 2x maintenance | Single codebase, unified updates |
| **App Store** | Two listings, split reviews | One listing, consolidated reviews |
| **User Experience** | Download different apps | One app, role-based access |
| **Data Sync** | Complex cross-app sync | Native real-time sync |
| **Branding** | Fragmented identity | Unified brand experience |

### Role-Based View Structure

**Trainer View:**
- Session recording (60-second logging)
- Member management
- AI program generation with exercise customization
- Member lifestyle monitoring dashboard
- AI report generation

**Client View (FitLog Life):**
- Daily lifestyle logging (meals, water, sleep, activity, mood)
- Body photo tracking
- Trainer feedback viewing
- Progress statistics
- Session history

---

## 5. Core Features - Trainer

### 5.1 Client Data Collection System

**Purpose:** Comprehensive client profiling to enable personalized training programs

#### Initial Onboarding Assessment
- Personal information (age, gender, occupation, schedule)
- Health history and medical conditions
- Current medications and supplements
- Fitness goals (primary and secondary)
- Current fitness level assessment
- Exercise history and preferences

#### Lifestyle Pattern Monitoring
- Real-time visibility into client lifestyle logs
- Meal photo review with AI nutritional analysis
- Sleep and recovery tracking
- Activity levels between sessions
- Trend analysis and alerts

### 5.2 Personal Training Session Log

**Purpose:** Streamlined session documentation with AI-assisted summarization

#### Zero-Typing Interface Design (Critical Feature)

**Design Philosophy:** Trainers have 5-10 minutes between clients including personal breaks. Logging must take under 60 seconds using only taps and swipes.

**Button-Based Input System:**
- Weight adjustment: [-10] [-5] [-2.5] [+2.5] [+5] [+10]
- Reps selection: Tap buttons [6] [7] [8] [9] [10] [11] [12]
- RPE slider: Visual scale from Easy to Max
- Quick tags: [PR] [Form Issue] [Pain] [Fatigue] [Good Condition]

### 5.3 AI Report Generation

**Purpose:** Automated session summaries for client communication

**Features:**
- One-tap report generation
- Customizable templates
- KakaoTalk/SMS integration
- Performance highlights extraction
- Trainer comment insertion

---

## 6. Core Features - Client (FitLog Life)

### 6.1 Overview

FitLog Life is the client-facing module integrated within the FitLog Pro app. It provides comprehensive lifestyle tracking that syncs in real-time with the trainer's dashboard.

### 6.2 Interface Structure

**4-Tab Navigation:**

| Tab | Purpose | Key Features |
|-----|---------|--------------|
| **Home** | Dashboard | Today's summary, trainer messages, upcoming sessions |
| **Record** | Daily logging | Meal photos, water, sleep, activity, mood, body photos |
| **Stats** | Progress tracking | Trends, charts, achievements, body composition |
| **Profile** | Settings | Personal info, goals, notifications, trainer link |

### 6.3 Daily Lifestyle Logging

#### Meal Tracking
- Photo-based logging (camera or gallery)
- AI nutritional analysis (calories, macros estimated)
- Meal timing and descriptions
- Trainer visibility toggle

#### Hydration Tracking
- Quick-add water intake (cups/ml)
- Daily goal progress
- Reminder notifications

#### Sleep Tracking
- Bedtime and wake time logging
- Sleep quality rating (1-5)
- Integration with wearables (future)

#### Activity Tracking
- Steps (manual or device sync)
- Workout type selection
- Duration and intensity

#### Mood & Energy
- Visual mood selector (emoji-based)
- Energy level rating
- Notes for trainer

#### Body Photo Tracking
- Standardized photo capture guidance
- Before/after comparison tools
- Privacy controls

### 6.4 Trainer Visibility

All logged data flows to the trainer's monitoring dashboard with these controls:
- Client can mark items as "private" (hidden from trainer)
- Trainer receives daily summary notifications
- Anomaly alerts (e.g., missed meals, poor sleep patterns)

---

## 7. AI Exercise Intelligence

### 7.1 AI Program Generation with Exercise Swap

**Purpose:** Enable trainers to review, understand, and customize AI-generated workout programs

#### AI Reasoning Display

When AI generates a workout program, each exercise includes transparent reasoning:

**Example: Barbell Squat Selection**

| Reason Type | Explanation |
|-------------|-------------|
| **Goal Alignment** | Optimal for overall lower body strength development |
| **History-Based** | Consistent weight progression over past 4 weeks |
| **Form Readiness** | Form stability confirmed in previous sessions |

#### Exercise Swap Feature

**Workflow:**
1. Trainer taps any AI-recommended exercise
2. System displays AI selection reasons (3 key points)
3. System shows alternative exercises with swap reasons
4. Trainer selects preferred alternative
5. Program updates instantly

**Alternative Exercise Display:**

| Alternative | Swap Reason |
|-------------|-------------|
| Leg Press | Reduced knee stress, similar muscle activation |
| Goblet Squat | Core stability focus, improved range of motion |
| Smith Machine Squat | Balance assistance, safe for heavy loads |

**Key Principle:** AI recommends, trainer decides. The trainer always has final control over the program.

### 7.2 Session-Time Alternative Recommendations

**Purpose:** Real-time exercise adjustments based on client performance during sessions

#### Difficulty Feedback System

During active sessions, trainers can indicate client performance:

| Feedback | Meaning | AI Response |
|----------|---------|-------------|
| **Struggling (👎)** | Client finding exercise too difficult | Recommend easier alternatives with similar movement patterns |
| **Too Easy (👍)** | Client completing with excess capacity | Recommend more challenging alternatives |

#### Alternative Recommendation Logic

**When Client Struggles:**

| Current Exercise | Alternative | Reason |
|------------------|-------------|--------|
| Barbell Squat | Leg Press | Same muscle group, stable positioning |
| Barbell Squat | Goblet Squat | Lighter load, focus on form |
| Barbell Squat | Box Squat | Reduced range of motion, less stress |

**When Exercise is Too Easy:**

| Current Exercise | Alternative | Reason |
|------------------|-------------|--------|
| Barbell Squat | Front Squat | Increased core demand, upright torso |
| Barbell Squat | Pause Squat (3s) | Extended time under tension |
| Barbell Squat | Jump Squat | Added explosive power component |

#### Movement Pattern Preservation

**Critical Design Principle:** Alternative recommendations maintain similar movement patterns to preserve workout intent.

| Movement Pattern | Examples |
|------------------|----------|
| Squat Pattern | Back squat, front squat, goblet squat, leg press, hack squat |
| Hip Hinge | Deadlift, RDL, good morning, cable pull-through |
| Horizontal Push | Bench press, push-up, dumbbell press, machine chest press |
| Horizontal Pull | Barbell row, cable row, dumbbell row, machine row |
| Vertical Push | Overhead press, dumbbell shoulder press, machine press |
| Vertical Pull | Pull-up, lat pulldown, cable pulldown |

---

## 8. Trainer Education & Certification (FitLog Academy)

### 8.1 Overview

To systematically use FitLog Pro's AI-powered features, trainers must understand **structured and pre-defined program design principles**. Without this foundation, trainers cannot effectively interpret AI recommendations, make informed exercise swaps, or provide consistent client outcomes.

**FitLog Academy** is an integrated education system that teaches the **FitLog Program Design Methodology** - a structured approach to workout programming that all trainers learn before accessing AI features. This ensures every trainer using the app shares the same context, vocabulary, and decision-making framework.

### 8.2 Core Philosophy

> **"AI는 추천하고, 트레이너가 결정한다"** (AI recommends, trainer decides)

For trainers to make good decisions, they must understand:
1. **Why** the AI selected specific exercises
2. **When** to accept vs. customize recommendations  
3. **How** to maintain program integrity when making changes

This requires structured education, not just app tutorials.

### 8.3 Problem Statement

| Issue | Impact | Academy Solution |
|-------|--------|------------------|
| Trainers have inconsistent programming knowledge | AI recommendations misunderstood or misapplied | Standardized curriculum before AI access |
| No shared vocabulary between trainers | Collaboration and knowledge sharing difficult | Common terminology and frameworks |
| New trainers lack structured learning path | Steep learning curve, higher churn | Progressive certification levels |
| AI works best with structured thinking | Unstructured approaches reduce AI effectiveness | Teach structured decision-making |
| Trainers don't understand "why" behind programs | Over-reliance on AI without critical thinking | Explain reasoning behind every principle |

### 8.4 FitLog Program Design Methodology

The app teaches a specific, structured approach to program design:

#### The 6 Pillars of FitLog Programming

| Pillar | Concept | Application |
|--------|---------|-------------|
| **1. Movement Patterns** | 6 fundamental patterns (Squat, Hinge, Push, Pull, Carry, Rotation) | Every exercise categorized; alternatives within same pattern |
| **2. Training Variables** | Volume, Intensity, Frequency, Density | Systematic adjustment for progression |
| **3. Periodization** | Mesocycle → Microcycle → Session structure | Long-term planning with weekly/daily execution |
| **4. Progressive Overload** | Systematic increase in training stimulus | Weight, reps, sets, tempo, ROM progression |
| **5. Recovery Integration** | Training-recovery balance | Deload protocols, lifestyle data interpretation |
| **6. Individualization** | Client-specific modifications | Limitations, goals, preferences, history |

### 8.5 Course Structure

#### Tier 1: Foundations (Required for AI Features)

| Module | Topics | Duration | Assessment |
|--------|--------|----------|------------|
| **M1: Program Design Basics** | 6 pillars overview, training variables, goal-to-program mapping | 45 min | Quiz (80%+) |
| **M2: Movement Patterns** | 6 patterns deep-dive, exercise classification, pattern-based alternatives | 45 min | Classification test |
| **M3: Client Assessment** | Goal setting framework, limitation identification, baseline testing | 30 min | Case study |
| **M4: Understanding AI** | How AI selects exercises, interpreting reasoning, when to swap | 30 min | Practical exercise |

**Completion unlocks:** AI program generation, exercise swap, session alternatives

#### Tier 2: Advanced Programming (Optional Enhancement)

| Module | Topics | Duration |
|--------|--------|----------|
| **M5: Periodization Models** | Linear, undulating, block periodization, peaking | 45 min |
| **M6: Special Populations** | Elderly, post-rehab, athletes, beginners, pregnant | 45 min |
| **M7: Nutrition Integration** | Training-nutrition coordination, FitLog Life data interpretation | 30 min |

#### Tier 3: Master Trainer (Elite Certification)

| Module | Topics | Duration |
|--------|--------|----------|
| **M8: Custom Templates** | Building personal exercise libraries, template creation | 60 min |
| **M9: Business & Retention** | Using data for consultations, client communication strategies | 45 min |
| **Final Exam** | Comprehensive practical assessment with case studies | 90 min |

### 8.6 Feature Gating Strategy

**Critical Design Decision:** AI features are locked until trainers complete Tier 1 certification.

| Certification Status | Available Features |
|---------------------|-------------------|
| **No Certification** | Manual session logging, basic history, client management |
| **Tier 1 Complete** | ✅ AI program generation ✅ Exercise swap ✅ Session alternatives ✅ AI reports |
| **Tier 2 Complete** | ✅ Advanced periodization templates ✅ Special population filters ✅ Nutrition integration |
| **Tier 3 Complete** | ✅ Custom exercise creation ✅ Template sharing ✅ Master Trainer badge ✅ Mentorship access |

**Rationale:** This ensures trainers understand the methodology before using AI tools, resulting in:
- Better AI utilization
- More informed customization decisions
- Consistent quality across all FitLog trainers
- Reduced support issues from confused users

### 8.7 Learning Experience Design

**Format:**
- Video lessons (5-10 minute segments for mobile-friendly learning)
- Interactive quizzes after each section
- Practical exercises using the app with sample clients
- Case study scenarios with AI program review

**Gamification:**
- Progress badges for module completion
- "FitLog Certified Trainer" badge displayed on profile after Tier 1
- Leaderboards for course completion
- Streak rewards for consistent learning

**Accessibility:**
- Available in-app (no external platform needed)
- Offline video downloads for gym environments
- Korean language with future English/Japanese expansion

### 8.8 Benefits

**For Trainers:**
- Structured learning path accelerates career development
- Certification credential for marketing ("FitLog Certified Trainer")
- Deep understanding of AI = better client outcomes
- Shared vocabulary enables collaboration with other FitLog trainers

**For FitLog Pro:**
- Higher trainer retention (invested in learning)
- Better AI usage = better data quality = improved AI models
- Community building through shared methodology
- Premium revenue opportunity (advanced courses, certifications)
- Reduced support burden (educated users ask fewer questions)

**For Clients:**
- Consistent, high-quality service from any FitLog trainer
- Evidence-based programming regardless of trainer experience level
- Trainers who can explain the "why" behind every program decision

### 8.9 Implementation Phases

| Phase | Features | Timeline |
|-------|----------|----------|
| **Phase 1** | Tier 1 video courses (M1-M4) + basic quizzes | Q2 2026 |
| **Phase 2** | Interactive assessments + certification badges + feature gating | Q3 2026 |
| **Phase 3** | Tier 2-3 courses + mentorship program | Q4 2026 |
| **Phase 4** | Community features + trainer-to-trainer content sharing | 2027 |

---

## 9. User Stories

### Trainer Stories

| ID | Story | Priority |
|----|-------|----------|
| T-01 | As a trainer, I want to log a complete session in under 60 seconds so I can move to my next client | P0 |
| T-02 | As a trainer, I want to see why AI selected each exercise so I can make informed decisions | P0 |
| T-03 | As a trainer, I want to swap AI-recommended exercises with alternatives so I can customize programs | P0 |
| T-04 | As a trainer, I want to get real-time alternative suggestions when clients struggle so I can adapt on the fly | P1 |
| T-05 | As a trainer, I want to monitor my clients' daily lifestyle so I can provide better guidance | P1 |
| T-06 | As a trainer, I want AI-generated session reports so I can send professional summaries without writing | P1 |
| T-07 | As a trainer, I want to learn structured program design through courses so I can use the app more effectively | P1 |
| T-08 | As a trainer, I want to earn certification badges so I can demonstrate my expertise to clients | P2 |
| T-09 | As a trainer, I want to mentor new trainers so I can advance to Master Trainer level | P2 |

### Client Stories

| ID | Story | Priority |
|----|-------|----------|
| C-01 | As a client, I want to log my meals with photos so my trainer understands my nutrition | P0 |
| C-02 | As a client, I want to track my water intake so I stay accountable for hydration | P1 |
| C-03 | As a client, I want to record my sleep so my trainer knows my recovery status | P1 |
| C-04 | As a client, I want to see my progress over time so I stay motivated | P1 |
| C-05 | As a client, I want to take body photos with guidance so I can track visual changes | P2 |
| C-06 | As a client, I want to hide certain data from my trainer so I maintain some privacy | P2 |

---

## 10. Technical Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      FitLog Pro App                              │
│  ┌─────────────────────┐    ┌─────────────────────────────────┐ │
│  │   Trainer View      │    │      Client View (FitLog Life)  │ │
│  │  - Session Recording│    │  - Lifestyle Logging            │ │
│  │  - AI Programs      │◄──►│  - Progress Tracking            │ │
│  │  - Member Monitor   │    │  - Trainer Feedback             │ │
│  └─────────────────────┘    └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────────┐
              │         Backend Services          │
              │  - Authentication & Roles         │
              │  - Real-time Data Sync            │
              │  - AI Exercise Engine             │
              │  - Notification Service           │
              └───────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────────┐
              │         AI Services               │
              │  - Exercise Recommendation        │
              │  - Alternative Suggestions        │
              │  - Reasoning Generation           │
              │  - Report Summarization           │
              │  - Nutritional Analysis           │
              └───────────────────────────────────┘
```

### AI Exercise Engine

**Core Capabilities:**

| Capability | Description |
|------------|-------------|
| **Program Generation** | Create personalized workout programs based on client profile |
| **Reasoning Engine** | Generate human-readable explanations for exercise selections |
| **Alternative Matching** | Find similar-pattern exercises adjusted for difficulty |
| **Safety Filtering** | Exclude exercises conflicting with client limitations |
| **Progressive Overload** | Calculate appropriate weight/rep progressions |

---

## 11. Success Metrics & KPIs

### Primary Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Session logging time | < 60 seconds | Average time from start to complete |
| AI program customization rate | > 40% | % of programs with exercise swaps |
| Client lifestyle logging | > 5 entries/week | Average logs per active client |
| Trainer retention (30-day) | > 70% | % still active after 30 days |
| Client retention (30-day) | > 60% | % still logging after 30 days |

### AI Feature Metrics

| Metric | Target | Purpose |
|--------|--------|---------|
| Exercise swap usage | > 30% of AI programs | Validates trainer customization need |
| Session alternative usage | > 20% of sessions | Validates real-time adjustment need |
| AI reasoning helpfulness | > 4.0/5.0 rating | User satisfaction with explanations |

### Education Metrics (Phase 2+)

| Metric | Target | Purpose |
|--------|--------|---------|
| Course completion rate | > 60% | Validates content engagement |
| Certification pass rate | > 75% | Validates learning effectiveness |
| Certified trainer retention | > 85% (30-day) | Validates investment = retention |
| AI usage quality (certified vs. non) | +20% effectiveness | Validates training impact |

---

## 12. Product Roadmap

### Phase 1: MVP (Q1 2026)

**Features:**
- ✅ Trainer and client account creation with role-based views
- ✅ Basic client onboarding questionnaire
- ✅ Button/slider-based session logging (zero typing)
- ✅ AI-generated session summaries
- ✅ AI program generation with exercise reasoning
- ✅ Exercise swap feature with alternatives
- ✅ Session-time difficulty feedback and alternatives
- ✅ FitLog Life: Meal, water, sleep logging
- ✅ Real-time trainer visibility of client logs
- ✅ Push notifications

**Success Criteria:**
- 100 active trainers
- 70% trainer retention after 1 month
- Average session logging time < 60 seconds
- > 30% of AI programs customized by trainers

### Phase 2: Enhanced Features (Q2 2026)

**Features:**
- ✅ Photo-based meal logging with AI nutritional analysis
- ✅ Body photo tracking with comparison tools
- ✅ Advanced client limitation system
- ✅ Progress visualization and trends
- ✅ In-app messaging
- ✅ Exercise video library
- ✅ Wearable integration (basic)
- ✅ **FitLog Academy: Basic video courses (Modules 1-4)**

### Phase 3: Scale & Monetize (Q3-Q4 2026)

**Features:**
- ✅ Premium trainer subscription tier
- ✅ Advanced wearable integrations
- ✅ In-app client payments
- ✅ Analytics dashboard
- ✅ Gym/studio white-label option
- ✅ **FitLog Academy: Interactive quizzes + certification system**
- ✅ **Advanced courses (Modules 5-6)**

### Phase 4: Expansion (2027)

**Features:**
- ✅ Multi-language support
- ✅ Enterprise gym management
- ✅ **FitLog Academy: Mentorship program**
- ✅ **Trainer marketplace (certified trainers)**
- ✅ Community features

---

## 13. Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation Strategy |
|------|------------|--------|---------------------|
| **AI generates inappropriate workout** | Medium | High | Trainer review required; safety guardrails; clear disclaimers |
| **AI reasoning perceived as inaccurate** | Medium | Medium | Allow trainer override; continuous model improvement; feedback loop |
| **Exercise alternatives don't match context** | Medium | Medium | Movement pattern validation; trainer final approval |
| **Low client engagement with lifestyle tracking** | High | Medium | Gamification; streak rewards; trainer nudges; simplified logging |
| **Data privacy concerns** | Medium | High | SOC 2 compliance; encryption; privacy controls for clients |
| **Single app complexity** | Medium | Medium | Clean role-based separation; intuitive onboarding flow |

---

## 14. Appendix

### A. Competitive Landscape

| Competitor | Strengths | Weaknesses | Our Differentiation |
|------------|-----------|------------|---------------------|
| **Trainerize** | Established market leader | Complex UI; typing-heavy | Zero-typing; AI with reasoning |
| **TrueCoach** | Clean interface | Limited AI; no content library | AI explanations; exercise swap |
| **My PT Hub** | Affordable | Dated design; manual everything | Modern AI-first approach |

### B. Revenue Model

#### Per-Client Pricing Model

| Tier | Price | Details |
|------|-------|---------|
| **Free Trial** | ₩0 | First 3 clients free for 30 days |
| **Standard** | ₩5,000/client/month | Full features for each active client |
| **Annual Discount** | ₩50,000/client/year | 2 months free |

### C. AI Exercise Reasoning Categories

| Category | Example Reasons |
|----------|-----------------|
| **Goal Alignment** | "Optimal for lower body strength development" |
| **History-Based** | "Consistent weight progression over 4 weeks" |
| **Safety** | "Low impact on previously injured knee" |
| **Form Readiness** | "Form stability confirmed in recent sessions" |
| **Progressive Overload** | "Appropriate next step in squat progression" |
| **Recovery** | "Adequate rest since last similar movement" |

### D. Glossary

| Term | Definition |
|------|------------|
| **Exercise Swap** | Replacing an AI-recommended exercise with a trainer-selected alternative |
| **AI Reasoning** | Human-readable explanation for why AI selected an exercise |
| **Movement Pattern** | Category of similar biomechanical movements (e.g., squat pattern, hip hinge) |
| **Difficulty Feedback** | Trainer indication that client is struggling or finding exercise too easy |
| **FitLog Life** | Client-facing lifestyle tracking module within FitLog Pro |
| **Role-Based View** | UI that adapts based on user type (trainer vs. client) |
| **FitLog Academy** | Trainer education and certification program |
| **FitLog Certified** | Basic certification level for trainers who complete all courses |
| **FitLog Methodology** | Standardized program design approach taught through FitLog Academy |
| **Periodization** | Strategic planning of athletic training in progressive phases |

---

*Document Version: 1.2*  
*Last Updated: December 2025*  
*For questions or feedback, contact the Product Team*