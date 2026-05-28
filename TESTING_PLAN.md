# Micro Habits — Testing Plan

## 1. Unit Regression Tests

### 1.1 Models
| ID | Test | Expected |
|----|------|----------|
| M1 | Entry.toJson/fromJson round-trip | Entry serializes and deserializes correctly with all fields |
| M2 | Routine.toJson/fromJson with completions | Routine with completionLog survives round-trip |
| M3 | Routine.streak calculation | Correct streak with gap grace period |
| M4 | Routine.isCompletedOn(date) | Correctly identifies completion for specific date |
| M5 | Routine.frequencyLabel | Correct text for daily/weekly/scheduled/adhoc |
| M6 | Tag.toJson/fromJson round-trip | Tag serializes correctly |
| M7 | ListItem.toJson/fromJson | List items serialize correctly |
| M8 | Routine copyWith preserves fields | Specified fields change, others unchanged |

### 1.2 Database
| ID | Test | Expected |
|----|------|----------|
| D1 | DatabaseService._onCreate creates all tables | entries, tags, entry_tags, routines, completions exist |
| D2 | DatabaseService._onCreate creates indexes | idx_entries_created_at, idx_entry_tags_tag_id, idx_completions_routine_id exist |
| D3 | StorageService.init() seeds default tags | 6 default tags created on empty DB |
| D4 | StorageService.init() seeds default routines | 7 default routines created on empty DB |
| D5 | addEntry/updateEntry/deleteEntry CRUD | Entry lifecycle works correctly |
| D6 | addRoutine/updateRoutine/deleteRoutine CRUD | Routine with completions persists correctly |
| D7 | addTag/updateTag/deleteTag CRUD | Tag lifecycle works correctly |
| D8 | toggleListItem toggles isDone | List item state flips correctly |

### 1.3 Providers
| ID | Test | Expected |
|----|------|----------|
| P1 | EntryProvider.loadEntries populates list | Entries loaded from storage |
| P2 | EntryProvider.addEntry inserts at top | New entry appears at index 0 |
| P3 | EntryProvider search filters correctly | Content search returns matching entries |
| P4 | EntryProvider filterTag filters correctly | Tag filter returns only tagged entries |
| P5 | EntryProvider getEntriesForDate returns correct entries | Date filtering works |
| P6 | RoutineProvider.loadRoutines populates list | Routines loaded from storage |
| P7 | RoutineProvider.completeRoutine adds completion | Completion added to log |
| P8 | RoutineProvider.unmarkRoutine removes completion | Completion removed from log |
| P9 | RoutineProvider.toggleComplete toggles state | Alternating calls add/remove completion |
| P10 | RoutineProvider.getRoutinesForDate filters by schedule | Daily/weekly/scheduled/adhoc correct |
| P11 | RoutineProvider.isMissedOn detects missed day | Past uncompleted scheduled = missed |
| P12 | SummaryProvider.totalEntries counts correctly | Entry count matches |
| P13 | SummaryProvider.currentStreak calculates correctly | Consecutive day streak correct |
| P14 | SummaryProvider.activeHabits counts active only | Inactive routines excluded |

### 1.4 Services
| ID | Test | Expected |
|----|------|----------|
| S1 | VoiceNotificationService.init initializes TTS | No exception thrown |
| S2 | VoiceNotificationService.speak calls TTS | Text spoken in correct language |
| S3 | NotificationService.init initializes plugin | Plugin and timezone set up |
| S4 | NotificationService.scheduleRoutine schedules | Notification scheduled for reminder time |
| S5 | NotificationService.rescheduleAll handles empty list | No exception thrown |
| S6 | StorageService.exportData returns valid JSON | All data serialized correctly |

## 2. Integration Tests

| ID | Test | Steps | Expected |
|----|------|-------|----------|
| I1 | Full note lifecycle | 1. Add note with tags 2. Search for note 3. Edit note 4. Delete note | Note appears, is editable, searchable, deletable |
| I2 | Full habit lifecycle | 1. Add habit 2. Complete today 3. Check streak 4. Unmark 5. Delete | Streak increments, completion toggles, habit removed |
| I3 | Voice notification scheduling | 1. Add habit with reminder 2. Check notification scheduled | Background notification appears at scheduled time |
| I4 | Backup/restore cycle | 1. Create data 2. Export ZIP 3. Clear data 4. Import ZIP | Data restored exactly |
| I5 | Multi-tab navigation | 1. Navigate My Day → Moments → Habits → Insights | Each tab loads correctly, state preserved |

## 3. UAT Test Cases

### 3.1 My Day (Calendar)
| ID | Case | Steps | Pass Criteria |
|----|------|-------|---------------|
| U1 | View today's entries | Open My Day tab | Today's entries visible |
| U2 | View past date | Tap past date in calendar | Past day's entries shown |
| U3 | Add entry from FAB | Tap +, write note, save | Note appears in list |
| U4 | Edit entry | Tap entry, edit, save | Changes persist |
| U5 | Delete entry | Swipe/delete entry | Entry removed |
| U6 | Emotion picker | Add entry with emotion | Emotion saved and visible |

### 3.2 Moments (Notes)
| ID | Case | Steps | Pass Criteria |
|----|------|-------|---------------|
| U7 | Search notes | Type in search bar | Filtered results shown |
| U8 | Filter by tag | Tap filter, select tag | Tag-filtered results shown |
| U9 | Clear search | Clear search text | All notes visible again |
| U10 | Note detail view | Tap note card | Full note content shown |

### 3.3 Habits
| ID | Case | Steps | Pass Criteria |
|----|------|-------|---------------|
| U11 | Add habit | Tap +, fill form, save | Habit appears in list |
| U12 | Complete habit | Check checkbox | Completion recorded, streak updated |
| U13 | Un-complete habit | Uncheck checkbox | Completion removed |
| U14 | Edit habit | Tap habit, edit, save | Changes persist |
| U15 | Delete habit | Open edit, tap delete | Habit removed |
| U16 | Voice reminder toggle | Enable voice in settings | Voice speaks at scheduled time |
| U17 | Weekly habit | Create habit with specific days | Only shows on selected days |
| U18 | Streak display | Complete habit 3 days | Streak shows "3 days" |

### 3.4 Insights
| ID | Case | Steps | Pass Criteria |
|----|------|-------|---------------|
| U19 | Note count display | View Insights tab | Total note count shown |
| U20 | Active habit count | View Insights tab | Active habit count shown |

### 3.5 Cross-Device
| ID | Case | Steps | Pass Criteria |
|----|------|-------|---------------|
| U21 | All 4 tabs render on iPhone | Launch on iPhone 17 Pro | No crash, tabs navigable |
| U22 | All 4 tabs render on iPad | Launch on iPad Air 11" | No crash, tabs navigable |
| U23 | All 4 tabs render on Android | Launch on Pixel emulator | No crash, tabs navigable |

## UAT Checklist (per device)

- [ ] App launches without crash
- [ ] Bottom nav shows 4 tabs (My Day, Moments, Habits, Insights)
- [ ] My Day: Calendar renders, FAB adds entry
- [ ] Moments: Note list renders, search works
- [ ] Habits: Habit list renders, checkbox toggles work
- [ ] Insights: Basic stats render
- [ ] No AI robot overlay visible
- [ ] No purchase/paywall prompts
- [ ] No card sharing UI
