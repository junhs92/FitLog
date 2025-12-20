# FitLog Pro - UI Design Benchmark

UI 디자인 벤치마크 및 스타일 가이드 (Nutridea 앱 기반)

---

## 1. Design Inspiration

### Source
- **Benchmark App**: Nutridea (Nutrition tracking app)
- **Design Style**: Modern, soft, friendly fitness/health UI

### Key Principles
- Clean, minimal interface with focus on data visualization
- Soft color palette with blue tones
- Rounded corners and pill-shaped buttons
- Generous whitespace for breathing room
- Gradient accents for call-to-action elements

---

## 2. Color System

### Primary Palette

| Name | Hex Code | RGB | Usage |
|------|----------|-----|-------|
| **Bright Blue** | `#2563EB` | rgb(37, 99, 235) | Primary actions, links, active states |
| **Patterns Blue** | `#DBEAFE` | rgb(219, 234, 254) | Light backgrounds, input fields |
| **Blue Chalk** | `#EEF2FF` | rgb(238, 242, 255) | Card backgrounds, hover states |
| **Midnight Blue** | `#1E3A5F` | rgb(30, 58, 95) | Headers, navigation, emphasis |
| **Black** | `#121212` | rgb(18, 18, 18) | Primary text, titles |
| **Gray** | `#787B7F` | rgb(120, 123, 127) | Secondary text, placeholders, labels |

### Gradient Definitions

```dart
// Primary Button Gradient (Orange-Yellow)
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFF59E0B), // Amber
    Color(0xFFFB923C), // Orange
  ],
)

// Background Gradient (Soft Blue)
LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFEEF2FF), // Blue Chalk
    Color(0xFFFFFFFF), // White
  ],
)
```

### Semantic Colors

| Purpose | Color | Hex Code |
|---------|-------|----------|
| Success | Green | `#22C55E` |
| Warning | Amber | `#F59E0B` |
| Error | Red | `#EF4444` |
| Info | Blue | `#2563EB` |
| Surface | White | `#FFFFFF` |
| Border | Light Gray | `#E5E7EB` |

---

## 3. Typography Scale

### Font Family
- **Primary**: SF Pro Display / Inter (system default)
- **Fallback**: -apple-system, BlinkMacSystemFont, sans-serif

### Size Hierarchy

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| **Display** | 32px | Bold (700) | 1.2 |
| **Headline** | 24px | Bold (700) | 1.3 |
| **Title** | 20px | Semibold (600) | 1.4 |
| **Subtitle** | 18px | Semibold (600) | 1.4 |
| **Body Large** | 16px | Regular (400) | 1.5 |
| **Body** | 14px | Regular (400) | 1.5 |
| **Label** | 14px | Medium (500) | 1.4 |
| **Caption** | 12px | Regular (400) | 1.4 |
| **Overline** | 10px | Medium (500) | 1.6 |

### Flutter Implementation

```dart
// Text Styles
static const TextStyle headline = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w700,
  color: Color(0xFF121212),
  height: 1.3,
);

static const TextStyle body = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: Color(0xFF121212),
  height: 1.5,
);

static const TextStyle label = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: Color(0xFF787B7F),
  height: 1.4,
);
```

---

## 4. Component Specifications

### 4.1 Buttons

#### Primary Button
```dart
// Gradient pill button
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFFB923C)],
    ),
    borderRadius: BorderRadius.circular(999),
  ),
  child: Padding(
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    child: Text(
      'Button Primary',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  ),
)
```

| Property | Value |
|----------|-------|
| Background | Gradient `#F59E0B` → `#FB923C` |
| Text Color | White `#FFFFFF` |
| Font Weight | 600 (Semibold) |
| Padding | 12px vertical, 24px horizontal |
| Border Radius | 999px (full pill) |
| Min Height | 48px |

#### Secondary Button
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: Color(0xFFE5E7EB)),
  ),
  child: Padding(
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    child: Text(
      'Button Secondary',
      style: TextStyle(
        color: Color(0xFF121212),
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
    ),
  ),
)
```

| Property | Value |
|----------|-------|
| Background | Transparent |
| Text Color | Black `#121212` |
| Font Weight | 500 (Medium) |
| Border | 1px solid `#E5E7EB` |
| Border Radius | 999px (full pill) |

### 4.2 Cards & Containers

#### Standard Card
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 20,
        offset: Offset(0, 4),
      ),
    ],
  ),
  padding: EdgeInsets.all(16),
)
```

| Property | Value |
|----------|-------|
| Background | White `#FFFFFF` |
| Border Radius | 16px |
| Shadow Blur | 20px |
| Shadow Opacity | 8% |
| Shadow Offset | (0, 4) |
| Padding | 16px |

