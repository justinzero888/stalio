# Stalio 跬步 — Popup UI Component Design Specification  
  
**Version:** 1.0    
**Date:** June 16, 2026    
**Audience:** Development Team, UI/UX Designers    
**Purpose:** UI component specifications for all habit tracking interaction patterns  
  
---  
  
## Table of Contents  
  
1. [Component Type Legend](#component-type-legend)  
2. [Boolean — Simple Toggle](#1-boolean--simple-toggle)  
3. [Boolean with Optional Text](#2-boolean_optional_text--toggle-with-optional-note)  
4. [Duration — Timer / Minutes Picker](#3-duration--timer--minutes-picker)  
5. [Duration with Optional Text](#4-duration_optional_text--duration--optional-note)  
6. [Number — Number Picker](#5-number--number-picker)  
7. [Time — Time Picker](#6-time--time-picker)  
8. [Scale — 1-5 Rating Picker](#7-scale--1-5-rating-picker)  
9. [Scale with Optional Text](#8-scale_optional_text--scale--optional-note)  
10. [Text Required — Text Box](#9-text_required--text-box-must-write)  
11. [Multi-Text Required — Multi-Field](#10-multi_text_required--multi-field-text-box)  
    - [A. Gratitude (3 items)](#a-h020--practice-gratitude-3-items)  
    - [B. Priorities (3 items)](#b-h042--review-top-3-priorities-3-items)  
    - [C. Spending (item + amount)](#c-h046--log-spending-item--amount)  
12. [Streak — Streak Counter](#11-streak--streak-counter-smoking-cessation)  
13. [Habit Mapping Reference](#appendix-a-habit-mapping-reference)  
14. [Shared Design Principles](#appendix-b-shared-design-principles)  
  
---  
  
## Component Type Legend  
  
| Type | Code | Behavior | Habits Using This |  
|------|------|----------|-------------------|  
| `boolean` | Simple toggle | Tap → checkmark | H002, H003, H004, H008, H009, H010, H012, H016, H033, H034, H035, H036, H038, H051 |  
| `boolean_optional_text` | Toggle + optional note | Tap → checkmark; optional "add note" | H007, H011, H027, H028, H032, H049, H050, H053 |  
| `duration` | Timer / minutes picker | Start/stop or slide to select minutes | H006, H018, H019, H022, H052 |  
| `duration_optional_text` | Duration + optional note | Duration required, note optional | H029, H030, H031, H040, H041, H043, H045, H054 |  
| `number` | Number picker | Stepper or keyboard number input | H005, H013, H039, H047 |  
| `time` | Time picker | Clock selector | H014, H015 |  
| `scale` | 1-5 rating | Emoji or number scale selector | H017 |  
| `scale_optional_text` | Scale + optional note | Scale required, text optional | H024 |  
| `text_required` | Text box (must write) | Popup with textarea, save button disabled until text entered | H021, H023, H025, H026, H044, H048 |  
| `multi_text_required` | Multi-field text box | 2-3 separate text fields, all required | H020, H042, H046 |  
| `streak` | Streak counter | Special handling for cessation habits | H037 |  
  
---  
  
## 1. `boolean` — Simple Toggle  
  
**Habits:** H002, H003, H004, H008, H009, H010, H012, H016, H033, H034, H035, H036, H038, H051  
  
### UI Specification  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  今日习惯                                                   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│   ┌─────────────────────────────────────────────────────┐   │  
│   │  💧 喝水                              [ ]          │   │  
│   │  今天已喝 5/8 杯                                    │   │  
│   └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│   ┌─────────────────────────────────────────────────────┐   │  
│   │  🪥 用牙线                             [ ]          │   │  
│   └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│   ┌─────────────────────────────────────────────────────┐   │  
│   │  🚶 出门走走                           [ ]          │   │  
│   └─────────────────────────────────────────────────────┘   │  
│                                                             │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### Interaction Flow  
  
```  
User taps checkbox  
        ↓  
Animate checkmark ✓ (spring animation, 300ms)  
        ↓  
Haptic feedback (light impact)  
        ↓  
Habit marked as completed ✅  
        ↓  
Update UI: checkbox checked, show "Done!" toast (optional)  
        ↓  
No popup. Instant satisfaction.  
```  
  
### Design Specifications  
  
| Element | Specification |  
|---------|---------------|  
| **Checkbox** | Custom rounded square, 24x24dp, border radius 6dp |  
| **Checkbox unchecked** | Border: 2dp solid, color: #D1D5DB |  
| **Checkbox checked** | Background: #2D6A6A, white checkmark |  
| **Habit icon** | 24x24dp emoji or SF Symbol |  
| **Habit name** | 16sp, weight 500, color: #1E1E2A |  
| **Progress text** | 14sp, color: #6B7280 |  
| **Animation** | Spring animation, duration 300ms |  
| **Haptic feedback** | UIImpactFeedbackStyle.light (iOS) / Vibrator.vibrate(20ms) (Android) |  
| **Accessibility** | Content description: "Mark [habit name] complete" |  
  
### State Transitions  
  
| State | Visual |  
|-------|--------|  
| Unchecked | Empty checkbox, grey border |  
| Checking | Checkbox animates to filled state |  
| Checked | Filled checkbox with white checkmark, subtle glow |  
| Completed today | Slightly greyed out or checkmark with strikethrough (optional) |  
  
---  
  
## 2. `boolean_optional_text` — Toggle with Optional Note  
  
**Habits:** H007, H011, H027, H028, H032, H049, H050, H053  
  
### UI Specification — Main View  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  今日习惯                                                   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│   ┌─────────────────────────────────────────────────────┐   │  
│   │  🏋️ 运动                              [ ]          │   │  
│   │  Tap to mark complete                               │   │  
│   │  [📝 Add note]                                     │   │  
│   └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│   ┌─────────────────────────────────────────────────────┐   │  
│   │  📞 给家人打电话                        [ ]          │   │  
│   │  [📝 Add note]                                     │   │  
│   └─────────────────────────────────────────────────────┘   │  
│                                                             │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### UI Specification — Note Popup  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  📝 Add note                                          [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  What workout did you do?                                   │  
│                                                             │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │  45 min strength training                          │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  [Skip]                              [Save & Done]         │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### Interaction Flow  
  
```  
User taps checkbox  
        ↓  
Habit marked as completed ✅ (immediate)  
        ↓  
User sees "Add note" button appears below habit  
        ↓  
User may tap "Add note" at any time (even later)  
        ↓  
Popup appears with text field  
        ↓  
User writes note (optional — can close without saving)  
        ↓  
Tap "Save & Done" → note saved to journal  
        ↓  
Popup closes, note icon appears on habit card  
  
OR  
  
User ignores note button → habit remains completed  
```  
  
### Design Specifications  
  
| Element | Specification |  
|---------|---------------|  
| **Main checkbox** | Same as `boolean` type |  
| **Add note button** | Text link: 14sp, color: #2D6A6A, icon: 📝 |  
| **Note badge** | After note saved: small "📝" badge on habit card |  
| **Popup** | Bottom sheet or centered modal |  
| **Popup title** | 18sp, weight 600, color: #1E1E2A |  
| **Popup text field** | Standard input with placeholder |  
| **Skip button** | 16sp, color: #9CA3AF |  
| **Save button** | 16sp, color: #FFFFFF, background: #2D6A6A, rounded 8dp |  
| **Haptic feedback** | Medium impact on checkbox |  
  
### State Transitions  
  
| State | Visual |  
|-------|--------|  
| Habit unchecked | Empty checkbox |  
| Habit checked, no note | Checked checkbox, "Add note" button visible |  
| Habit checked, note saved | Checked checkbox, 📝 badge appears |  
| Note popup open | Bottom sheet slides up from bottom |  
  
---  
  
## 3. `duration` — Timer / Minutes Picker  
  
**Habits:** H006, H018, H019, H022, H052  
  
### UI Specification  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  🧘 静坐 / 冥想                                      [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  How long did you meditate?                                 │  
│                                                             │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │                                                     │   │  
│  │           [  -  ]    10 min     [  +  ]             │   │  
│  │                                                     │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │  
│                                                             │  
│  Or use timer:                                              │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │  [▶️ Start Timer]                                   │   │  
│  │  Timer will count up. Tap 'Done' when finished.     │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  [Cancel]                              [Save & Done]       │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### Timer Running State  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  🧘 静坐 / 冥想                                      [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  Timer running...                                           │  
│                                                             │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │                                                     │   │  
│  │               ⏱️  12:34                             │   │  
│  │                                                     │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │  [⏹️ Stop Timer]                                    │   │  
│  │  Tap 'Stop' when you're finished.                   │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  [Cancel]                              [Save & Done]       │  
│                                         (enabled after      │  
│                                          timer stopped)     │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### Interaction Flow  
  
```  
User opens habit popup  
        ↓  
Option A: Manual entry  
    User taps + / - buttons to adjust minutes  
        ↓  
    Tap "Save & Done"  
        ↓  
    Habit completed ✅  
  
Option B: Timer  
    User taps "Start Timer"  
        ↓  
    Timer counts up (00:00 format)  
        ↓  
    User taps "Stop Timer"  
        ↓  
    Duration auto-populated  
        ↓  
    Tap "Save & Done"  
        ↓  
    Habit completed ✅  
```  
  
### Design Specifications  
  
| Element | Specification |  
|---------|---------------|  
| **Stepper buttons** | Circular buttons, 40x40dp, background: #F3F4F6, icon: chevron |  
| **Duration display** | 32sp, weight 600, color: #1E1E2A, font: monospaced digits |  
| **Increment** | User-defined per habit (1, 5, 15 minutes) |  
| **Timer display** | 48sp, weight 700, color: #2D6A6A, font: monospaced |  
| **Start button** | 16sp, background: #2D6A6A, text: white, rounded 8dp |  
| **Stop button** | 16sp, background: #EF4444, text: white, rounded 8dp |  
| **Haptic feedback** | On start: medium impact. On stop: success impact |  
| **Background timer** | Timer continues even if app goes to background (with notification) |  
  
### Validations  
  
| Condition | Behavior |  
|-----------|----------|  
| Duration = 0 | "Save & Done" disabled |  
| Duration > max | Show error: "Maximum [max] minutes" |  
| Duration < min | Show error: "Minimum [min] minutes" |  
  
---  
  
## 4. `duration_optional_text` — Duration + Optional Note  
  
**Habits:** H029, H030, H031, H040, H041, H043, H045, H054  
  
### UI Specification  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  👨‍👩‍👧 专心陪孩子                                      [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  How long?                                                  │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │           [  -  ]    15 min     [  +  ]             │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  📝 Add a note (optional)                                   │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │  Played LEGO together for 20 min                    │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  [Cancel]                              [Save & Done]       │  
│                                         (disabled until     │  
│                                          duration set)      │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### Interaction Flow  
  
```  
User opens habit popup  
        ↓  
Select duration (required) via stepper or timer  
        ↓  
Optional: Write a note  
        ↓  
Tap "Save & Done"  
        ↓  
Habit completed ✅  
        ↓  
Note saved to journal if provided  
```  
  
### Design Specifications  
  
| Element | Specification |  
|---------|---------------|  
| **Duration picker** | Same as `duration` component |  
| **Note field** | Single-line text input, placeholder: "Add a note..." |  
| **Note field height** | 48dp, border: 1dp #E5E7EB, corner radius 8dp |  
| **Character limit** | 200 characters (soft limit) |  
| **Save button** | Disabled until duration is set |  
| **Haptic feedback** | Success impact on save |  
  
---  
  
## 5. `number` — Number Picker  
  
**Habits:** H005 (steps), H013 (calories), H039 (minutes), H047 (amount)  
  
### UI Specification  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  🚶 走 5000 步                                       [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  How many steps did you walk today?                         │  
│                                                             │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │                                                     │   │  
│  │       [  -  ]      5,234     [  +  ]               │   │  
│  │                                                     │   │  
│  │           (increment: 500 steps)                    │   │  
│  │                                                     │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  Target: 5,000 steps                                       │  
│  └───────────────────────── Progress: ████░░░░ 65%        │  
│                                                             │  
│  [Cancel]                              [Save & Done]       │  
│                                         (disabled if         │  
│                                          value < min)       │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### Alternative: Keyboard Input for Precise Numbers  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  💰 转存储蓄                                          [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  How much did you transfer to savings?                      │  
│                                                             │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │  $                                              │   │  
│  │  ─────────────────────────────────────────────── │   │  
│  │  [1] [2] [3]                                     │   │  
│  │  [4] [5] [6]                                     │   │  
│  │  [7] [8] [9]                                     │   │  
│  │  [.] [0] [⌫]                                     │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  Current savings: $247.50                                   │  
│  Projected annual: $2,970.00                               │  
│                                                             │  
│  [Cancel]                              [Save & Done]       │  
│                                         (disabled if         │  
│                                          value < min)       │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### Interaction Flow  
  
```  
User opens habit popup  
        ↓  
Option A: Stepper  
    Tap + / - → value adjusts by increment  
        ↓  
Option B: Keyboard input  
    Tap number field → numeric keyboard appears  
        ↓  
    Enter value  
        ↓  
Tap "Save & Done"  
        ↓  
Habit completed ✅  
```  
  
### Design Specifications  
  
| Element | Specification |  
|---------|---------------|  
| **Stepper buttons** | 44x44dp, background: #F3F4F6, icon: plus/minus |  
| **Value display** | 28sp, weight 600, color: #1E1E2A, number formatting |  
| **Increment** | User-defined per habit (500, 50, 15, etc.) |  
| **Progress bar** | Shows % of target achieved, color: #2D6A6A |  
| **Keyboard input** | Numeric keyboard for precise values |  
| **Formatting** | Commas for thousands, 2 decimals for currency |  
| **Currency** | Locale-aware ($, £, €, ¥) |  
  
### Validations  
  
| Condition | Behavior |  
|-----------|----------|  
| Value < min | Show error: "Minimum is [min]" |  
| Value > max | Show error: "Maximum is [max]" |  
| Value not multiple of increment | Show warning: "Increment by [increment]" |  
| Value = 0 | Save button disabled |  
  
---  
  
## 6. `time` — Time Picker  
  
**Habits:** H014 (bedtime), H015 (wake time)  
  
### UI Specification  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  😴 11 点前睡觉                                       [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  What time did you go to bed last night?                    │  
│                                                             │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │                                                     │   │  
│  │              10:45 PM                              │   │  
│  │            [⏰ Time Picker Wheel]                   │   │  
│  │                                                     │   │  
│  │        Hour: 10   Minute: 45   AM/PM: PM           │   │  
│  │                                                     │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  Target: 11:00 PM                                          │  
│  Status: ✅ 15 minutes early — great!                      │  
│                                                             │  
│  [Cancel]                              [Save & Done]       │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### Wake Time Variation  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  🌅 固定时间起床                                      [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  What time did you wake up this morning?                    │  
│                                                             │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │                                                     │   │  
│  │              6:30 AM                               │   │  
│  │            [⏰ Time Picker Wheel]                   │   │  
│  │                                                     │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  Target: 6:30 AM                                           │  
│  Status: ✅ On target!                                      │  
│                                                             │  
│  [Cancel]                              [Save & Done]       │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### Interaction Flow  
  
```  
User opens habit popup  
        ↓  
Spin time picker wheels to select time  
        ↓  
Tap "Save & Done"  
        ↓  
Habit completed ✅  
        ↓  
Time saved to database  
```  
  
### Design Specifications  
  
| Element | Specification |  
|---------|---------------|  
| **Time picker** | Native iOS/Android wheel picker or custom picker |  
| **Format** | Locale-aware (12h vs 24h) |  
| **Target** | Displayed below picker with comparison |  
| **Comparison status** | Early: ✅ green / Late: ⚠️ orange / On time: ✅ green |  
| **Time zone** | User's local time zone |  
| **Haptic feedback** | Light impact on picker selection |  
  
---  
  
## 7. `scale` — 1-5 Rating Picker  
  
**Habits:** H017 (sleep quality)  
  
### UI Specification  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  💤 记录睡眠质量                                      [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  How well did you sleep last night?                         │  
│                                                             │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │                                                     │   │  
│  │     😫     😕     😐     🙂     😊                  │   │  
│  │      1      2      3      4      5                  │   │  
│  │                                                     │   │  
│  │          [Tap your rating]                          │   │  
│  │                                                     │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  Bedtime: 10:45 PM | Wake: 6:30 AM | Duration: 7h 45m     │  
│                                                             │  
│  [Cancel]                              [Save & Done]       │  
│                                         (disabled until     │  
│                                          rating selected)   │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### Interaction Flow  
  
```  
User opens habit popup  
        ↓  
Tap on emoji or number (1-5)  
        ↓  
Selected rating animates (scale up)  
        ↓  
Tap "Save & Done"  
        ↓  
Habit completed ✅  
        ↓  
Rating saved to sleep_entries table  
```  
  
### Design Specifications  
  
| Element | Specification |  
|---------|---------------|  
| **Emoji scale** | 😫 😕 😐 🙂 😊 (5 levels) |  
| **Number scale** | 1, 2, 3, 4, 5 (below emojis) |  
| **Selected state** | Scale up animation, colored background |  
| **Unselected** | 50% opacity |  
| **Tap area** | Minimum 44x44dp per option |  
| **Haptic feedback** | Light impact on selection, success on save |  
| **Sleep summary** | Shows bedtime, wake time, duration (if available) |  
  
---  
  
## 8. `scale_optional_text` — Scale + Optional Note  
  
**Habits:** H024 (log mood)  
  
### UI Specification  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  😊 记录心情                                          [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  How was your overall mood today?                           │  
│                                                             │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │                                                     │   │  
│  │     😫     😕     😐     🙂     😊                  │   │  
│  │      1      2      3      4      5                  │   │  
│  │                                                     │   │  
│  │              [Selected: 4]                          │   │  
│  │                                                     │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  📝 Add a note (optional)                                   │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │  Had a great lunch with an old friend               │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  [Cancel]                              [Save & Done]       │  
│                                         (disabled until     │  
│                                          rating selected)   │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### Interaction Flow  
  
```  
User opens habit popup  
        ↓  
Tap on emoji or number (1-5) — REQUIRED  
        ↓  
Selected rating animates (scale up)  
        ↓  
Optional: Write a note  
        ↓  
Tap "Save & Done"  
        ↓  
Habit completed ✅  
        ↓  
Rating and note saved to mood_entries table  
```  
  
### Design Specifications  
  
| Element | Specification |  
|---------|---------------|  
| **Rating scale** | Same as `scale` component |  
| **Rating required** | Save button disabled until rating selected |  
| **Note field** | Single-line text input, placeholder: "How are you feeling?" |  
| **Note field height** | 48dp, border: 1dp #E5E7EB, corner radius 8dp |  
| **Character limit** | 200 characters |  
| **Haptic feedback** | Light impact on selection, success on save |  
  
---  
  
## 9. `text_required` — Text Box (Must Write)  
  
**Habits:** H021, H023, H025, H026, H044, H048  
  
### UI Specification  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  📝 写一则笔记                                        [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  What happened? What are you thinking?                      │  
│                                                             │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │                                                     │   │  
│  │  Finished the project proposal today. Felt good    │   │  
│  │  about how it came together. Need to review with   │   │  
│  │  the team tomorrow morning.                        │   │  
│  │                                                     │   │  
│  │  (Keyboard open automatically)                      │   │  
│  │                                                     │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  💡 Tip: Write anything — one sentence counts.              │  
│                                                             │  
│  [ Cancel ]                          [ Save & Done ]       │  
│                                          (disabled until    │  
│                                           text entered)     │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### Habit-Specific Variations  
  
#### H021 — Learn Something New  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  📚 学一样新的事                                      [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  What's one new thing you learned today?                    │  
│                                                             │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │  Learned that the 'testing effect' is more powerful │   │  
│  │  than re-reading for memory retention.              │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  💡 Tip: Even a small fact or observation counts.           │  
│                                                             │  
│  [ Cancel ]                              [ Save & Done ]   │  
└─────────────────────────────────────────────────────────────┘  
```  
  
#### H025 — Note One Gratitude  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  🙏 写下一件感激的事                                  [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  Write down one thing you're grateful for today.            │  
│  Be specific.                                               │  
│                                                             │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │  The way my colleague offered help without me       │   │  
│  │  having to ask.                                     │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  💡 Tip: Specific > generic ("the coffee" > "my family")   │  
│                                                             │  
│  [ Cancel ]                              [ Save & Done ]   │  
└─────────────────────────────────────────────────────────────┘  
```  
  
#### H026 — Evening Reflection  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  🌙 晚间省思                                          [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  Reflect on your day:                                       │  
│                                                             │  
│  What went well?                                            │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │  Finished the project draft                         │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  What could have gone better?                               │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │  Didn't take a lunch break                          │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  What will you do differently tomorrow?                     │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │  Take a proper lunch break                          │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  [ Cancel ]                              [ Save & Done ]   │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### Design Specifications  
  
| Element | Specification |  
|---------|---------------|  
| **Text area** | Multi-line, auto-expanding height, min 100dp |  
| **Placeholder** | Habit-specific prompt text |  
| **Keyboard** | Auto-opens on popup show (with slight delay for smooth transition) |  
| **Character limit** | Soft limit: 10,000 characters (display counter) |  
| **Save button** | Disabled until text is non-empty (trim whitespace) |  
| **Min length** | 3 characters (excluding whitespace) |  
| **Tip text** | 12sp, color: #9CA3AF, shows habit-specific encouragement |  
| **Haptic feedback** | Success impact on save |  
  
### Validations  
  
| Condition | Behavior |  
|-----------|----------|  
| Text empty or only whitespace | Save button disabled |  
| Text length < 3 characters | Show warning: "Please write a bit more" |  
| Text length > 10,000 characters | Show warning: "Entry is very long (max 10,000)" |  
  
---  
  
## 10. `multi_text_required` — Multi-Field Text Box  
  
### 10A. H020 — Practice Gratitude (3 items)  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  🙏 练习感恩                                          [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  Write 3 things you're grateful for today.                  │  
│  Be specific.                                               │  
│                                                             │  
│  1. ┌─────────────────────────────────────────────────────┐│  
│  │  The way my coffee tasted this morning                ││  
│  └─────────────────────────────────────────────────────┘│  
│                                                             │  
│  2. ┌─────────────────────────────────────────────────────┐│  
│  │  My coworker helped me with the presentation          ││  
│  └─────────────────────────────────────────────────────┘│  
│                                                             │  
│  3. ┌─────────────────────────────────────────────────────┐│  
│  │  Sunny weather during my lunch walk                   ││  
│  └─────────────────────────────────────────────────────┘│  
│                                                             │  
│  💡 Tip: "The coffee" > "coffee" — be specific!            │  
│                                                             │  
│  [ Cancel ]                          [ Save & Done ]       │  
│                                          (disabled until    │  
│                                           all 3 filled)     │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### 10B. H042 — Review Top 3 Priorities (3 items, lenient)  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  🎯 回顾 3 件要事                                     [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  What are the 3 most important things to do today?          │  
│                                                             │  
│  1. ┌─────────────────────────────────────────────────────┐│  
│  │  Finish quarterly report draft                        ││  
│  └─────────────────────────────────────────────────────┘│  
│                                                             │  
│  2. ┌─────────────────────────────────────────────────────┐│  
│  │  Schedule client meeting for next week                ││  
│  └─────────────────────────────────────────────────────┘│  
│                                                             │  
│  3. ┌─────────────────────────────────────────────────────┐│  
│  │  Buy groceries for dinner                             ││  
│  └─────────────────────────────────────────────────────┘│  
│                                                             │  
│  💡 Tip: Start with just one priority if 3 feels like too much. │  
│                                                             │  
│  [ Cancel ]                          [ Save & Done ]       │  
│                                          (disabled until    │  
│                                           at least 1 filled)│  
└─────────────────────────────────────────────────────────────┘  
```  
  
### 10C. H046 — Log Spending (item + amount)  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  💰 记录支出                                          [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  What did you spend money on today?                         │  
│                                                             │  
│  Item:                                                      │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │  Cold brew coffee                                   │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  Amount:                                                    │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │  $5.25                                              │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  Category (optional):                                      │  
│  [🍔 Food] [🚗 Transport] [🎬 Entertainment] [🛍️ Shopping] [➕ Other]│  
│                                                             │  
│  💡 Tip: Log every purchase — even small ones add up.      │  
│                                                             │  
│  [ Cancel ]                          [ Save & Done ]       │  
│                                          (disabled until    │  
│                                           item and amount)  │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### Multi-Text Interaction Flow  
  
```  
User opens habit popup  
        ↓  
Fields appear with auto-focus on first field  
        ↓  
User fills field 1 → keyboard "Next" moves to field 2  
        ↓  
User fills field 2 → keyboard "Next" moves to field 3  
        ↓  
User fills final field → keyboard "Done" appears  
        ↓  
Save button enables when validation passes  
        ↓  
Tap "Save & Done"  
        ↓  
Habit completed ✅  
        ↓  
All fields saved to journal_entries with structured_data  
```  
  
### Multi-Text Design Specifications  
  
| Element | Specification |  
|---------|---------------|  
| **Field count** | Variable (2-3 fields depending on habit) |  
| **Field height** | 44dp single-line input |  
| **Field label** | "1.", "2.", "3." or "Item:", "Amount:" |  
| **Field border** | 1dp #E5E7EB, corner radius 8dp |  
| **Field spacing** | 12dp between fields |  
| **Keyboard navigation** | Next → Next → Done |  
| **Save button** | Disabled until validation passes |  
| **Character limit per field** | 500 characters |  
  
### Multi-Text Validation Rules  
  
| Habit | Fields | Rule |  
|-------|--------|------|  
| H020 | 3 fields | All 3 must be non-empty (≥3 chars each) |  
| H042 | 3 fields | At least 1 must be non-empty (lenient) |  
| H046 | 2 fields | Item non-empty, Amount valid number > 0 |  
  
---  
  
## 11. `streak` — Streak Counter (Smoking Cessation)  
  
**Habits:** H037 (No smoking today)  
  
### UI Specification  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  🚭 今日不吸烟                                        [✕]   │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│  Did you stay smoke-free today?                             │  
│                                                             │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │                                                     │   │  
│  │           [✅ YES — I did not smoke]                │   │  
│  │                                                     │   │  
│  │           [❌ NO — I smoked today]                  │   │  
│  │                                                     │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  ┌─────────────────────────────────────────────────────┐   │  
│  │  🔥 Current streak: 47 days                         │   │  
│  │  🏆 Longest streak: 47 days                         │   │  
│  │  💰 Money saved: ~$470                              │   │  
│  │  🫁 Health recovered: 15% lung function improvement │   │  
│  └─────────────────────────────────────────────────────┘   │  
│                                                             │  
│  Need support? [📞 Resources]                               │  
│                                                             │  
│  [Skip]                                   [Confirm]        │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### Streak Celebration — Milestone  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  🎉                                                     [✕] │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│                                                             │  
│               🏆 50 DAYS!                                   │  
│                                                             │  
│          You've been smoke-free for                        │  
│             50 consecutive days!                            │  
│                                                             │  
│          💰 Total saved: ~$500                              │  
│          🫁 Health improvement: +20%                       │  
│                                                             │  
│          Keep going — you're doing amazing!                 │  
│                                                             │  
│                      [Continue]                             │  
│                                                             │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### Streak Reset — Supportive Message  
  
```  
┌─────────────────────────────────────────────────────────────┐  
│  💪                                                     [✕] │  
│  ─────────────────────────────────────────────────────────  │  
│                                                             │  
│                                                             │  
│          It's okay. Today is a new day.                     │  
│                                                             │  
│          You went 47 days smoke-free.                       │  
│          That's 47 days you didn't smoke.                   │  
│                                                             │  
│          💰 You saved ~$470 during that time.               │  
│          🫁 Your body is healing.                           │  
│                                                             │  
│          Let's start again tomorrow.                        │  
│          You've got this. 💪                                │  
│                                                             │  
│                      [Start Again]                          │  
│                                                             │  
└─────────────────────────────────────────────────────────────┘  
```  
  
### Interaction Flow  
  
```  
User opens habit popup  
        ↓  
Tap YES or NO (required)  
        ↓  
If YES:  
    Streak increments  
    Show milestone celebration if milestone reached  
        ↓  
    Save & Close  
        ↓  
If NO:  
    Streak resets to 0  
    Show supportive reset message (no guilt)  
        ↓  
    Save & Close  
        ↓  
Habit marked as completed (either way — tracking is the habit)  
```  
  
### Design Specifications  
  
| Element | Specification |  
|---------|---------------|  
| **YES button** | 48dp height, background: #2D6A6A, text: white, rounded 12dp |  
| **NO button** | 48dp height, background: #EF4444, text: white, rounded 12dp |  
| **Streak display** | Cards showing current streak, longest streak, money saved |  
| **Milestone celebrations** | At 7, 14, 30, 50, 75, 100, 365 days |  
| **Reset message** | Compassionate, non-judgmental tone |  
| **Resources button** | Links to smoking cessation resources |  
| **Haptic feedback** | Medium impact on selection |  
  
### Milestone Celebration Logic  
  
| Milestone | Animation | Message |  
|-----------|-----------|---------|  
| 7 days | 🎉 | "One week! Your body is already healing." |  
| 14 days | 🎉 | "Two weeks! You're building a new habit." |  
| 30 days | 🎉🎉 | "One month! This is a major achievement." |  
| 50 days | 🎉🎉🎉 | "50 days! You're incredible." |  
| 100 days | 🎉🎉🎉🎉 | "100 days! Look how far you've come." |  
| 365 days | 🥳🎊🎉 | "ONE YEAR! You did it!" |  
  
---  
  
## Appendix A: Habit Mapping Reference  
  
| tracking_ui_type | Habit IDs | Count |  
|------------------|-----------|-------|  
| `boolean` | H002, H003, H004, H008, H009, H010, H012, H016, H033, H034, H035, H036, H038, H051 | 14 |  
| `boolean_optional_text` | H007, H011, H027, H028, H032, H049, H050, H053 | 8 |  
| `duration` | H006, H018, H019, H022, H052 | 5 |  
| `duration_optional_text` | H029, H030, H031, H040, H041, H043, H045, H054 | 8 |  
| `number` | H005, H013, H039, H047 | 4 |  
| `time` | H014, H015 | 2 |  
| `scale` | H017 | 1 |  
| `scale_optional_text` | H024 | 1 |  
| `text_required` | H021, H023, H025, H026, H044, H048 | 6 |  
| `multi_text_required` | H020, H042, H046 | 3 |  
| `streak` | H037 | 1 |  
| **Total** | | **54** |  
  
---  
  
## Appendix B: Shared Design Principles  
  
### 1. Animation Standards  
  
| Animation | Duration | Curve | Use Case |  
|-----------|----------|-------|----------|  
| Checkbox check | 300ms | Spring (damping: 0.75) | Habit completion |  
| Popup open | 350ms | Ease-out | Any popup |  
| Popup close | 250ms | Ease-in | Any popup |  
| Scale selection | 200ms | Ease-out | Rating selection |  
| Celebration | 800ms | Spring (damping: 0.5) | Streak milestones |  
  
### 2. Haptic Feedback Standards  
  
| Action | iOS | Android |  
|--------|-----|---------|  
| Check habit | Light impact | Vibrator.vibrate(10ms) |  
| Save entry | Success notification | Vibrator.vibrate(30ms) |  
| Streak milestone | Heavy impact | Vibrator.vibrate(50ms) |  
| Selection | Light impact | Vibrator.vibrate(5ms) |  
| Error | Error notification | Vibrator.vibrate(40ms) |  
  
### 3. Color Palette  
  
| Token | Color | Usage |  
|-------|-------|-------|  
| Primary | #2D6A6A | Buttons, checkmarks, active states |  
| Primary Light | #E8F4F1 | Backgrounds, highlights |  
| Text Primary | #1E1E2A | Main text |  
| Text Secondary | #6B7280 | Helper text, placeholders |  
| Border | #E5E7EB | Input fields, dividers |  
| Success | #22C55E | Positive status |  
| Warning | #F59E0B | Warning status |  
| Error | #EF4444 | Error states, negative actions |  
  
### 4. Accessibility Requirements  
  
| Element | Specification |  
|---------|---------------|  
| **Tap targets** | Minimum 44x44dp for all interactive elements |  
| **Text contrast** | Minimum 4.5:1 ratio |  
| **Content description** | All interactive elements must have accessibility labels |  
| **Keyboard support** | All actions must be reachable via keyboard |  
| **Dynamic type** | Text must support user font size preferences |  
| **VoiceOver/TalkBack** | All elements must have proper accessibility traits |  
  
### 5. Error Handling  
  
| Error Type | Visual | Message |  
|------------|--------|---------|  
| Empty text | Red border on field | "Please write something before saving" |  
| Invalid number | Red border on field | "Please enter a valid number" |  
| Rating missing | Shake animation | "Please select a rating" |  
| Time invalid | Red border on picker | "Please select a valid time" |  
  
---  
  
## Appendix C: Developer Implementation Notes  
  
### iOS (UIKit/SwiftUI) Notes  
  
- Use `UIPresentationController` for bottom sheets  
- Use `UITextView` with dynamic height for text fields  
- Use `UISelectionFeedbackGenerator` for haptics  
- Use `UIView.animate` with spring damping for animations  
  
### Android (Jetpack Compose) Notes  
  
- Use `ModalBottomSheet` for popups  
- Use `TextField` with `maxLines = Int.MAX_VALUE` for text areas  
- Use `Vibrator` for haptic feedback  
- Use `AnimatedContent` for smooth transitions  
  
### React Native Notes  
  
- Use `Modal` with `transparent` for popups  
- Use `TextInput` with `multiline` for text areas  
- Use `react-native-haptic-feedback` for haptics  
- Use `react-native-reanimated` for animations  
  
---  
  
**End of Document**  
