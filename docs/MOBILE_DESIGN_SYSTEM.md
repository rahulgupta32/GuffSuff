# GuffSuff Mobile Design System Specification

## Executive Overview
The GuffSuff Mobile Design System is a human-centric, highly structured design framework engineered specifically for consumer messaging in Nepal. It prioritizes clarity, performance, low latency, and zero visual clutter.

## 1. Color Semantics (`AppColors`)

### Light Palette
- **Surface Primary**: `#F8F9FA` (Soft neutral background)
- **Surface Secondary**: `#FFFFFF` (Card and list item background)
- **Surface Elevated**: `#FFFFFF` (Elevated modals and sheets)
- **Content Primary**: `#111827` (High contrast text)
- **Content Secondary**: `#4B5563` (Muted body text)
- **Content Muted**: `#9CA3AF` (Metadata and timestamps)
- **Border Subtle**: `#E5E7EB` (Subtle 1px dividers)

### Dark Palette
- **Surface Primary**: `#0F172A` (Deep navy midnight surface)
- **Surface Secondary**: `#1E293B` (Slightly lighter slate container)
- **Surface Elevated**: `#334155` (Elevated action sheets)
- **Content Primary**: `#F8FAFC` (Pure white text)
- **Content Secondary**: `#94A3B8` (Soft muted content)
- **Content Muted**: `#64748B` (Subtle timestamps)
- **Border Subtle**: `#334155` (Slate divider line)

### Brand & Interactive Colors
- **Brand Primary**: `#0F766E` (Teal accent, calm and trustworthy)
- **Brand Secondary**: `#14B8A6` (Vibrant teal highlight)
- **Interactive Primary**: `#0D9488` (Main CTA button background)
- **Danger**: `#DC2626` (Destructive action & warnings)
- **Warning**: `#D97706` (Security notice highlights)
- **Success**: `#059669` (Delivery checkmark & online status)

## 2. Typography (`AppTypography`)
Using `Inter` font family with fallback to Devanagari system fonts for seamless English and Nepali rendering.

- **Display Large**: 32pt, SemiBold (Onboarding titles)
- **Headline Medium**: 24pt, SemiBold (Section titles)
- **Title Large**: 20pt, SemiBold (AppBar headers)
- **Title Medium**: 16pt, Medium (Contact names, list item headers)
- **Title Small**: 14pt, Medium (Setting labels)
- **Body Large**: 16pt, Regular (Conversation bubble text)
- **Body Medium**: 14pt, Regular (Subtitles and secondary text)
- **Body Small**: 12pt, Regular (Previews)
- **Metadata**: 11pt, Regular (Timestamps, unread counts)

## 3. Spacing Grid (`AppSpacing`)
Built on a strict 8pt grid scale:
- `s2`: 2dp
- `s4`: 4dp
- `s8`: 8dp
- `s12`: 12dp
- `s16`: 16dp (Standard screen margin)
- `s20`: 20dp
- `s24`: 24dp (Section separation)
- `s32`: 32dp
- `s48`: 48dp (Touch target height)

## 4. Radii & Geometry (`AppRadii`)
- `small`: 4dp (Badge corners)
- `medium`: 8dp (Input fields & standard cards)
- `large`: 16dp (Action sheets & dialogs)
- `bubble`: 18dp (Chat message bubble corners with 4dp tail notch)
- `full`: 999dp (Circular avatars & pills)

## 5. Components & UI Patterns
- **AppBottomNav**: Custom 3-tab navigation bar with 48dp minimum touch targets.
- **Message Bubbles**: Asymmetric radii (`18dp` top-left, top-right, bottom-left, `4dp` bottom-right for outgoing messages).
- **Empty States**: Contextual SVG/Icon illustration with headline, descriptive body, and action button (`EmptyStateWidget`).
- **Security Notice**: Non-intrusive banner styled with subtle warning background, alerting users when cryptographic features are unavailable.
