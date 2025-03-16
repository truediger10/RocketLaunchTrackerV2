# Rocket Launch Tracker - Style Guide (Grok-Inspired)

## Overview
This style guide defines the design system for the RocketLaunchTrackerV2 app, inspired by the Grok 3 app’s sleek, minimalist, and dark aesthetic. It emphasizes pure black backgrounds, glassmorphic UI elements, subtle gradients, and a modern typographic system.

## Color System

### Base Colors
- **baseBackground**: Pure black (`#000000`)
- **deepBackground**: Deep black (`#0A0A0A`)
- **cardSurface**: Semi-transparent dark gray (`#1A1A1A`, 85% opacity)
- **elevatedSurface**: Slightly lighter semi-transparent gray (`#212121`, 90% opacity)
- **divider**: Subtle gray with low opacity (`#3A3A3A`, 20% opacity)

### Text Colors
- **textPrimary**: White (`#FFFFFF`)
- **textSecondary**: Light gray (`#A0A0A0`) for subtle text (e.g., "beta")
- **textTertiary**: Medium gray (`#777777`)
- **textDisabled**: Darker gray (`#505050`)

### Accent Colors
- **highlightAccent**: Vibrant blue (`#00AEEF`) for primary highlights (e.g., icons, buttons)
- **supportAccent**: Bright yellow (`#D7FF00`) for sparse, occasional use (e.g., special highlights)
- **tertiaryAccent**: Not used (set to `clear`)

### Status Colors
- **statusSuccess**: Semi-transparent blue (`#00AEEF`, 90% opacity) for consistency
- **statusWarning**: Not used (set to `clear`)
- **statusError**: Not used (set to `clear`)

## Gradients

### Background Gradients
- **spaceBackgroundGradient**:
  ```
  LinearGradient(
      colors: [Color.black, Color(hex: "#0A0A0A"), Color(hex: "#00AEEF").opacity(0.05)],
      startPoint: .top,
      endPoint: .bottom
  )
  ```

- **purpleBackgroundGradient**:
  ```
  LinearGradient(
      colors: [Color.black, Color(hex: "#0A0A0A"), Color.black],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
  )
  ```

- **blueBackgroundGradient**:
  ```
  LinearGradient(
      colors: [Color.black, Color(hex: "#0A0A0A"), Color.black],
      startPoint: .topTrailing,
      endPoint: .bottomLeading
  )
  ```

### Component Gradients
- **cardGradient**:
  ```
  LinearGradient(
      colors: [Color(hex: "#1A1A1A").opacity(0.85), Color(hex: "#212121").opacity(0.9)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
  )
  ```

- **imageOverlayGradient**:
  ```
  LinearGradient(
      colors: [Color.black.opacity(0.7), Color.black.opacity(0.3), Color.clear],
      startPoint: .bottom,
      endPoint: .top
  )
  ```

- **buttonGradient**:
  ```
  LinearGradient(
      colors: [highlightAccent, highlightAccent.opacity(0.8)],
      startPoint: .leading,
      endPoint: .trailing
  )
  ```

## Typography

### Font Sizes
- **Tiny**: 12pt
- **Small**: 14pt
- **Medium**: 16pt
- **Large**: 20pt
- **Header**: 24pt
- **Title**: 32pt
- **Display**: 40pt

### Font Weights
- **Light**: `Font.Weight.light`
- **Regular**: `Font.Weight.regular`
- **Medium**: `Font.Weight.medium`
- **Semibold**: `Font.Weight.semibold`
- **Bold**: `Font.Weight.bold`

### Predefined Text Styles
- **Display**: 40pt Bold
- **Title**: 24pt Bold (adjusted to match Grok 3 header)
- **Header**: 20pt Semibold
- **Subheader**: 16pt Semibold
- **Body**: 16pt Regular
- **Caption**: 14pt Regular
- **Small Caption**: 12pt Medium
- **Button**: 14pt Medium (adjusted to match Grok 3 buttons)

## Spacing & Layout

### Grid System
- Based on 8-point grid (multiples of 8)

### Corner Radius
- **Small**: 12px
- **Medium**: 16px (adjusted to match Grok 3 cards/buttons)
- **Large**: 24px
- **Pill**: 32px

### Padding
- **Tiny**: 4px
- **Small**: 8px
- **Medium**: 12px
- **Standard**: 16px
- **Large**: 24px
- **Extra Large**: 32px

### Element Sizing
- **Button Height**: 48px
- **Input Height**: 48px
- **Icon Size (Small)**: 16px
- **Icon Size (Medium)**: 20px
- **Icon Size (Large)**: 24px
- **Launch Card Image Height**: 220px
- **Detail Image Height**: 240px

## Effects

### Shadow
- **Radius (Small)**: 10px
- **Radius (Medium)**: 15px
- **Radius (Large)**: 25px
- **Opacity (Light)**: 10%
- **Opacity (Medium)**: 20%
- **Opacity (Heavy)**: 30%
- **Offset**: (0, 8)

### Glassmorphic Effect
- **Background**: Semi-transparent dark gray (`#1A1A1A`, 85% opacity)
- **Glass Highlight**: White with 10% opacity
- **Glass Effect**: White with 5% opacity
- **Border**: White with 10% opacity, 0.5px width

### Animation
- **Standard Duration**: 0.25s
- **Fast Duration**: 0.15s
- **Slow Duration**: 0.4s
- **Spring**: response 0.3, dampingFraction 0.7
- **Bouncy Spring**: response 0.4, dampingFraction 0.6

## Components

### Buttons
- **Primary**: Blue background (`highlightAccent`) with black text
- **Secondary**: Transparent with blue border (`highlightAccent`) and white text
- **Occasional Highlight**: Bright yellow background (`supportAccent`) with black text, used sparingly
- **Shape**: Pill with 32px corner radius
- **Height**: 48px
- **Padding**: 24px horizontal, 12px vertical

### Cards
- **Background**: Semi-transparent dark gray (`cardSurface`)
- **Border**: White with 10% opacity, 0.5px width
- **Corner Radius**: 16px
- **Shadow**: Black with 20% opacity, 15px radius, (0, 8) offset

### Status Badges
- **Small**: Pill shape, 11pt text, small icon
- **Large**: Pill shape, 14pt text, medium icon
- **Glowing**: With added outer glow matching `highlightAccent`

### Search Bar
- **Style**: Pill shape with magnifying glass icon
- **Background**: Dark gray with 85% opacity (`cardSurface`)
- **Border**: White with 10% opacity, 0.5px width
- **Animation**: Spring for expansion/collapse

### Countdown Timer
- **Ring Style**: Circular progress indicators
- **Colors**: Dynamic based on time remaining (e.g., `highlightAccent` for active)
- **Animations**: Subtle pulse for under one hour countdown
- **Compact Style**: Pill shape with clock icon

## Implementation Notes

### Glass Effect Modifier
```swift
.glassmorphic(
    tint: .white, 
    intensity: 0.85, 
    cornerRadius: 16
)
```

### Card Style
```swift
.grokCard(cornerRadius: 16)
```

### Control Style
```swift
.grokControl(
    cornerRadius: 16,
    highlightBorder: true,
    highlightColor: Styles.highlightAccent
)
```

### Background Style
```swift
.grokBackground()
```

## Accessibility Considerations
- Ensure sufficient contrast between text and backgrounds
- Support dynamic type scaling
- Include reduced motion settings
- Provide appropriate text alternatives for UI elements

---
