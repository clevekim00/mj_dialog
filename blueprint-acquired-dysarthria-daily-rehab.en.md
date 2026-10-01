# Acquired Dysarthria Daily Rehabilitation Codex Automation Blueprint

[한국어](blueprint-acquired-dysarthria-daily-rehab.md) | [English](blueprint-acquired-dysarthria-daily-rehab.en.md) | [All documents](docs/README.en.md)

<!-- reader-link --> [Read with language tabs](https://clevekim00.github.io/mj_dialog/documents/blueprint-acquired-dysarthria-daily-rehab.en.html)

> Current navigation (2026-10-01): **Today → Training → Games → Records → Settings**. See [Games and current entry points](docs/game-menu.en.md). Earlier plans and reviews below retain their dated context.

> Created: 2026-08-24
> Purpose: Codex implementation blueprint
> Product identity review: 2026-09-25 · User confirmed adult acquired dysarthria and home self-practice scope.
> See section 5 for implementation status and revised design. The 15-/8-minute routines and twice-daily examples below are historical product examples, not clinical recommendations for every patient. Suggest a short initial plan; let users adjust actual time and repetitions.

## 0. Goals and deliverables

### Primary goal

Restructure Speech Rehab into a home self-practice service for adults with acquired dysarthria, with individually chosen durations and repetitions. Help users start today's practice immediately, connect lip/tongue movements to actual pronunciation, combine needed respiration, phonation, articulation, prosody, and functional-speaking tasks, and view accumulated training in a calendar.

### Success definition

- Start a chosen routine within 2 Home actions.
- Optional daily completion goal `N` is user-set from 1–4; never force it or present it as a universal dose.
- Save multiple sessions per day separately and aggregate counts, time, completed domains, and fatigue changes.
- Default routines connect breathing, phonation, articulation, and functional speech; nonspeech oral movements alone do not complete them.
- Every session has immediate-stop safeguards for pain, choking, swallowing difficulty, breathing discomfort, dizziness, or sudden speech changes.
- Voice scores are within-person practice references, not diagnosis or proof of treatment effectiveness.
- Reuse existing tongue, facial, breathing, pronunciation, recording, fatigue, and history features.

### Out of scope

Diagnosis, type/severity classification; individual medical plans replacing SLP prescription; swallowing/feeding rehabilitation or aspiration-risk assessment; unprescribed device-based EMST/IMST; unauthorized replication of LSVT LOUD® or SPEAK OUT!®; remote judgment of acute neurological/respiratory emergencies; caregiver/therapist portals and remote prescription in MVP.

## 1. Working context

### Background

The Flutter/Riverpod app already provides tongue routines, facial/breathing exercises, words/sentences/free speech, STT/TTS, playback, mouth videos, fatigue, history, and dashboard. Screens and storage are fragmented, without one daily prescribed-style routine or monthly aggregation. The breathing screen mixes mouth, lip, tongue, and cheek movements, so naming/content alignment needs improvement.

Clinical design references:

- ASHA describes acquired dysarthria as affecting one or more of respiration, phonation, articulation, resonance, and prosody. Intervention should match assessed impairments and functional communication goals. [ASHA Dysarthria in Adults](https://www.asha.org/practice-portal/clinical-topics/dysarthria-in-adults/).
- Motor-learning principles suggest repeated consistent tasks and performance feedback early, then varied tasks and outcome feedback with proficiency. The same guidance discusses dose, schedule, variability, complexity, specificity, repetition, intensity, and salience.
- Examples include comfortable posture, controlled/phrase-level breathing, sustained vowels, respiratory–phonatory coordination, placement cues, clear speech, rate control, stress, and natural pauses.
- Frequency/intensity depend on diagnosis, severity, energy, and support. The 15-minute routine is an optional product example, not a treatment-dose claim.
- NICE recommends speech therapy for communication difficulties in Parkinson's disease and consideration of effort-based speech and, where needed, professionally managed expiratory muscle training. [NICE recommendations](https://www.nice.org.uk/guidance/ng71/chapter/Recommendations).
- Non-progressive acquired-dysarthria studies suggest potential improvement but are heterogeneous and limited; do not claim universal effects for particular exercises. [Systematic review](https://pubmed.ncbi.nlm.nih.gov/30286661/).
- Evidence that nonspeech oral-motor exercises improve speech is limited. Keep lip/tongue preparation brief and immediately transfer to syllables, words, and sentences. [ASHA evidence review](https://pubs.asha.org/doi/10.1044/1058-0360%282009/09-0006%29).

### Objective

The Codex workflow should integrate current features around Today's chosen practice plan, let users choose underlying causes and difficult speaking areas without diagnosing them, compose appropriate task proportions, and design/validate integrated session records and calendar statistics.

### Scope

Included: adult acquired dysarthria, self-practice, adjustable routines, optional 1–4 daily goal, repeated sessions, lip/tongue preparation, breathing/phonation, articulation, prosody/functional sentences, fatigue, stop reasons, calendar/day details, local-first storage, accessibility, safety notices.

Excluded: diagnosis, prescription, swallowing therapy, device-based respiratory strengthening, therapist portals, remote monitoring, and replication of clinical programs.

### Inputs

| Item | Format | Source | Notes |
|---|---|---|---|
| Rehabilitation profile | Local JSON | Onboarding | Cause optional; not diagnostic |
| Daily count goal | Integer 1–4 | Settings | Optional/personal |
| Pre-session condition | Integer/enum | User | Fatigue 1–5 and pain/breathing/swallowing risk check |
| Content | Versioned local JSON/Dart | Bundle | Review version and provenance |
| Voice/recording | Local audio/STT | Microphone | Explicit permission; local retention default |
| Session events | Structured JSON | Player | Start, pause, skip, stop, complete |
| Legacy history | SharedPreferences JSON | App services | Integrated lookup after migration |

### Outputs

| Item | Format | Destination | Notes |
|---|---|---|---|
| Today's routine | Runtime model | Home/player | Chosen duration, reducible for fatigue |
| Integrated session | JSON | Local store | Multiple records on one date |
| Calendar summary | Derived view model | Calendar | Count, time, domains, fatigue |
| Day detail | UI | Selected date | Steps, scores, recordings, stop reasons |
| Weekly summary | Derived JSON/UI | Home/dashboard | Goal days, sessions, time, streak |
| Safety events | Local log | History | Minimize health data; no external transfer |

### Constraints

- App is an aid; no diagnosis/treatment-replacement claims.
- Personalize using selected difficulties/fatigue, not diagnosis alone.
- Do not prompt loud/high-effort phonation with pain, worsening hoarseness, or throat tightness.
- Exclude breath-holding contests, hyperventilation, repeated maximal effort, and resistance devices from default routines.
- Limit nonspeech preparation to 2–3 minutes or less and link to speech.
- MVP is local-first with explicit deletion, retention, and export policies.
- Large text, contrast, one action per screen, spoken/visual guidance, and large targets for tremor/unilateral weakness.
- Routines, timers, history, and calendar work offline.
- Every content item has `clinicalReviewVersion`, `reviewedAt`, `sourceRefs`, `contraindications`.

### Terms

| Term | Meaning |
|---|---|
| Acquired dysarthria | Difficulty executing speech movements from acquired neurological causes such as stroke, TBI, or Parkinson's disease |
| Session | One initiated training record, complete/partial/stopped |
| Daily goal N | Optional user-set 1–4 completions, not a clinical recommendation |
| Warm-up | Brief nonspeech check of comfortable lip/tongue/jaw movement |
| Speech transfer | Immediately connecting preparation to related syllables, words, sentences |
| Clear speech | More distinct placement at a comfortable rate |
| Integrated history | Same session schema regardless of exercise type |

## 2. Workflow definition

### End-to-end flow

Profile/safety → compose today's routine → execute chosen plan → post-session condition → integrated save → calendar/weekly summary.

Example when 15 minutes is selected; do not require every domain each session:

| Segment | Time | Tasks | Principle |
|---|---:|---|---|
| Preparation/condition | 1 min | Posture, shoulder/jaw relaxation, fatigue, risks | Block start for concerning symptoms |
| Comfortable breathing/phonation | 3 min | Slow breathing, comfortable vowels, short phrases | No maximal effort/breath holding |
| Lip/tongue to speech | 3 min | Lip closure/rounding and tongue-tip placement, then `마·바·파`, `라·나·다`, `가·카` | Do not repeat nonspeech movement alone |
| Articulation/rate | 4 min | Difficult syllables → words → short sentences, clear speech, tapping | Accuracy before variation |
| Phonation/prosody/functional sentences | 3 min | Comfortable volume, stress, natural pauses, daily sentences | No loudness competition |
| Finish | 1 min | Fatigue/discomfort/self-rating, optional replay | Encourage rest between sessions |

For high fatigue or extra sessions, suggest a shorter plan or rest without forcing it. The 8-minute version is also optional. Users may exceed N, with rest guidance between consecutive sessions.

### LLM versus code

| LLM | Code |
|---|---|
| Simple feedback tailored to selected difficulties | Timers, duration sums, transitions, storage, calendar |
| Non-diagnostic explanations of omissions/rate/pauses from STT | Objective level/duration calculation and threshold validation |
| Assist review for missing/risky wording | Distribute approved content with fixed versions/sources |
| Propose daily-sentence variations/difficulty | Deletion, migration, deduplication, tests |

#### Step 01: Profile and safety gate

1. **Goal:** establish the minimum profile and safety state for adult acquired-dysarthria self-practice.
2. **Input/output:** existing `RehabProfile`, N, initial fatigue, risk answers → gate outcome and `RehabTrainingProfile`.
3. **LLM decisions:** suggest respiration/phonation/articulation/rate/functional categories for free-text goals without diagnosis.
4. **Code:** validate required consent, adulthood, N range, risks, and schema.
5. **Success:** notice accepted, no risk symptoms, valid profile.
6. **Validation:** JSON schema, boundaries, per-risk UI blocking, user confirmation.
7. **Failure:** block start and show professional/emergency guidance for risks; repair format once, then `NEEDS_USER_INPUT`.
8. **Skill/script:** planned `dysarthria-content-safety`; `scripts/validate_rehab_profile.dart`.
9. **Artifact:** `output/step01_rehab_profile.json`.

#### Step 02: Daily routine composition

1. **Goal:** match chosen time/tasks using goals, recent difficulties, fatigue, and today's count.
2. **Input/output:** profile, approved library, last 7 days → ordered/timed `DailyRoutinePlan`.
3. **LLM:** suggest functional sentences, simple explanations, and variations to reduce repetition fatigue.
4. **Code:** deterministically validate total/per-stage times, chosen domains, contraindications, and versions.
5. **Success:** estimate equals actual task-time sum; include needed speaking tasks and closure. Validate a selected 15-minute example within 14–16 minutes.
6. **Validation:** rule-based routine validator and golden fixtures.
7. **Failure:** fall back to a clinically approved default if personalization lacks content; stop if no approved content exists.
8. **Skill/script:** planned `dysarthria-routine-planner`; `scripts/validate_daily_routine.dart`.
9. **Artifact:** `output/step02_daily_routine.json`.

#### Step 03: Guided training session

1. **Goal:** safely execute with large displays, audio/visual cues, and staged timers.
2. **Input/output:** `DailyRoutinePlan`, microphone permission, control events → per-step events/partial results.
3. **LLM:** brief nonjudgmental feedback within approved bounds.
4. **Code:** timers, pause/resume/skip/stop, TTS, recording, STT, animation.
5. **Success:** users can always stop; consistent time/state after backgrounding; all events recorded.
6. **Validation:** Riverpod transitions, fake clocks, permission denial/resume, accessibility.
7. **Failure:** keep timer/training with self-rating when STT/AI fails; continue without recording when it fails; end immediately on safety stop.
8. **Skill/script:** planned `dysarthria-session-coach`; `scripts/check_session_state_machine.dart`.
9. **Artifact:** `output/step03_session_events.json`.

#### Step 04: Completion and storage

1. **Goal:** preserve complete, partial, and stopped sessions without loss.
2. **Input/output:** events, before/after fatigue, self-rating, optional voice measures → `RehabSession`.
3. **LLM:** 1–2-sentence summary without treatment-effect claims.
4. **Code:** ID/date/duration/completion, score range, paths, version, stop reason.
5. **Success:** same-day sessions never overwrite and restore identically after relaunch.
6. **Validation:** serialization round trip, duplicate IDs, time zones, midnight, legacy migration.
7. **Failure:** retain once in memory and retry; on persistent failure notify and let the user choose whether to delete recordings.
8. **Skill/script:** none; `scripts/migrate_rehab_history.dart`.
9. **Artifact:** `output/step04_rehab_session.json`.

#### Step 05: Calendar and daily detail

1. **Goal:** view practice/counts monthly and open individual dates.
2. **Input/output:** sessions, N, selected month/date → `CalendarDaySummary` and session list.
3. **LLM:** simple weekly trends without causal/clinical claims.
4. **Code:** aggregate counts/minutes/domains/completion by local date; calculate goal state.
5. **Success:** distinguish none/in-progress/goal met/exceeded; selecting a date shows every session.
6. **Validation:** month boundaries, leap years, zone changes, multiple sessions, deletion in unit/widget tests.
7. **Failure:** exclude damaged records and log recovery; full load failure offers retry/export.
8. **Skill/script:** none; `scripts/verify_calendar_aggregation.dart`.
9. **Artifact:** `output/step05_calendar_summary.json`.

#### Step 06: Content governance and release validation

1. **Goal:** validate content, safety, models, and key flows before release.
2. **Input/output:** library, sources, contraindications, tests → approval checklist/report.
3. **LLM:** identify exaggerated medical claims, ambiguous movement instructions, and content beyond self-practice.
4. **Code:** required metadata, time, links, test outcomes, privacy fields.
5. **Success:** all exercises have clinical review, tests pass, safety blocks verified.
6. **Validation:** SLP review, schema, `flutter analyze`, `flutter test`, manual accessibility QA.
7. **Failure:** disable unreviewed content; halt release for safety/storage/calendar test failures.
8. **Skill/script:** planned `dysarthria-content-safety`; `scripts/validate_clinical_content.dart`.
9. **Artifact:** `output/step06_release_validation.md`.

### State model

| State | Entry | Exit | Next |
|---|---|---|---|
| `COLLECTING_REQUIREMENTS` | Incomplete audience/use/time/history requirements | Adult acquired/self-practice/time/history confirmed | `PLANNING` |
| `PLANNING` | Compose routines/models from evidence and current app | Valid plan/approved content | `RUNNING_SCRIPT` or `VALIDATING` |
| `RUNNING_SCRIPT` | Generate/migrate/aggregate | Script success/failure | `VALIDATING` or `FAILED` |
| `VALIDATING` | Schema/safety/tests/clinical review | Results final | `DONE`, `NEEDS_USER_INPUT`, or `FAILED` |
| `NEEDS_USER_INPUT` | Human choice needed for risk, recovery, settings | User answers | `PLANNING` or `DONE` |
| `DONE` | Planning/implementation/validation accepted | Terminal | none |
| `FAILED` | Safety failure or unrecoverable storage error | Terminal | none |

## 3. Implementation specification

### Recommended folder structure

```text
/project-root
  AGENTS.md
  blueprint-acquired-dysarthria-daily-rehab.md
  /.agents
    /skills
      /dysarthria-content-safety
        SKILL.md
        /references
      /dysarthria-routine-planner
        SKILL.md
        /scripts
        /references
      /dysarthria-session-coach
        SKILL.md
        /references
  /lib
    /features
      /rehab_home
      /daily_routine
        /model
        /provider
        /view
      /rehab_calendar
        /model
        /provider
        /view
      /tongue_exercise
      /face_exercise
      /breathing_training
      /practice
    /services
      rehab_profile_service.dart
      rehab_session_repository.dart
      rehab_calendar_service.dart
      rehab_content_service.dart
  /assets
    /rehab_content
      ko-KR.json
  /output
  /scripts
  /docs
```

### AGENTS.md responsibilities

- Prioritize this blueprint and clinically approved content for dysarthria implementation.
- Prohibit diagnosis, guaranteed recovery, or treatment-effect claims; preserve safety blocks.
- Update sources, review version, contraindications, and tests with content changes.
- Preserve `PracticeSession` and `TongueExerciseSession` in local migrations.
- Create and validate new skills through `skill-creator`.

### Custom agents

| Name | Path | Role | Required fields |
|---|---|---|---|
| none | none | One Codex agent plus skills/scripts is enough for MVP; do not delegate clinical-content judgments to autonomous agents | none |

### Skills and scripts

| Name | Type | Role | Trigger |
|---|---|---|---|
| `dysarthria-content-safety` | skill | Medical wording, contraindications, stop criteria, scope | Exercise/safety-copy changes |
| `dysarthria-routine-planner` | skill | Adjustable routines using approved content | Routine/personalization changes |
| `dysarthria-session-coach` | skill | Brief non-diagnostic Korean feedback | Coaching/summary changes |
| `validate_daily_routine.dart` | script | Time, domains, contraindications | Content build/CI |
| `migrate_rehab_history.dart` | script | Convert fragmented history | First update/tests |
| `verify_calendar_aggregation.dart` | script | Date/zone/multiple-session aggregation | Calendar changes/CI |

### Skill creation rules

> During implementation, create every skill defined here using `skill-creator` (`/skill-creator`). Do not manually write SKILL.md: this can cause format and trigger failures.

The specified guarantees are required frontmatter (`name`, `description`), eval-based trigger optimization, `.agents/skills/<skill-name>/` placement, `SKILL.md`/`scripts/`/`references/` structure, progressive disclosure with body ≤500 lines and large references separated, and prompt-based quality validation.

### Core artifacts

| Path | Format | Producer | Purpose |
|---|---|---|---|
| `output/step01_rehab_profile.json` | JSON | Step 01 | Safety-cleared profile |
| `output/step02_daily_routine.json` | JSON | Step 02 | Executable chosen routine |
| `output/step03_session_events.json` | JSON | Step 03 | State/performance events |
| `output/step04_rehab_session.json` | JSON | Step 04 | Persistent session model |
| `output/step05_calendar_summary.json` | JSON | Step 05 | Monthly/daily aggregates |
| `output/step06_release_validation.md` | Markdown | Step 06 | Clinical/technical release validation |

Recommended additional models:

```text
RehabTrainingProfile
  id, acquiredCause?, primaryDifficulties[], dailySessionGoal,
  preferredSessionMinutes, fatigueRule, acceptedSafetyNoticeAt

RehabSession
  id, localStartedAt, localEndedAt, timezoneOffset, status,
  routineVersion, completedModules[], durationSeconds,
  fatigueBefore, fatigueAfter?, discomfortFlags[], stopReason?,
  pronunciationSummary?, recordingRefs[]

CalendarDaySummary
  localDate, completedCount, partialCount, totalMinutes,
  goalCount, goalStatus, modulesCompleted[], averageFatigueBefore?
```

Core screens:

```text
Launch → Today's training Home
           → Today's plan [Start / Resume]
           → Training: articulation / sentences / daily situations / voice / rate and pauses
           → Recent practice and rest guidance
       → Chosen-plan player: condition → tasks → related daily sentences → finish
       → Calendar: monthly goal state → date → session list/details
       → Settings: daily N, reminders, recording retention, safety notice
```

Calendar: blank for no records; gray dot for partial-only; blue dot plus completed/goal for ≥1 but below N; green circle at N; green circle plus +count above N. Details show start, chosen duration, complete/partial/stopped, modules, before/after fatigue, playback/deletion.

Initial implementation priorities:

1. P0: integrated `RehabSession`, repository, legacy migration.
2. P0: Today and chosen-plan orchestrator.
3. P0: safety blocks, fatigue-based shorter routine, stop records.
4. P0: monthly calendar/day details.
5. P1: task proportions based on difficult sounds.
6. P1: reminders and goal notifications.
7. P2: optional backup/export and professional PDF/CSV sharing.

## 4. Validation checklist

- [x] Every workflow step has all 9 required fields.
- [x] Artifacts follow `output/stepNN_<name>.<ext>`.
- [x] LLM/code responsibilities separated.
- [x] Human review points explicit.
- [x] Skills use `.agents/skills/...`.
- [x] Custom subagents use `.codex/agents/*.toml`.
- [x] Skill changes mention `skill-creator`.
- [ ] SLP reviews all instructions/contraindications/stop criteria before release.
- [ ] Calendar tested for N=1,2,3,4 and extra sessions.
- [ ] Midnight, zone changes, leap years, and forced-exit recovery tested.
- [ ] Safe practice/history without STT, AI, or microphone permission.
- [ ] Nonspeech lip/tongue tasks transfer to related sounds.
- [ ] Large text, screen readers, contrast, and targets checked on devices.

## 5. Identity, features, and menus — 2026-09-25

### 5.1 Conclusion and scope

**Identity: a rehabilitation practice aid helping adults with acquired dysarthria repeat personally useful speech at home, compare recordings, and continue at a manageable effort.** The user confirmed this adult acquired/self-practice scope.

Most features are worth reusing. The central problem is that tools have multiplied as equal menu entries, hiding the purpose and sequence of practice. Neither consonants alone nor oral movement alone adequately represents the product. Connect practice to speech needed in daily life.

Review source: `ca261bb`. Findings from September 13 were not reused as current defects. Current code already has unscored free speech, text-match labels, untimed word practice by default, oral-training checkpoints, and professional-only locks; retain these safeguards.

This is product/UX design, not clinical efficacy or individual prescription validation. Screens and limits are in section 11 of the [menu design](docs/adaptive-ui-menu-architecture.en.md). Current source was traced directly because no completed graphify graph existed.

### 5.2 Identity criteria

A feature must directly help at least one of:

1. Actually speaking needed sounds/sentences.
2. Listening to recordings, retrying, or communicating in daily situations.
3. Reducing fatigue/interaction burden and supporting stop/resume/history.

Visualizations, long AI chats, high numbers, or more exercise types are not independent goals. Move unrelated analysis to details. Keep typed/selected input as access support but do not count it as spoken practice.

Primary users are adults with acquired dysarthria; caregivers may assist settings/comparison. Consider co-occurring aphasia, apraxia, or cognitive difficulties through listen-and-repeat and short instructions, without differential diagnosis or applying identical treatment universally. For progressive conditions, maintaining needed communication is a valid success goal alongside improvement.

### 5.3 Feature decisions and evidence

| Existing feature | Decision | Design | Evidence |
|---|---|---|---|
| Consonant → syllable/word/sentence | Core | Training > Speak clearly; expand initial/final choices; connect useful words | `consonant_training_screens.dart`, `consonant_training_session_service.dart` |
| Short/long reading, personal sentences | Core | Group as Speak in sentences with length choice, not severity grade; listen/repeat and pause cues | `practice_screen.dart`, `practice_mode.dart` |
| Record/replay/same-item comparison | Strengthen | Common completion flow: current → previous same sentence → retry | `practice_screen.dart`, `recording_library_screen.dart` |
| Word game | Adapt | Default Speak words, one at a time, untimed; falling/speed challenges only optional later | `word_game_screen.dart:95`, `practice_provider.dart:142` |
| Free conversation | Structure | Everyday speaking with one goal, short turns, Finish; free conversation nested as optional | `_CommunicationHub` in `adaptive_app_shell.dart`, `_buildPrompt` in `ai_service.dart` |
| Nonspeech tongue/lip tasks | Conditional aid | Not mandatory; brief reviewed tasks linked to sounds | `guided_training_catalog.dart`, `GuidedTrainingExercise` |
| Alternating syllables | Conditional | Optional Speak clearly task; no universal maximal-speed/repeat goal | `guided_training_catalog.dart:317` |
| Breathing/phonation | Keep with purpose | Comfortable voice / Speak to sentence end; exclude breath holds, fast deep breaths, resistance; retain locks | `guided_training_player_screen.dart:70` |
| Pitch/volume | Supporting feedback | Optional within relevant practice, not normalization/loudness competition | `voice_analysis_screens.dart` |
| Match a target tone | Reduce/conditional | Remove from default list; retain for individual reasons, not flagship rehabilitation | Same file `_items` |
| Waveform/frequency/spectrogram | Detailed tools | History > Recording details > More measurements; never require graph interpretation | Same file `_items` |
| 10-second/reference recording | Consolidate | Shared recording and reference selection; fewer duplicate entries | Same file `_items` |
| Mouth camera | Optional | Off by default; separate consent/deletion; complete flow without capture | `mouth_video_preview_sheet.dart`, `mouth_video_recorder_service.dart` |
| Text match | Reference only | Collapsed details; never sole basis for outcomes, intelligibility, weak sounds, or automatic prescription | `ai_service.dart:40`, `practice_history_service.dart:14` |
| Server analysis | Optional/later | Keep separate transfer consent; method/version/uncertainty/status; alignment is not validated accuracy | `pronunciation_analysis_client.dart` |
| Downloads/language/microphone | Settings | Rename Download resources to Offline content; device check also available on failure | `_SettingsHub` |

Conversation, pitch tools, and falling games are not inherently inappropriate. Equal top-level placement without purpose obscures identity. Do not remove typed/selected communication support merely because it is not spoken practice.

### 5.4 Structural priorities

| ID | Finding/impact | Decision |
|---|---|---|
| IA-01 | Training has only oral/breathing and voice-tool cards in `ExerciseMenuScreen`, omitting consonant/sentence work | One hub for all training |
| IA-02 | Consonant card precedes recommendation; top also duplicates tools/recordings/history/results | One primary Start today's practice / Resume |
| IA-03 | Phone `_buildCompact` returns `_MoreHub` for index ≥3, so Communication(3)/Settings(4) draw More | Four explicit destinations; width regression tests; physical-phone verification later |
| IA-04 | Training calendar/history opens a list-only `PracticeHistoryScreen` | Call it Practice history until integrated calendar exists |
| IA-05 | Separate general/analysis/oral stores; Home counts only `practice.history` | Shared index distinguishing sessions and attempts |
| IA-06 | `_recommendMode` chooses words below text-match 75, otherwise cycles last mode | Goals/chosen items/recent plan first; no difficulty changes from match alone |
| IA-07 | Daily sentences launches `/practice` without mode/content | Typed launch spec carries chosen situation |
| IA-08 | Labels favor Performance/Average score/Phonation results while records are fragmented | Default to Practice changes/My recordings/Words practiced |

### 5.5 Target information architecture and screen contracts

Use **Today · Training · History · Settings** in the same order and meaning on every device; only bottom/side navigation changes with width. Detailed routes are in the [adaptive-menu design](docs/adaptive-ui-menu-architecture.en.md).

| Screen | User question | Default content | Primary action |
|---|---|---|---|
| Today | What should I do now? | One goal, selected plan, estimate, resumable state | Start or Resume |
| Training | Choose another practice? | Clear speech, sentences, daily situations, comfortable voice, rate/pauses | Choose purpose and start |
| History | What did I do/can I hear again? | Dated sessions, complete/partial/stopped, fatigue, same-sentence audio | Listen / Practice again |
| Settings | How do I adapt it? | Plan, text/guidance, recordings, language, content, device check | Adjust each item |

First use: brief purpose → daily goal/comfortable input → short plan → condition → practice. Do not ask every exercise, diagnosis detail, and score upfront. Make How long you have practiced optional because it does not determine the core plan.

Returning: Today → condition → listen/speak/replay → next/finish → today's history. Target one action from Home to preparation and two to start after onboarding; report safety/permission actions separately.

One task, one instruction, one primary button. Label Stop recording while recording and Stop listening during playback. Keep Rest/Finish discoverable. Finalize or cancel an attempt before switching tasks during recording/analysis.

Start results with facts such as “You practiced this sentence 3 times,” then Listen / One more / Finish. Put text match and waveform in collapsed Reference information. Save typed-only as Sentence preparation and viewed-only as Guidance viewed, distinct from speech.

### 5.6 Connect plan and content

Preserve 15-/8-minute examples, but match selected 5/10/15-minute goals to actual content time. These are usability values, not universal doses. Separate Daily goal and This session's duration in fields/labels. Counts are optional; do not reward longer practice as inherently better.

Choose (1) saved plan, (2) recent item, (3) reviewed short default. Difficulties are browsing filters, not diagnoses. AI supplies simple approved guidance and a conversation partner, not unrestricted prescriptions.

Example: chosen word → daily sentence containing it → request/explanation scenario → replay. Prepend comfortable phonation or reviewed preparation when needed; do not force every domain each session. Offer listening/repeating for reading difficulty and label examples as TTS or reviewed recordings.

Ask fatigue at every session, not reuse the day's first answer. Allow shorter practice/rest. High fatigue must not trigger increased intensity or forced repeats. Preserve high-intensity/resistance/professional-only locks through menu changes.

### 5.7 History and implementation

Keep Flutter/Riverpod and existing players. Add read adapters and shared launch information before replacing every store.

```text
TrainingLaunchSpec
  moduleId, goalId, contentIds[], scenarioId?, planId?, stepId?,
  repeatTarget?, plannedSeconds?, inputMode, contentVersion

RehabSessionSummary
  id, planId?, startedAtUtc, offsetAtStart, localDateAtStart,
  status[inProgress|completed|partial|stopped], activeSeconds,
  plannedSteps, completedSteps, fatigueBefore?, fatigueAfter?,
  selfReportedEase?, sourceRefs[], schemaVersion

PracticeAttemptRef
  id, sessionId?, sourceType, sourceId, contentId?, contentVersion?,
  modality[speech|typed|selected|viewOnly], recordingRef?,
  evaluationMethod?, evaluationVersion?, analysisStatus
```

- Deduplicate by `sourceType + sourceId`; do not count one consonant utterance twice from session/attempt stores.
- Some old `PracticeSession` entries are individual utterances. Do not infer historical routines from time gaps; label ungrouped data Previous individual practice.
- Routine completions, utterance attempts, and time differ. Do not mix typing, chat messages, or exercise loops into utterance counts. Use Unknown modality when evidence is insufficient.
- Active time excludes pause, analysis wait, and background. Do not directly compare ambiguous legacy durations with new active time.
- Initially retain original stores and build a combined list with read adapters. Only new routines receive parent sessionId/stepId. Migrate writes later with backups/deduplication/validation.
- New integrated records use one write path and the same sessionId across partial saves, exits, and return. Idempotent upsert prevents duplicate completion.
- Deletion updates source/index/recording refs; check other references before deleting shared files. Preview scope/files before export.
- Compare same user/sentence/method/version; explain device/mic/noise differences. Do not combine unrelated text-match scores into a Recovery score.

| Area | Responsibility |
|---|---|
| `adaptive_app_shell.dart` | Four enum destinations, preserve state on resize, fix compact routing |
| `practice_mode_selection_screen.dart` | Plan/resume first, remove duplicate tools and score recommendations |
| `exercise_menu_screen.dart` | All-speaking-training hub |
| `practice_mode.dart` | Change labels first, preserve stored values |
| `chat_screen.dart`, `chat_provider.dart`, `ai_service.dart` | Explicit scenario/turns/goals, no pronunciation diagnosis, offline fixed dialog |
| History services | Shared read adapters/sourceRefs |
| `rehab_profile_service.dart` | Separate day/session goals; timestamp fresh fatigue |
| `guided_training_catalog.dart` and resources | Domains, sound transfer, review/source/exclusion metadata |
| `app_ko.arb`, `app_en.arb`, `AppStrings` | Update menus/states/buttons together; remove English-only notices from Korean UI |

### 5.8 Failures, accessibility, and acceptance

| Situation | Behavior | Acceptance |
|---|---|---|
| Mic denied | Listening/preparation/history remain; explain again when recording | No global block or fake speech |
| STT failed/offline | Playback/manual completion | No zero/failure score or automatic difficulty shift |
| AI failed | Short fixed question or free recording | Core practice/storage continues |
| Cancel analysis | Preserve audio; late results cannot attach elsewhere | Check attemptId/canceled status |
| Missing video | Reviewed still/text/voice | Missing media does not produce unsafe instructions |
| Stop/exit | Restore step, save partial | No duplicate completion/time inflation |
| Save failed | Explicit unsaved state and Retry | No premature success toast/count |
| Fatigue/discomfort | Rest/reduce/stop and help guidance | No punishment through failure/streak loss |
| 200% text | Instructions/record/stop/back accessible | No overlap/occlusion at 360 px |
| Motor/visual limitations | Labels, large targets, automatic advance off | Product target ≥56 logical px for core controls |
| Screen reader | Labels, focus order, recording announcements | Separate real VoiceOver/TalkBack checks |

Clinical review gates content release. Design/tests alone do not approve efficacy or complete accessibility compliance. Acute-change/severe-discomfort copy and branches also require professional review.

### 5.9 Order and success measures

Apply sections 0–4 in this revised sequence; full storage migration is not a prerequisite for menu cleanup.

**P0 — Identity and entry:** five menus, compact routing fix, complete Training hub, one Home primary action, corrected calendar/performance labels, remove score-based mode recommendations. Verify every menu mapping and preserve routes/history.

**P1 — Connect practice:** launch specs/read adapters, resume, word→sentence→scenario, recording comparison, fresh fatigue. Finish the same session and find its history offline, after analysis failure, and after interruption.

**P2 — Expand after validation:** calendar, chosen reference recordings, rate/pause cues, optional sharing, reviewed personal plans. Defer outcome charts, richer AI dialog, and more animation until core flows are validated.

Proposed usability study: 5–8 target users, caregivers as needed, and SLP review; tasks are start today, rest/resume, re-record same sentence, find yesterday's audio, and view guidance without a microphone. No recruitment/testing occurred in this work. This is a product hypothesis, not a clinical-study sample calculation.

Observe unaided start rate, wrong destinations, resume success, recording retrieval, save failures, fatigue responses, and perceived burden. Remote patient-audio collection is not enabled by default. Retention/time increases alone do not prove treatment effectiveness.

### 5.10 Evidence and open decisions

ASHA addresses respiration, phonation, resonance, articulation, prosody, communication needs, and participation. Connecting consonants to everyday communication is this design's interpretation of that framework. [ASHA](https://www.asha.org/Practice-Portal/Clinical-Topics/Dysarthria-in-Adults/).

Typed/selected input has independent communication-support value. Separate it from training counts without removing access. [ASHA AAC](https://www.asha.org/Practice-Portal/Professional-Issues/Augmentative-and-Alternative-Communication/).

Open: final visibility of conversation/games, clinical reviewer, primary devices, and how individual plans are received. Until decided, retain redesigned daily-situation dialog and untimed word repetition as proposals. Therapist portals, diagnosis, automatic prescription, and pediatric expansion remain outside scope.