#### Hero Card (with gradient)
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFDBEAFE), Color(0xFFEEF2FF)],
    ),
    borderRadius: BorderRadius.circular(20),
  ),
  padding: EdgeInsets.all(20),
)
```

### 4.3 Progress Indicators

#### Circular Progress (Workout/Calorie Tracker)
```dart
SizedBox(
  width: 160,
  height: 160,
  child: CircularProgressIndicator(
    value: 0.65, // 65% progress
    strokeWidth: 12,
    backgroundColor: Color(0xFFEEF2FF),
    valueColor: AlwaysStoppedAnimation(Color(0xFF2563EB)),
    strokeCap: StrokeCap.round,
  ),
)
```

| Property | Value |
|----------|-------|
| Size | 160x160px |
| Stroke Width | 12px |
| Background | Blue Chalk `#EEF2FF` |
| Progress Color | Bright Blue `#2563EB` |
| Stroke Cap | Round |

#### Linear Progress Bar
```dart
Container(
  height: 8,
  decoration: BoxDecoration(
    color: Color(0xFFEEF2FF),
    borderRadius: BorderRadius.circular(4),
  ),
  child: FractionallySizedBox(
    widthFactor: 0.65,
    child: Container(
      decoration: BoxDecoration(
        color: Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  ),
)
```

### 4.4 Input Fields

#### Text Input
```dart
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: Color(0xFFDBEAFE),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: TextStyle(color: Color(0xFF787B7F)),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
)
```

| Property | Value |
|----------|-------|
| Background | Patterns Blue `#DBEAFE` |
| Border Radius | 12px |
| Border | None |
| Padding | 14px vertical, 16px horizontal |
| Hint Color | Gray `#787B7F` |

---

## 5. Layout Patterns

### Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4px | Tight spacing, icon gaps |
| `sm` | 8px | Related elements |
| `md` | 16px | Standard spacing, card padding |
| `lg` | 24px | Section spacing |
| `xl` | 32px | Major sections |
| `xxl` | 48px | Page margins (mobile) |

### Grid System
- **Mobile**: Single column, 16px horizontal padding
- **Tablet**: 2 columns, 24px gutter
- **Desktop**: 3-4 columns, 32px gutter

### Card Arrangements

#### Dashboard Layout
```
┌─────────────────────────────────┐
│         Hero Card               │
│   (Full width, gradient bg)     │
└─────────────────────────────────┘
         ↓ 16px gap
┌─────────────────────────────────┐
│     Circular Progress Card      │
│  ┌─────┐                        │
│  │ 65% │  1057 / 2000 kcal     │
│  └─────┘                        │
└─────────────────────────────────┘
         ↓ 16px gap
┌─────────┐ ┌─────────┐ ┌─────────┐
│ Protein │ │  Carbs  │ │   Fat   │
│  57/120 │ │  89/200 │ │  32/65  │
└─────────┘ └─────────┘ └─────────┘
         ↓ 16px gap
┌─────────────────────────────────┐
│      Water Intake Chart         │
│   [Bar chart - Mon to Sun]      │
└─────────────────────────────────┘
```

---

## 6. FitLog Pro Applications

### Feature Mapping

| Benchmark Component | FitLog Pro Implementation |
|--------------------|---------------------------|
| Calorie Ring | Workout completion progress |
| Macro Breakdown | Exercise categories (Push/Pull/Legs) |
| Water Intake Chart | Hydration logging |
| Meal Cards | Lifestyle log entries |
| Smart Insights | AI session reports |

### Client Home Screen

Apply these design elements:
1. **Hero Section**: Greeting card with soft gradient background
2. **Today's Progress**: Circular progress for workout completion
3. **Quick Stats Row**: 3-column layout for key metrics
4. **Recent Activity**: Card list with meal/hydration logs
5. **AI Insights**: Summary card with weekly patterns

### Lifestyle Logging Screen

1. **Category Tabs**: Pill-shaped segmented control
2. **Log Entry Cards**: Image + info layout with rounded corners
3. **Add Button**: Floating action button with primary gradient
4. **Timeline View**: Chronological log display

### Session Summary Screen

1. **Completion Badge**: Large circular progress (100%)
2. **Stats Grid**: 2x2 grid of metric cards
3. **Exercise List**: Expandable accordion cards
4. **Share Button**: Secondary pill button

---

## 7. Flutter Implementation Reference

### Theme Data Setup

```dart
// lib/core/theme/app_theme.dart

class AppTheme {
  // Colors
  static const brightBlue = Color(0xFF2563EB);
  static const patternsBlue = Color(0xFFDBEAFE);
  static const blueChalk = Color(0xFFEEF2FF);
  static const midnightBlue = Color(0xFF1E3A5F);
  static const textPrimary = Color(0xFF121212);
  static const textSecondary = Color(0xFF787B7F);
  static const border = Color(0xFFE5E7EB);

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFB923C)],
  );

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [blueChalk, Colors.white],
  );

  // Border Radius
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 20.0;
  static const radiusFull = 999.0;

  // Shadows
  static final cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 20,
    offset: const Offset(0, 4),
  );
}
```

---

*Last Updated: 2024-12-06*
*Based on: Nutridea App UI Benchmark*
