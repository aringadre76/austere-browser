# Austere Design System

## Design Philosophy
**"Focused Privacy, Purposeful Simplicity"** - Every element serves a function. No decoration without purpose.

## Color Palette

### Primary Colors (Dark Theme - Default)
- **Background Deep**: `#0A0A0B` (Near-black, warm undertone)
- **Background Surface**: `#141415` (Slightly raised elements)
- **Background Elevated**: `#1A1A1C` (Interactive elements)

### Accent Colors
- **Primary Blue**: `#0066CC` (Privacy, trust)
- **Secondary Blue**: `#0052A3` (Pressed/active states)
- **Accent Green**: `#00C896` (Success, secure connections)
- **Warning Amber**: `#FFB000` (Warnings, cautions)
- **Critical Red**: `#FF3B30` (Errors, security alerts)

### Neutral Text Colors
- **Text Primary**: `#FFFFFF` (Full white for contrast)
- **Text Secondary**: `#A0A0A5` (Subtle, secondary info)
- **Text Tertiary**: `#606065` (Disabled/hint text)
- **Text Inverse**: `#0A0A0B` (On colored backgrounds)

### Border Colors
- **Border Subtle**: `#2A2A2D` (Hardly visible)
- **Border Medium**: `#3A3A3D` (Visible dividers)
- **Border Strong**: `#4A4A4D` (Interactive boundaries)

### Memory Status Colors
- **Low Memory**: `#00C896` (Green - healthy)
- **Medium Memory**: `#FFB000` (Amber - caution)
- **High Memory**: `#FF6B35` (Orange - warning)
- **Critical Memory**: `#FF3B30` (Red - critical)

## Typography

### Font Hierarchy
- **Primary**: Inter (system-ui fallback)
- **Monospace**: JetBrains Mono (monospace fallback)
- **Weights**: 300 (Light), 400 (Regular), 500 (Medium), 600 (SemiBold)

### Font Sizes
- **UI Body**: 14px (Primary interface text)
- **UI Small**: 12px (Secondary info, tooltips)
- **UI Large**: 16px (Important labels, headers)
- **Tab Title**: 13px (Tab titles specifically)

### Line Heights
- **Body Text**: 1.4
- **UI Elements**: 1.2
- **Tab Titles**: 1.3

## Spacing System (4px grid)

- **xs**: 4px (Icon padding, tight spacing)
- **sm**: 8px (Button padding, small gaps)
- **md**: 12px (Standard spacing)
- **lg**: 16px (Section spacing)
- **xl**: 24px (Major sections)
- **2xl**: 32px (Page margins)

## Border Radius System

- **Micro**: 2px (Input fields, small elements)
- **Small**: 4px (Buttons, tags)
- **Medium**: 6px (Cards, panels)
- **Large**: 8px (Dialog boxes, major containers)
- **Tab Radius**: 8px top only, 0px bottom (connected tabs)

## Shadows

- **Subtle**: `0 1px 2px rgba(0, 0, 0, 0.3)`
- **Medium**: `0 4px 6px rgba(0, 0, 0, 0.4)`
- **Strong**: `0 8px 12px rgba(0, 0, 0, 0.5)`
- **Tab Shadow**: `0 2px 4px rgba(0, 0, 0, 0.2)` (for active tabs)

## Animations

### Duration
- **Fast**: 150ms (Button interactions)
- **Medium**: 250ms (Tab transitions)
- **Slow**: 350ms (Dialog openings)

### Easing
- **Ease Out**: `cubic-bezier(0.0, 0.0, 0.2, 1)` (Most UI)
- **Ease In Out**: `cubic-bezier(0.4, 0.0, 0.2, 1)` (Complex transitions)

### Key Animations
- **Tab Hover**: Scale 1.02, shadow enhancement
- **Tab Active**: Scale 0.98, deeper shadow
- **Button Press**: Scale 0.95
- **Fade In**: Opacity 0 → 1, subtle slide up 2px

## Component States

### Buttons
- **Default**: Background Elevated + Text Primary + Border Subtle
- **Hover**: Background #1F1F21 + Border Medium
- **Active**: Background #252527 + Scale 0.95
- **Disabled**: Text Tertiary + Background Surface

### Tabs
- **Inactive**: Background Surface + Text Secondary
- **Active**: Background Elevated + Text Primary + Strong shadow
- **Hover**: Background #1A1A1C + Subtle shadow
- **Discarded/Frozen**: Text Tertiary + italic

### Memory Indicators
- **Low**: Green dot (4px) + Green text
- **Medium**: Amber dot (4px) + Amber text  
- **High**: Orange dot (4px) + Orange text
- **Critical**: Red pulsing dot (4px) + Red text

## Iconography

### Style
- **Line Weight**: 1.5px (conservative, readable)
- **Size**: 16px (standard), 20px (important actions)
- **Color**: Text Primary (default), Secondary for less important

### Key Icons
- **Security**: Shield outline (green when secure)
- **Memory**: Memory chip/ram icon
- **Privacy**: Eye with slash
- **Settings**: Gear (simplified)

## Responsive Behavior

### Window Size Adaptations
- **< 800px**: Reduce tab title truncation, hide secondary actions
- **< 600px**: Compact tab mode, icon-only buttons where possible
- **< 400px**: Minimum viable interface, essential controls only

## Accessibility

### Contrast Ratios
- **All text**: WCAG AA compliant (4.5:1 minimum)
- **Important text**: WCAG AAA compliant (7:1 minimum)

### Focus Indicators
- **Color**: Primary Blue (#0066CC)
- **Width**: 2px
- **Style**: Solid, rounded corners matching element

### Reduced Motion
- **Respect system preferences**
- **Remove animations when disabled**
- **Instant transitions only**

## Implementation Notes

### CSS Variables (Chromium equivalent)
```css
--austere-bg-deep: #0A0A0B;
--austere-bg-surface: #141415;
--austere-bg-elevated: #1A1A1C;
--austere-primary: #0066CC;
--austere-accent-green: #00C896;
--austere-text-primary: #FFFFFF;
--austere-text-secondary: #A0A0A5;
--austere-text-tertiary: #606065;
```

### Platform Integration
- **Windows**: Respect dark mode system setting
- **Linux**: Follow GTK dark mode preferences
- **macOS**: Follow system appearance preferences

This design system emphasizes the browser's core values: privacy, performance, and purposeful design. Every element is optimized for reducing cognitive load while maintaining visual sophistication.