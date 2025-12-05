# FitLog Pro Development Handoff Specification
**Version 1.0 | December 2024**

Complete technical specification for development implementation

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Technical Stack](#technical-stack)
3. [Project Structure](#project-structure)
4. [Design System Implementation](#design-system-implementation)
5. [Component Specifications](#component-specifications)
6. [Screen Implementation Guide](#screen-implementation-guide)
7. [Data Models & Schema](#data-models--schema)
8. [API Specifications](#api-specifications)
9. [State Management](#state-management)
10. [Animation Implementation](#animation-implementation)
11. [Performance Requirements](#performance-requirements)
12. [Testing Strategy](#testing-strategy)
13. [Deployment & DevOps](#deployment--devops)
14. [Quality Assurance Checklist](#quality-assurance-checklist)

---

## Executive Summary

### Purpose

This document provides developers with complete technical specifications, implementation guidelines, and quality standards for building FitLog Pro MVP. It bridges design and development, ensuring pixel-perfect implementation that meets performance and usability requirements.

### Scope

**MVP Features to Implement:**
- ✅ Trainer authentication & onboarding
- ✅ Client management (create, edit, view)
- ✅ Session logging with zero-typing UI
- ✅ AI workout generation
- ✅ FitLog Life basic tracking
- ✅ Dashboard & analytics
- ✅ FitLog Academy tier system

**Post-MVP (Not in Scope):**
- Advanced analytics
- Team/multi-trainer features
- Web dashboard
- Integration APIs
- White-label options

### Timeline

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| **Phase 1: Setup** | Week 1-2 | Project scaffold, design system, CI/CD |
| **Phase 2: Core** | Week 3-8 | Auth, client management, session logging |
| **Phase 3: AI** | Week 9-12 | AI workout generation, exercise swap |
| **Phase 4: Life** | Week 13-14 | FitLog Life tracking |
| **Phase 5: Polish** | Week 15-16 | Animations, performance, bug fixes |
| **Phase 6: Testing** | Week 17-18 | QA, beta testing, fixes |

**Total:** 18 weeks (4.5 months) to MVP launch

---

## Technical Stack

### Frontend (Mobile App)

#### Primary Framework
**React Native 0.73+**
- **Rationale:** Cross-platform (iOS/Android), mature ecosystem, fast development
- **Language:** TypeScript for type safety
- **Navigation:** React Navigation 6.x
- **State:** Redux Toolkit + RTK Query

#### Key Libraries
```json
{
  "dependencies": {
    "react": "18.2.0",
    "react-native": "0.73.0",
    "typescript": "5.3.0",
    
    "// Navigation": "",
    "@react-navigation/native": "^6.1.9",
    "@react-navigation/bottom-tabs": "^6.5.11",
    "@react-navigation/stack": "^6.3.20",
    
    "// State Management": "",
    "@reduxjs/toolkit": "^2.0.1",
    "react-redux": "^9.0.4",
    
    "// UI Components": "",
    "react-native-reanimated": "^3.6.1",
    "react-native-gesture-handler": "^2.14.1",
    "react-native-svg": "^14.1.0",
    
    "// Forms": "",
    "react-hook-form": "^7.49.2",
    "zod": "^3.22.4",
    
    "// Voice": "",
    "@react-native-voice/voice": "^3.2.4",
    
    "// Storage": "",
    "@react-native-async-storage/async-storage": "^1.21.0",
    
    "// Network": "",
    "axios": "^1.6.2",
    
    "// Analytics": "",
    "@react-native-firebase/analytics": "^18.7.3",
    
    "// Haptics": "",
    "react-native-haptic-feedback": "^2.2.0"
  },
  "devDependencies": {
    "@testing-library/react-native": "^12.4.2",
    "jest": "^29.7.0",
    "eslint": "^8.56.0",
    "prettier": "^3.1.1"
  }
}
```

---

### Backend

#### Infrastructure
**Firebase (BaaS)**
- **Authentication:** Firebase Auth (email/password, social login future)
- **Database:** Firestore (NoSQL, real-time sync)
- **Storage:** Firebase Storage (images, voice recordings)
- **Functions:** Cloud Functions for AI generation
- **Analytics:** Firebase Analytics
- **Crashlytics:** Error tracking

**Alternative Backend (If Custom):**
- **API:** Node.js + Express + TypeScript
- **Database:** PostgreSQL
- **ORM:** Prisma
- **Authentication:** JWT
- **Storage:** AWS S3
- **Hosting:** AWS or Google Cloud

---

#### AI Services
**OpenAI API (GPT-4)**
- Workout generation
- Exercise substitution suggestions
- Session summary generation
- Natural language processing for voice notes

**Implementation:**
- Cloud Function as proxy
- Prompt templates stored server-side
- Rate limiting per trainer tier
- Caching for common requests

---

### Development Tools

#### Version Control
- **Git:** GitHub or GitLab
- **Branching:** Git Flow (main, develop, feature/*, hotfix/*)
- **Commits:** Conventional Commits format

#### CI/CD
- **iOS:** Fastlane + TestFlight
- **Android:** Fastlane + Google Play Internal Testing
- **Automation:** GitHub Actions or GitLab CI

#### Design Collaboration
- **Figma:** Source of truth for designs
- **Handoff:** Zeplin or Figma Dev Mode
- **Assets:** Exported at 1x, 2x, 3x for React Native

---

## Project Structure

### Directory Organization

```
fitlog-pro/
├── src/
│   ├── assets/              # Images, fonts, icons
│   │   ├── icons/
│   │   ├── images/
│   │   └── fonts/
│   │
│   ├── components/          # Reusable UI components
│   │   ├── buttons/
│   │   │   ├── PrimaryButton.tsx
│   │   │   ├── SecondaryButton.tsx
│   │   │   └── IconButton.tsx
│   │   ├── inputs/
│   │   │   ├── TextInput.tsx
│   │   │   ├── Slider.tsx
│   │   │   └── NumberStepper.tsx
│   │   ├── cards/
│   │   ├── modals/
│   │   └── common/
│   │
│   ├── screens/             # Screen components
│   │   ├── auth/
│   │   │   ├── LoginScreen.tsx
│   │   │   ├── SignupScreen.tsx
│   │   │   └── OnboardingScreen.tsx
│   │   ├── home/
│   │   │   └── DashboardScreen.tsx
│   │   ├── clients/
│   │   │   ├── ClientListScreen.tsx
│   │   │   ├── ClientProfileScreen.tsx
│   │   │   └── AddClientScreen.tsx
│   │   ├── session/
│   │   │   ├── StartSessionScreen.tsx
│   │   │   ├── ActiveSessionScreen.tsx
│   │   │   └── SessionSummaryScreen.tsx
│   │   └── settings/
│   │
│   ├── navigation/          # Navigation configuration
│   │   ├── AppNavigator.tsx
│   │   ├── AuthNavigator.tsx
│   │   └── MainNavigator.tsx
│   │
│   ├── store/               # Redux store
│   │   ├── index.ts
│   │   ├── slices/
│   │   │   ├── authSlice.ts
│   │   │   ├── clientsSlice.ts
│   │   │   ├── sessionsSlice.ts
│   │   │   └── workoutsSlice.ts
│   │   └── api/
│   │       └── apiSlice.ts  # RTK Query
│   │
│   ├── services/            # Business logic
│   │   ├── authService.ts
│   │   ├── clientService.ts
│   │   ├── sessionService.ts
│   │   ├── aiService.ts
│   │   └── voiceService.ts
│   │
│   ├── utils/               # Utility functions
│   │   ├── validation.ts
│   │   ├── formatting.ts
│   │   ├── haptics.ts
│   │   └── constants.ts
│   │
│   ├── hooks/               # Custom React hooks
│   │   ├── useAuth.ts
│   │   ├── useVoice.ts
│   │   └── useDebounce.ts
│   │
│   ├── types/               # TypeScript types
│   │   ├── models.ts
│   │   ├── api.ts
│   │   └── navigation.ts
│   │
│   ├── theme/               # Design system tokens
│   │   ├── colors.ts
│   │   ├── typography.ts
│   │   ├── spacing.ts
│   │   └── shadows.ts
│   │
│   └── config/              # App configuration
│       ├── firebase.ts
│       └── env.ts
│
├── __tests__/               # Test files
├── ios/                     # iOS native code
├── android/                 # Android native code
├── .github/                 # CI/CD workflows
├── package.json
├── tsconfig.json
└── README.md
```

---

## Design System Implementation

### Design Tokens

#### colors.ts
```typescript
export const colors = {
  // Brand
  brand: {
    primary: '#2E5C8A',
    secondary: '#4A7BA7',
    light: '#D5E8F0',
  },
  
  // Semantic
  success: {
    700: '#0F6634',
    600: '#16A34A',
    500: '#22C55E',
    100: '#DCFCE7',
  },
  warning: {
    700: '#C2410C',
    600: '#EA580C',
    500: '#F97316',
    100: '#FFEDD5',
  },
  error: {
    700: '#B91C1C',
    600: '#DC2626',
    500: '#EF4444',
    100: '#FEE2E2',
  },
  
  // Neutrals
  gray: {
    900: '#111827',
    700: '#374151',
    500: '#6B7280',
    400: '#9CA3AF',
    300: '#D1D5DB',
    200: '#E5E7EB',
    100: '#F3F4F6',
    50: '#F9FAFB',
  },
  
  white: '#FFFFFF',
  black: '#000000',
  
  // Academy Tiers
  bronze: '#CD7F32',
  silver: '#C0C0C0',
  gold: '#FFD700',
};
```

#### typography.ts
```typescript
export const typography = {
  fontFamily: {
    ios: 'SF Pro',
    android: 'Roboto',
  },
  
  fontSizes: {
    display1: 56,
    display2: 48,
    h1: 32,
    h2: 28,
    h3: 24,
    h4: 20,
    bodyLarge: 18,
    body: 16,
    bodySmall: 14,
    labelLarge: 16,
    label: 14,
    labelSmall: 12,
    caption: 12,
    overline: 10,
  },
  
  fontWeights: {
    regular: '400',
    medium: '500',
    semibold: '600',
    bold: '700',
  },
  
  lineHeights: {
    display1: 64,
    display2: 56,
    h1: 40,
    h2: 36,
    h3: 32,
    h4: 28,
    bodyLarge: 28,
    body: 24,
    bodySmall: 20,
    labelLarge: 24,
    label: 20,
    labelSmall: 16,
    caption: 16,
    overline: 16,
  },
};
```

#### spacing.ts
```typescript
export const spacing = {
  1: 4,
  2: 8,
  3: 12,
  4: 16,
  5: 24,
  6: 32,
  7: 40,
  8: 48,
  9: 64,
  10: 80,
};
```

#### shadows.ts
```typescript
export const shadows = {
  level0: {
    shadowColor: 'transparent',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0,
    shadowRadius: 0,
    elevation: 0,
  },
  level1: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.12,
    shadowRadius: 3,
    elevation: 1,
  },
  level2: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.12,
    shadowRadius: 8,
    elevation: 4,
  },
  level3: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.15,
    shadowRadius: 16,
    elevation: 8,
  },
  level4: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 12 },
    shadowOpacity: 0.18,
    shadowRadius: 24,
    elevation: 12,
  },
};
```

---

## Component Specifications

### Button Components

#### PrimaryButton.tsx
```typescript
import React from 'react';
import { 
  TouchableOpacity, 
  Text, 
  StyleSheet, 
  ActivityIndicator,
  ViewStyle,
  TextStyle 
} from 'react-native';
import { colors, typography, spacing, shadows } from '@/theme';

interface PrimaryButtonProps {
  label: string;
  onPress: () => void;
  loading?: boolean;
  disabled?: boolean;
  fullWidth?: boolean;
  style?: ViewStyle;
  textStyle?: TextStyle;
}

export const PrimaryButton: React.FC<PrimaryButtonProps> = ({
  label,
  onPress,
  loading = false,
  disabled = false,
  fullWidth = false,
  style,
  textStyle,
}) => {
  return (
    <TouchableOpacity
      style={[
        styles.button,
        fullWidth && styles.fullWidth,
        disabled && styles.disabled,
        style,
      ]}
      onPress={onPress}
      disabled={disabled || loading}
      activeOpacity={0.7}
    >
      {loading ? (
        <ActivityIndicator color={colors.white} />
      ) : (
        <Text style={[styles.text, textStyle]}>{label}</Text>
      )}
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  button: {
    height: 56,
    paddingHorizontal: spacing[5],
    backgroundColor: colors.brand.primary,
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
    ...shadows.level1,
  },
  fullWidth: {
    width: '100%',
  },
  disabled: {
    backgroundColor: colors.gray[300],
    ...shadows.level0,
  },
  text: {
    color: colors.white,
    fontSize: typography.fontSizes.labelLarge,
    fontWeight: typography.fontWeights.medium,
    letterSpacing: 0,
  },
});
```

**Usage:**
```typescript
<PrimaryButton 
  label="Continue" 
  onPress={handleContinue}
  fullWidth
/>

<PrimaryButton 
  label="Saving..." 
  onPress={handleSave}
  loading={isSaving}
/>
```

---

#### SessionLoggingButton.tsx
```typescript
// Larger touch target for workout logging
import React from 'react';
import { 
  TouchableOpacity, 
  Text, 
  StyleSheet,
  Vibration 
} from 'react-native';
import { colors, typography, spacing } from '@/theme';
import HapticFeedback from 'react-native-haptic-feedback';

interface SessionLoggingButtonProps {
  label: string;
  onPress: () => void;
  variant?: 'primary' | 'success';
}

export const SessionLoggingButton: React.FC<SessionLoggingButtonProps> = ({
  label,
  onPress,
  variant = 'primary',
}) => {
  const handlePress = () => {
    HapticFeedback.trigger('impactMedium');
    onPress();
  };

  return (
    <TouchableOpacity
      style={[
        styles.button,
        variant === 'success' && styles.success,
      ]}
      onPress={handlePress}
      activeOpacity={0.7}
    >
      <Text style={styles.text}>{label}</Text>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  button: {
    height: 72, // Extra large for workout use
    width: '100%',
    backgroundColor: colors.brand.primary,
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
  },
  success: {
    backgroundColor: colors.success[600],
  },
  text: {
    color: colors.white,
    fontSize: 20, // Larger text
    fontWeight: typography.fontWeights.bold,
  },
});
```

---

### Input Components

#### CustomSlider.tsx
```typescript
import React, { useState } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Slider from '@react-native-community/slider';
import { colors, typography, spacing } from '@/theme';
import HapticFeedback from 'react-native-haptic-feedback';

interface CustomSliderProps {
  value: number;
  min: number;
  max: number;
  step: number;
  onChange: (value: number) => void;
  unit?: string;
  label?: string;
  showValue?: boolean;
}

export const CustomSlider: React.FC<CustomSliderProps> = ({
  value,
  min,
  max,
  step,
  onChange,
  unit = '',
  label,
  showValue = true,
}) => {
  const [hapticValue, setHapticValue] = useState(value);

  const handleValueChange = (newValue: number) => {
    // Trigger haptic every step
    if (Math.abs(newValue - hapticValue) >= step) {
      HapticFeedback.trigger('selection');
      setHapticValue(newValue);
    }
    onChange(newValue);
  };

  return (
    <View style={styles.container}>
      {label && <Text style={styles.label}>{label}</Text>}
      
      <View style={styles.sliderContainer}>
        <Slider
          value={value}
          minimumValue={min}
          maximumValue={max}
          step={step}
          onValueChange={handleValueChange}
          minimumTrackTintColor={colors.brand.primary}
          maximumTrackTintColor={colors.gray[200]}
          thumbTintColor={colors.white}
          style={styles.slider}
        />
      </View>
      
      {showValue && (
        <Text style={styles.value}>
          {value}{unit}
        </Text>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  label: {
    fontSize: typography.fontSizes.label,
    fontWeight: typography.fontWeights.medium,
    color: colors.gray[900],
    marginBottom: spacing[2],
  },
  sliderContainer: {
    paddingHorizontal: spacing[2],
  },
  slider: {
    height: 40,
  },
  value: {
    fontSize: typography.fontSizes.h3,
    fontWeight: typography.fontWeights.bold,
    color: colors.brand.primary,
    textAlign: 'center',
    marginTop: spacing[2],
  },
});
```

---

### Screen Components

#### ActiveSessionScreen.tsx (Simplified Example)
```typescript
import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { useDispatch, useSelector } from 'react-redux';
import { CustomSlider } from '@/components/inputs/CustomSlider';
import { NumberStepper } from '@/components/inputs/NumberStepper';
import { SessionLoggingButton } from '@/components/buttons/SessionLoggingButton';
import { logSet } from '@/store/slices/sessionsSlice';
import { colors, spacing, typography } from '@/theme';

export const ActiveSessionScreen: React.FC = () => {
  const dispatch = useDispatch();
  const { currentExercise, lastPerformance } = useSelector(
    state => state.sessions
  );
  
  // Local state for current set
  const [weight, setWeight] = useState(lastPerformance?.weight || 60);
  const [reps, setReps] = useState(lastPerformance?.reps || 10);
  const [effort, setEffort] = useState(5);
  
  // Auto-fill from last performance
  useEffect(() => {
    if (lastPerformance) {
      setWeight(lastPerformance.weight);
      setReps(lastPerformance.reps);
    }
  }, [lastPerformance]);
  
  const handleLogSet = () => {
    dispatch(logSet({
      exerciseId: currentExercise.id,
      weight,
      reps,
      effort,
      timestamp: Date.now(),
    }));
    
    // Show success feedback
    // Auto-advance to next set or exercise
  };
  
  return (
    <View style={styles.container}>
      {/* Timer Header */}
      <View style={styles.header}>
        <Text style={styles.timer}>12:34</Text>
      </View>
      
      {/* Exercise Info */}
      <View style={styles.exerciseInfo}>
        <Text style={styles.exerciseName}>
          {currentExercise.name}
        </Text>
        <Text style={styles.lastPerformance}>
          Last: {lastPerformance?.weight}kg × {lastPerformance?.reps} reps
        </Text>
      </View>
      
      {/* Weight Input */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Weight</Text>
        <CustomSlider
          value={weight}
          min={0}
          max={200}
          step={2.5}
          onChange={setWeight}
          unit="kg"
          showValue
        />
      </View>
      
      {/* Reps Input */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Reps</Text>
        <NumberStepper
          value={reps}
          min={1}
          max={50}
          onChange={setReps}
        />
      </View>
      
      {/* Effort Slider (Optional) */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Effort (Optional)</Text>
        <CustomSlider
          value={effort}
          min={1}
          max={10}
          step={1}
          onChange={setEffort}
          unit="/10"
        />
      </View>
      
      {/* Log Set Button */}
      <SessionLoggingButton
        label="Log Set"
        onPress={handleLogSet}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.white,
    padding: spacing[5],
  },
  header: {
    alignItems: 'center',
    paddingVertical: spacing[4],
  },
  timer: {
    fontSize: typography.fontSizes.h2,
    fontWeight: typography.fontWeights.bold,
    color: colors.brand.primary,
  },
  exerciseInfo: {
    alignItems: 'center',
    marginBottom: spacing[6],
  },
  exerciseName: {
    fontSize: typography.fontSizes.h2,
    fontWeight: typography.fontWeights.bold,
    color: colors.gray[900],
    marginBottom: spacing[2],
  },
  lastPerformance: {
    fontSize: typography.fontSizes.body,
    color: colors.gray[500],
  },
  section: {
    marginBottom: spacing[6],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.h4,
    fontWeight: typography.fontWeights.semibold,
    color: colors.gray[900],
    marginBottom: spacing[3],
  },
});
```

---

## Data Models & Schema

### TypeScript Models

#### models.ts
```typescript
// User/Trainer
export interface Trainer {
  id: string;
  email: string;
  name: string;
  profilePhoto?: string;
  experience: 'beginner' | 'intermediate' | 'advanced';
  certifications: string[];
  specializations: string[];
  academyTier: 'bronze' | 'silver' | 'gold';
  createdAt: number;
  updatedAt: number;
}

// Client
export interface Client {
  id: string;
  trainerId: string;
  name: string;
  preferredName?: string;
  email?: string;
  phone?: string;
  dateOfBirth?: string;
  gender?: 'male' | 'female' | 'other' | 'prefer-not-to-say';
  photo?: string;
  
  // Physical
  height?: number; // cm
  weight?: number; // kg
  goalWeight?: number; // kg
  bodyFat?: number; // percentage
  
  // Goals
  primaryGoal: 'weight-loss' | 'muscle-gain' | 'strength' | 'endurance' | 'rehab' | 'general';
  secondaryGoals?: string[];
  
  // Health
  limitations: Limitation[];
  medications?: string[];
  medicalConditions?: string[];
  
  // Status
  status: 'active' | 'inactive' | 'paused';
  
  createdAt: number;
  updatedAt: number;
}

// Limitation
export interface Limitation {
  id: string;
  category: 'injury' | 'pain' | 'condition' | 'mobility';
  bodyPart: string;
  symptom: string;
  severity: number; // 1-10
  duration: 'acute' | 'chronic' | 'past';
  notes?: string;
  createdAt: number;
}

// Exercise
export interface Exercise {
  id: string;
  name: string;
  nameKR?: string;
  category: 'strength' | 'cardio' | 'flexibility' | 'balance';
  muscleGroups: string[];
  equipment: string[];
  difficulty: 'beginner' | 'intermediate' | 'advanced';
  instructions: string;
  videoUrl?: string;
  thumbnailUrl?: string;
  contraindications: string[]; // Body parts/conditions to avoid
  alternatives?: string[]; // Alternative exercise IDs
}

// Workout Program
export interface WorkoutProgram {
  id: string;
  clientId: string;
  trainerId: string;
  name: string;
  duration: number; // weeks
  sessionsPerWeek: number;
  sessionLength: number; // minutes
  focus: string[];
  split: 'full-body' | 'upper-lower' | 'ppl' | 'custom';
  weeks: Week[];
  aiGenerated: boolean;
  aiRationale?: string;
  status: 'active' | 'completed' | 'paused';
  createdAt: number;
  updatedAt: number;
}

// Week
export interface Week {
  weekNumber: number;
  days: WorkoutDay[];
}

// Workout Day
export interface WorkoutDay {
  dayNumber: number;
  name: string;
  exercises: ProgrammedExercise[];
}

// Programmed Exercise
export interface ProgrammedExercise {
  exerciseId: string;
  sets: number;
  reps: number | string; // "10" or "8-12" or "AMRAP"
  restSeconds: number;
  tempo?: string; // e.g., "3-1-1-0"
  notes?: string;
  aiNotes?: string; // AI explanation for this exercise
}

// Training Session
export interface TrainingSession {
  id: string;
  clientId: string;
  trainerId: string;
  programId?: string;
  workoutDayId?: string;
  sessionType: 'workout' | 'assessment' | 'consultation';
  startTime: number;
  endTime?: number;
  duration?: number; // minutes
  exercises: LoggedExercise[];
  notes?: string;
  voiceNotes?: VoiceNote[];
  aiSummary?: string;
  status: 'active' | 'completed' | 'cancelled';
  createdAt: number;
  updatedAt: number;
}

// Logged Exercise
export interface LoggedExercise {
  exerciseId: string;
  sets: LoggedSet[];
  notes?: string;
}

// Logged Set
export interface LoggedSet {
  setNumber: number;
  weight: number; // kg
  reps: number;
  effort?: number; // RPE 1-10
  timestamp: number;
}

// Voice Note
export interface VoiceNote {
  id: string;
  audioUrl: string;
  transcription?: string;
  duration: number; // seconds
  timestamp: number;
}

// FitLog Life Entry
export interface FitLogLifeEntry {
  id: string;
  clientId: string;
  date: string; // YYYY-MM-DD
  
  // Sleep
  sleepHours?: number;
  sleepQuality?: number; // 1-5
  
  // Nutrition
  meals?: number;
  waterIntake?: number; // liters
  caloriesApprox?: 'low' | 'normal' | 'high';
  
  // Stress & Recovery
  stressLevel?: number; // 1-5
  energy?: number; // 1-5
  soreness?: number; // 1-5
  
  // Notes
  notes?: string;
  
  createdAt: number;
}

// FitLog Academy
export interface AcademyCertification {
  trainerId: string;
  tier: 'bronze' | 'silver' | 'gold';
  modules: ModuleProgress[];
  certificationDate?: number;
}

export interface ModuleProgress {
  moduleId: string;
  completed: boolean;
  score?: number;
  completedAt?: number;
}
```

---

### Firestore Schema

```
/trainers/{trainerId}
  - id: string
  - email: string
  - name: string
  - profilePhoto: string
  - experience: string
  - certifications: array
  - specializations: array
  - academyTier: string
  - createdAt: timestamp
  - updatedAt: timestamp

/clients/{clientId}
  - id: string
  - trainerId: string
  - name: string
  - ... (all Client fields)
  - createdAt: timestamp
  - updatedAt: timestamp

/exercises/{exerciseId}
  - id: string
  - name: string
  - category: string
  - muscleGroups: array
  - equipment: array
  - difficulty: string
  - instructions: string
  - videoUrl: string
  - contraindications: array

/programs/{programId}
  - id: string
  - clientId: string
  - trainerId: string
  - name: string
  - duration: number
  - ... (all WorkoutProgram fields)
  - createdAt: timestamp
  - updatedAt: timestamp

/sessions/{sessionId}
  - id: string
  - clientId: string
  - trainerId: string
  - sessionType: string
  - startTime: timestamp
  - endTime: timestamp
  - exercises: array
  - ... (all TrainingSession fields)
  - createdAt: timestamp
  - updatedAt: timestamp

/fitlogLife/{clientId}/entries/{date}
  - date: string
  - sleepHours: number
  - sleepQuality: number
  - ... (all FitLogLifeEntry fields)
  - createdAt: timestamp

/academy/{trainerId}
  - tier: string
  - modules: array
  - certificationDate: timestamp
```

**Firestore Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Trainers can only read/write their own data
    match /trainers/{trainerId} {
      allow read, write: if request.auth.uid == trainerId;
    }
    
    // Trainers can only access their own clients
    match /clients/{clientId} {
      allow read, write: if request.auth.uid == resource.data.trainerId;
      allow create: if request.auth.uid == request.resource.data.trainerId;
    }
    
    // Trainers can only access their own sessions
    match /sessions/{sessionId} {
      allow read, write: if request.auth.uid == resource.data.trainerId;
      allow create: if request.auth.uid == request.resource.data.trainerId;
    }
    
    // Exercise library is read-only for all authenticated users
    match /exercises/{exerciseId} {
      allow read: if request.auth != null;
      allow write: if false; // Only admins via backend
    }
    
    // Programs accessible by trainer who owns the client
    match /programs/{programId} {
      allow read, write: if request.auth.uid == resource.data.trainerId;
      allow create: if request.auth.uid == request.resource.data.trainerId;
    }
  }
}
```

---

## API Specifications

### REST API Endpoints (If Custom Backend)

#### Authentication
```
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/logout
POST /api/v1/auth/refresh
POST /api/v1/auth/reset-password
```

#### Trainers
```
GET    /api/v1/trainers/me
PUT    /api/v1/trainers/me
DELETE /api/v1/trainers/me
```

#### Clients
```
GET    /api/v1/clients              # List trainer's clients
POST   /api/v1/clients              # Create client
GET    /api/v1/clients/:id          # Get client details
PUT    /api/v1/clients/:id          # Update client
DELETE /api/v1/clients/:id          # Delete client
```

#### Sessions
```
GET    /api/v1/sessions                    # List sessions (with filters)
POST   /api/v1/sessions                    # Create session
GET    /api/v1/sessions/:id                # Get session details
PUT    /api/v1/sessions/:id                # Update session
DELETE /api/v1/sessions/:id                # Delete session
POST   /api/v1/sessions/:id/complete       # Mark complete
GET    /api/v1/sessions/:id/summary        # Get AI summary
```

#### AI Workout Generation
```
POST   /api/v1/ai/generate-workout
POST   /api/v1/ai/suggest-alternatives
POST   /api/v1/ai/summarize-session
```

#### Exercises
```
GET    /api/v1/exercises              # List exercises (with filters)
GET    /api/v1/exercises/:id          # Get exercise details
GET    /api/v1/exercises/search       # Search exercises
```

#### FitLog Life
```
GET    /api/v1/clients/:id/fitlog-life           # Get entries
POST   /api/v1/clients/:id/fitlog-life           # Create entry
PUT    /api/v1/clients/:id/fitlog-life/:date     # Update entry
GET    /api/v1/clients/:id/fitlog-life/insights  # Get insights
```

---

### AI Cloud Function

#### generateWorkout
```typescript
// Cloud Function: generateWorkout
export const generateWorkout = functions.https.onCall(async (data, context) => {
  // Authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }
  
  const trainerId = context.auth.uid;
  
  // Check tier permissions
  const trainer = await getTrainer(trainerId);
  if (trainer.academyTier === 'bronze') {
    const usage = await getMonthlyAIUsage(trainerId);
    if (usage >= 1) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Monthly AI generation limit reached. Upgrade to Silver for unlimited.'
      );
    }
  }
  
  // Get client data
  const client = await getClient(data.clientId);
  
  // Verify ownership
  if (client.trainerId !== trainerId) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Not authorized to access this client'
    );
  }
  
  // Build prompt
  const prompt = buildWorkoutPrompt({
    client,
    duration: data.duration,
    sessionsPerWeek: data.sessionsPerWeek,
    sessionLength: data.sessionLength,
    focus: data.focus,
    split: data.split,
  });
  
  // Call OpenAI
  const response = await openai.chat.completions.create({
    model: 'gpt-4-turbo-preview',
    messages: [
      { role: 'system', content: SYSTEM_PROMPT },
      { role: 'user', content: prompt },
    ],
    response_format: { type: 'json_object' },
    temperature: 0.7,
  });
  
  const workout = JSON.parse(response.choices[0].message.content);
  
  // Validate against client limitations
  const validatedWorkout = await validateSafety(workout, client.limitations);
  
  // Increment usage counter
  await incrementAIUsage(trainerId);
  
  // Return workout
  return validatedWorkout;
});
```

---

## State Management

### Redux Store Structure

```typescript
{
  auth: {
    user: Trainer | null,
    token: string | null,
    loading: boolean,
    error: string | null,
  },
  
  clients: {
    list: Client[],
    selected: Client | null,
    loading: boolean,
    error: string | null,
  },
  
  sessions: {
    active: TrainingSession | null,
    currentExercise: LoggedExercise | null,
    history: TrainingSession[],
    loading: boolean,
    error: string | null,
  },
  
  programs: {
    list: WorkoutProgram[],
    selected: WorkoutProgram | null,
    generating: boolean,
    error: string | null,
  },
  
  exercises: {
    library: Exercise[],
    filtered: Exercise[],
    filters: {
      category: string[],
      equipment: string[],
      muscleGroup: string[],
    },
  },
  
  fitlogLife: {
    entries: { [date: string]: FitLogLifeEntry },
    insights: any,
    loading: boolean,
  },
  
  ui: {
    theme: 'light' | 'dark',
    units: 'metric' | 'imperial',
    language: 'en' | 'kr',
    bottomSheetOpen: boolean,
  },
}
```

---

## Animation Implementation

### React Native Reanimated 3

#### Button Press Animation
```typescript
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
} from 'react-native-reanimated';

const AnimatedButton = ({ children, onPress }) => {
  const scale = useSharedValue(1);
  const opacity = useSharedValue(1);
  
  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
    opacity: opacity.value,
  }));
  
  const handlePressIn = () => {
    scale.value = withTiming(0.95, { duration: 50 });
    opacity.value = withTiming(0.9, { duration: 50 });
  };
  
  const handlePressOut = () => {
    scale.value = withSpring(1, { damping: 10, stiffness: 200 });
    opacity.value = withTiming(1, { duration: 100 });
  };
  
  return (
    <Animated.View style={animatedStyle}>
      <TouchableOpacity
        onPressIn={handlePressIn}
        onPressOut={handlePressOut}
        onPress={onPress}
      >
        {children}
      </TouchableOpacity>
    </Animated.View>
  );
};
```

#### Screen Transition
```typescript
// In navigation config
const screenOptions = {
  gestureEnabled: true,
  gestureDirection: 'horizontal',
  cardStyleInterpolator: ({ current, layouts }) => {
    return {
      cardStyle: {
        transform: [
          {
            translateX: current.progress.interpolate({
              inputRange: [0, 1],
              outputRange: [layouts.screen.width, 0],
            }),
          },
        ],
      },
      overlayStyle: {
        opacity: current.progress.interpolate({
          inputRange: [0, 1],
          outputRange: [0, 0.3],
        }),
      },
    };
  },
};
```

---

## Performance Requirements

### Target Metrics

| Metric | Target | Critical Threshold |
|--------|--------|-------------------|
| **App Launch Time** | <2 seconds | <3 seconds |
| **Screen Transition** | <300ms | <500ms |
| **API Response** | <500ms | <1 second |
| **Session Log Set** | <100ms | <200ms |
| **AI Generation** | <5 seconds | <10 seconds |
| **Frame Rate** | 60 FPS | >50 FPS |
| **Memory Usage** | <150 MB | <200 MB |
| **Battery Drain** | <5%/hour | <8%/hour |

### Optimization Strategies

#### Code Splitting
```typescript
// Lazy load screens
const ClientProfileScreen = React.lazy(() => 
  import('./screens/clients/ClientProfileScreen')
);

// Use React Suspense
<Suspense fallback={<LoadingScreen />}>
  <ClientProfileScreen />
</Suspense>
```

#### Memoization
```typescript
// Memoize expensive calculations
const clientStats = useMemo(() => 
  calculateClientStats(sessions),
  [sessions]
);

// Memoize components
const ClientCard = React.memo(({ client }) => {
  return <View>...</View>;
});
```

#### Image Optimization
```typescript
// Use FastImage for better caching
import FastImage from 'react-native-fast-image';

<FastImage
  source={{ uri: client.photo, priority: FastImage.priority.normal }}
  style={{ width: 100, height: 100 }}
  resizeMode={FastImage.resizeMode.cover}
/>
```

#### List Optimization
```typescript
// Use FlatList with optimizations
<FlatList
  data={clients}
  renderItem={renderClientCard}
  keyExtractor={item => item.id}
  initialNumToRender={10}
  maxToRenderPerBatch={10}
  windowSize={21}
  removeClippedSubviews={true}
  getItemLayout={(data, index) => ({
    length: ITEM_HEIGHT,
    offset: ITEM_HEIGHT * index,
    index,
  })}
/>
```

---

## Testing Strategy

### Unit Tests (Jest)
```typescript
// Example: Test button component
import { render, fireEvent } from '@testing-library/react-native';
import { PrimaryButton } from '@/components/buttons/PrimaryButton';

describe('PrimaryButton', () => {
  it('renders correctly', () => {
    const { getByText } = render(
      <PrimaryButton label="Test Button" onPress={() => {}} />
    );
    expect(getByText('Test Button')).toBeTruthy();
  });
  
  it('calls onPress when pressed', () => {
    const mockOnPress = jest.fn();
    const { getByText } = render(
      <PrimaryButton label="Test Button" onPress={mockOnPress} />
    );
    fireEvent.press(getByText('Test Button'));
    expect(mockOnPress).toHaveBeenCalledTimes(1);
  });
  
  it('shows loading state', () => {
    const { getByTestId } = render(
      <PrimaryButton label="Test" onPress={() => {}} loading />
    );
    expect(getByTestId('activity-indicator')).toBeTruthy();
  });
  
  it('disables when disabled prop is true', () => {
    const mockOnPress = jest.fn();
    const { getByText } = render(
      <PrimaryButton label="Test" onPress={mockOnPress} disabled />
    );
    fireEvent.press(getByText('Test'));
    expect(mockOnPress).not.toHaveBeenCalled();
  });
});
```

### Integration Tests (Detox)
```typescript
// Example: Test session logging flow
describe('Session Logging', () => {
  beforeEach(async () => {
    await device.reloadReactNative();
  });
  
  it('should log a complete workout', async () => {
    // Start session
    await element(by.id('start-session-button')).tap();
    
    // Select client
    await element(by.id('client-jane-kim')).tap();
    
    // Choose workout type
    await element(by.id('session-type-workout')).tap();
    
    // Log first set
    await element(by.id('weight-slider')).swipe('right', 'slow', 0.5);
    await element(by.id('reps-stepper-plus')).tap();
    await element(by.id('log-set-button')).tap();
    
    // Verify set logged
    await expect(element(by.id('set-1-logged'))).toBeVisible();
    
    // Finish session
    await element(by.id('finish-session-button')).tap();
    
    // Verify summary
    await expect(element(by.id('session-summary'))).toBeVisible();
  });
});
```

### Test Coverage Goals
- **Unit Tests:** 80%+ coverage
- **Integration Tests:** Cover all critical user flows
- **E2E Tests:** Cover happy paths for main features

---

## Deployment & DevOps

### CI/CD Pipeline

#### GitHub Actions Workflow
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run linter
        run: npm run lint
      
      - name: Run tests
        run: npm test -- --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
  
  build-ios:
    needs: test
    runs-on: macos-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      
      - name: Install dependencies
        run: npm ci
      
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.0'
      
      - name: Install Fastlane
        run: gem install fastlane
      
      - name: Build & Deploy to TestFlight
        run: fastlane ios beta
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          FASTLANE_PASSWORD: ${{ secrets.FASTLANE_PASSWORD }}
  
  build-android:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      
      - name: Install dependencies
        run: npm ci
      
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.0'
      
      - name: Install Fastlane
        run: gem install fastlane
      
      - name: Build & Deploy to Internal Testing
        run: fastlane android beta
        env:
          ANDROID_KEYSTORE: ${{ secrets.ANDROID_KEYSTORE }}
          ANDROID_KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
```

---

### Environment Configuration

#### .env.development
```
API_URL=https://dev-api.fitlogpro.com
FIREBASE_API_KEY=xxx
FIREBASE_AUTH_DOMAIN=fitlogpro-dev.firebaseapp.com
FIREBASE_PROJECT_ID=fitlogpro-dev
OPENAI_API_KEY=xxx
SENTRY_DSN=xxx
```

#### .env.production
```
API_URL=https://api.fitlogpro.com
FIREBASE_API_KEY=xxx
FIREBASE_AUTH_DOMAIN=fitlogpro.firebaseapp.com
FIREBASE_PROJECT_ID=fitlogpro-production
OPENAI_API_KEY=xxx
SENTRY_DSN=xxx
```

---

## Quality Assurance Checklist

### Pre-Launch Checklist

#### Design Implementation
- [ ] All screens match Figma designs (pixel-perfect within 2px tolerance)
- [ ] All colors use design tokens from theme
- [ ] All typography uses design system styles
- [ ] All spacing uses 8pt grid
- [ ] All touch targets meet minimum size (44×44pt, 72×72pt for session logging)
- [ ] All animations match specifications (timing, easing)
- [ ] All icons are correct size and style
- [ ] Dark mode support (if applicable)

#### Functionality
- [ ] All user flows work end-to-end
- [ ] Session logging completes in <10 seconds per set
- [ ] AI workout generation works and respects limitations
- [ ] Voice input records and transcribes accurately
- [ ] Offline mode saves data locally
- [ ] Data syncs when back online
- [ ] FitLog Academy tier restrictions enforced
- [ ] All forms validate correctly
- [ ] Error states display properly
- [ ] Success states display properly
- [ ] Empty states display properly

#### Performance
- [ ] App launches in <2 seconds
- [ ] Screen transitions in <300ms
- [ ] No dropped frames during animations (60 FPS)
- [ ] Memory usage <150 MB
- [ ] API responses <500ms
- [ ] Images load quickly with placeholders
- [ ] Lists scroll smoothly (FlatList optimized)

#### Accessibility
- [ ] VoiceOver/TalkBack support complete
- [ ] All interactive elements have labels
- [ ] Color contrast meets WCAG AA (4.5:1)
- [ ] Touch targets meet minimum size
- [ ] Reduced motion alternative works
- [ ] Text scales with system font size
- [ ] Focus order is logical

#### Security
- [ ] Authentication required for all protected routes
- [ ] API tokens stored securely
- [ ] Sensitive data encrypted at rest
- [ ] HTTPS only for all network requests
- [ ] User input sanitized
- [ ] SQL injection protection (if applicable)
- [ ] XSS protection
- [ ] Rate limiting implemented

#### Data & Privacy
- [ ] Privacy policy implemented
- [ ] Terms of service implemented
- [ ] Data export functionality works
- [ ] Account deletion works (cascades properly)
- [ ] User consent collected where required
- [ ] Analytics tracking implemented
- [ ] Crash reporting enabled

#### Cross-Platform
- [ ] iOS build successful
- [ ] Android build successful
- [ ] Tested on iPhone (12, 13, 14 Pro, 15)
- [ ] Tested on Android (Samsung, Pixel, OnePlus)
- [ ] Safe areas respected (notch, home indicator)
- [ ] Platform-specific features work (haptics, etc.)

#### Testing
- [ ] Unit tests passing (80%+ coverage)
- [ ] Integration tests passing
- [ ] E2E tests passing for critical flows
- [ ] Manual QA completed
- [ ] Beta testing completed (8-10 trainers)
- [ ] Usability testing results addressed

#### App Store Preparation
- [ ] App icons created (all sizes)
- [ ] Screenshots created (iOS & Android)
- [ ] App Store description written
- [ ] Keywords optimized
- [ ] Privacy nutrition label completed
- [ ] App Store review guidelines checked
- [ ] Age rating determined
- [ ] In-app purchases configured (if applicable)

---

## Conclusion

This development handoff specification provides a complete blueprint for implementing FitLog Pro MVP. By following these specifications, the development team can build a high-quality, performant, and user-friendly application that meets all design and business requirements.

**Key Success Factors:**
- Adhere to design system religiously
- Prioritize session logging performance (<10s per set)
- Implement robust error handling and offline support
- Test thoroughly across devices and scenarios
- Launch with confidence knowing all requirements are met

**Next Steps:**
1. Review this document with full development team
2. Set up project scaffold and development environment
3. Implement design system and core components
4. Build features incrementally following timeline
5. Test continuously throughout development
6. Launch beta, gather feedback, iterate
7. Launch MVP to App Store and Google Play

---

**Document prepared for FitLog Pro development team**  
*Last updated: December 2024*