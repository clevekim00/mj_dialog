# Specification: English-version launch

[한국어](spec-english-version-launch.md) | [English](spec-english-version-launch.en.md) | [All documents](docs/README.en.md)

## Overview

Expand Speech Rehab into one app supporting Korean and US English. On first install follow the OS language; Settings can override with System default, Korean, or English (US). Apply the choice consistently to UI, STT, TTS, content, AI prompts, and pronunciation models.

The first English release targets US-English-speaking adults with acquired dysarthria and caregivers. Remain a repeated-practice aid, not a substitute for treatment or diagnosis.

## Goals

- One iOS/Android/macOS app and history system.
- Automatic OS selection with an in-app override anytime.
- Route analysis to Korean or English MFA resources by request language.
- Provide English consonants, words, short and functional sentences appropriate to the clinical context.
- Record language/model/content versions; never mix scores/baselines across languages.
- Prepare store review, privacy, accessibility, and clinical wording for English release.

## Scope

### Included

`ko-KR`/`en-US` localization; OS/manual selection; STT/TTS/AI prompts; bundled language packs/CDN updates; API v1 language extension; Korean/English MFA routing; phoneme/consonant-cluster, word, and short-sentence content; per-language history/baselines/model versions; US App Store/Play Store preparation.

### Excluded

Separate British/Australian/Indian scoring in release 1; diagnosis/disability grading/effect guarantees; code-switching analysis within one utterance; accuracy scores from MFA alignment alone; pediatric articulation content/criteria.

## Product decisions

| Item | Decision |
|---|---|
| App | One Korean/English app |
| English variety | `en-US` first |
| New-install default | OS language; unsupported OS language → `en-US` |
| Existing users | One-time `ko-KR` migration if no saved value, preserving Korean experience |
| Supported list | Immediate bundled bootstrap catalog; signed remote catalog updates enablement/order/pack versions |
| Manual choice | System default and compatible catalog-approved languages |
| API | BCP 47 `language` on every analysis request |
| Models | Server selects dictionary/acoustic model/phone map by language |
| Scores | Separate baselines by language/model revision; no MFA-only scoring |
| UI strings | Downloadable runtime packs first; bundled ARB for bootstrap/emergency fallback |
| Training resources | Separate required core and optional media; activate only fully installed versions atomically |
| Remote additions | Expose only languages compatible with binary locale/font/TTS/STT/analysis capabilities |

## Language resolution

```text
Saved explicit language → otherwise OS locale → exact locale match
→ language-code match → unsupported language falls back to en-US
```

```text
languagePreference = system | <BCP-47 locale>
resolvedLanguage = <BCP-47 locale allowed by both catalog and client capabilities>
```

With `system`, re-resolve OS changes on resume/relaunch. An explicit locale ignores OS changes. If a saved locale is suspended or incompatible, switch to an installed fallback and explain why.

Use `flutter_localizations`, `intl`, and ARB:

```text
lib/l10n/app_ko.arb
lib/l10n/app_en.arb
lib/l10n/l10n.yaml
```

Move hardcoded Korean into stable keys, including exercise names, titles, errors, safety, accessibility, and notifications. Generated ARB covers bootstrap/framework fallback; mutable product copy comes from a runtime repository. Catalog enablement remains inside binary-declared `clientSupportedLocales`; it cannot bypass rebuild requirements for native permissions, font shaping, or framework locales.

## Settings UX

Provide Language and Download resources from the bundled/remote catalog, not hardcoded lists.

```text
Language
├── System default
├── Installed: Korean
├── Download required: English (US) · 48 MB
└── Update available: <catalog-approved language>
```

- Show resolved language, e.g. System default · English (US).
- Redraw immediately after switching, but finish/cancel active recording or analysis first.
- Explain that screens, voice guidance, content, and analysis language change together.
- Preserve history and display language badges.
- Block analysis if practice/content languages differ; reload the correct pack.
- For uninstalled languages, show required size/network conditions and Download and switch; retain current language during download.
- States: Available, Download required, Downloading, Installed, Update available, Incompatible with this app, Temporarily suspended.
- Resource center: automatic updates, Wi-Fi only, pause/resume/retry, per-language storage, optional-pack deletion.

## Shared language context

Use one `AppLanguageController`; features must not read OS locale independently or hardcode `ko-KR`.

```text
AppLanguageController
├── LanguageRegistry (catalog ∩ client capabilities)
├── RuntimeLocalizationRepository
├── STT locale
├── TTS voice locale
├── content pack locale
├── AI prompt language
├── pronunciation API language
└── history metadata
```

The controller chooses locale; `ResourcePackManager` downloads, verifies, and activates. Commit a switch only after required UI strings and core content are installed/verified.

| Feature | ko-KR | en-US |
|---|---|---|
| STT | `ko-KR` | `en-US` |
| TTS | `ko-KR` | `en-US` |
| Content | `ko_consonant_core` | `en_us_consonant_core` |
| MFA dictionary | `korean_mfa` | `english_us_mfa` |
| MFA acoustic | `korean_mfa` | `english_mfa` |
| AI prompt | Korean feedback | US-English feedback |

If the platform lacks selected STT/TTS, mark only that feature `unavailable`; retain visual training/recording. Do not silently fall back to another language's voice.

## Analysis API contract

Add required `language` to `POST /v1/analysis/jobs` multipart form.

```text
audio              file, required
text               string, required
language           BCP 47 string, required: ko-KR | en-US
target_phone        language-specific phone id, required
position            onset | medial | coda, required
target_occurrence   integer, optional, default 0
content_version     string, required
baseline_score      number, optional
```

English repeats phones and has clusters, so add `target_occurrence`. Existing Korean clients use `position=onset|coda`, `target_occurrence=0`. `medial` supports internal English consonants.

Return the actual language/model applied:

```json
{
  "jobId": "...",
  "status": "completed",
  "language": "en-US",
  "modelVersion": "mfa-english-v3.1.0",
  "contentVersion": "en-US-1.0.0",
  "overallPracticeScore": null,
  "phonemes": [],
  "disclaimer": "Automated practice feedback; not a clinical diagnosis."
}
```

Validation:

- Unsupported language: `422 unsupported_language`.
- Content/request mismatch: `409 language_content_mismatch`.
- Phone outside inventory: `422 unsupported_phone`.
- Select models only from request `language`, never `Accept-Language` or server OS locale.
- Freeze language, model revision, and dictionary revision when creating the job.
- Return language-independent error codes; localize in the app.

## Server architecture

Replace one global MFA backend with a language registry.

```text
Analysis request(language)
→ LanguagePolicy validation
→ BackendRegistry.resolve(language)
→ ko-KR: KoreanMfaBackend
→ en-US: EnglishMfaBackend
→ normalized result with language/model metadata
```

Recommended environment variables:

```text
SUPPORTED_ANALYSIS_LANGUAGES=ko-KR,en-US
MFA_KO_KR_DICTIONARY=korean_mfa
MFA_KO_KR_ACOUSTIC_MODEL=korean_mfa
MFA_EN_US_DICTIONARY=english_us_mfa
MFA_EN_US_ACOUSTIC_MODEL=english_mfa
```

`GET /ready` reports overall and language-specific readiness:

```json
{
  "ready": true,
  "languages": {
    "ko-KR": {"ready": true, "modelVersion": "mfa-korean-v3.0.0"},
    "en-US": {"ready": true, "modelVersion": "mfa-english-v3.1.0"}
  }
}
```

A failure in one language disables only its analysis, not the whole server. Use separate MFA temporary directories per request.

## English phoneme and content design

Create English content anew, rather than translating Korean exercises.

### Target inventory

- Stops: /p, b, t, d, k, g/.
- Fricatives: /f, v, θ, ð, s, z, ʃ, ʒ, h/.
- Affricates: /tʃ, dʒ/.
- Nasals: /m, n, ŋ/.
- Approximants/liquids: /w, j, r, l/.
- Later: clusters, vowel contrasts, stress, rhythm, rate.

Separate spelling from phones. Manage `th` as separate /θ/ and /ð/ targets; encode context-dependent phones for identical spellings.

### Content pack

```text
assets/pronunciation/content/en_us_consonant_core.json
locale: en-US
version: 1.0.0
targets
words
minimalPairs
shortSentences
functionalSentences
ttsMetadata
clinicalReview
```

Recommended minimum per target: 20 words for each initial/medial/final position; 10 minimal pairs; 20 short sentences of 4–8 words; 10 functional hospital/home/phone/caregiver sentences; slow/normal TTS metadata.

Use natural adult language, not childish wording. A native US-English SLP reviews phone positions, difficulty, function, and cultural appropriateness.

## Audio, STT, and TTS

- Create STT with `resolvedLanguage`.
- Remove fixed iOS `SFSpeechRecognizer(locale: ko_KR)` and native TTS `ko-KR`.
- Inspect installed voices per language and save an available voice ID.
- English defaults to `en-US`, with SLP-reviewed slow/normal rates.
- TTS is a listening/imitation aid, not the reference signal for acoustic scoring.
- STT mismatch is not equivalent to an articulation error; keep it separate from phoneme analysis.

Apple Speech requires a locale at recognizer creation and separate checks for supported locale and temporary service availability. Distinguish settings choices from actual device capability checks.

## Clinical and scoring policy

English MFA aligns words/phones to the transcript. Alignment itself has no pronunciation accuracy score; keep `practiceScore` and `gop` nullable in English too.

Before adding scores require adult acquired-dysarthria English data; correlation/agreement with US-English phone-level clinician ratings; reporting by severity, sex, age, accent, device, noise; independent language/model baselines; within-person change rather than rankings; no score at low confidence, OOV, or alignment failure.

Do not label nonnative or regional accents as errors. Initial copy must clarify that this is target-utterance repetition, not accent assessment.

## Data and history migration

Add:

```text
language
contentLocale
contentVersion
analysisModelVersion
dictionaryVersion
ttsVoiceId (optional)
```

Migrate old history to `language=ko-KR`. Compute baselines/previous best by `targetId + language + modelVersion`. Preserve records on switching; default to current-language history and offer a language filter. Namespace targets, e.g. `ko-KR:onset:k`, `en-US:initial:θ`.

## Store and compliance preparation

- English name, subtitle, description, keywords, screenshots, preview, and privacy policy.
- Localize microphone, speech-recognition, and camera permission explanations.
- Explain transfer timing/purpose, retention, and deletion in-app.
- Explicit remote-analysis consent; preserve a basic path without remote analysis.
- Avoid diagnostic or guaranteed-effect claims; align in-app and store safety copy.
- Validate US-English VoiceOver/TalkBack, dynamic text, contrast, and large targets.
- Prepare English support email, FAQ, analysis-failure and deletion procedures.

## Failure modes

| Situation | Handling |
|---|---|
| Unsupported OS language | `en-US`; show supported choices |
| Corrupted preference | Restore `system`; diagnostic log |
| Unsupported STT locale | Disable STT only; retain recording/playback |
| Missing TTS voice | Installation guidance or another voice in the same locale |
| English MFA not ready | English analysis unavailable; Korean continues |
| Content/analysis mismatch | Block before analysis; reload current pack |
| Analysis during switching | Existing job completes in original language; badge in new UI |
| English OOV | Explain and skip, or use approved supplementary lexicon |
| Low alignment confidence from accent/disability | Hide score; offer retry/professional consultation |
| CDN failure | Use that language's bundled core |

## Test strategy

### Flutter

Test OS `ko`/`en`/unsupported resolution; system/manual priority; persisted selection; complete Korean/English ARB keys; STT/TTS/content/API switching together; old-install `ko-KR` migration; separate history/baselines; English overflow, large text, and accessibility semantics goldens.

### Server

Test missing/unsupported language 422; backend routing; inventory/TextGrid parsing; content mismatch 409; per-language readiness; concurrent model/temp-file isolation; language/modelVersion/disclaimer responses; OOV, timeout, missing models, poor signal.

### Release QA

Physical iOS/Android STT/TTS for both languages; OS change/manual override while running; native US-English and adult dysarthria usability; SLP content/safety approval; manual TextGrid comparison against real English audio.

## Delivery plan

### Phase 0 — Freeze contracts, 1 week

Locales/resolution, API language/response, migration, English authoring/review guide. Done when app/server/content share locale identifiers and draft contract tests are approved.

### Phase 1 — Internationalization foundation, 2 weeks

ARB UI, `AppLanguageController`/settings, remove STT/TTS hardcoding, history locale. Done when OS/manual choice consistently changes core UI/STT/TTS.

### Phase 2 — Content and training UX, 3–4 weeks

Inventory/packs, consonant positions/minimal pairs/short-sentence UI, functional sentences/TTS review, initial SLP review. Done when every first-release phone meets minimum volume and review status is recorded.

### Phase 3 — Multilingual analysis, 2 weeks

Backend registry/validation, model/dictionary installation, phone mapping/occurrence/OOV, readiness/observability/tests. Done when both real-audio alignments work simultaneously and invalid combinations are blocked.

### Phase 4 — Validation and stores, 3–4 weeks

Native-speaker/SLP/user QA, English privacy/safety/support, store metadata/screenshots, TestFlight/Play closed testing and fixes. Done with zero critical or major locale defects and approved SLP/privacy/store checklists.

Estimated MVP: 9–12 weeks with parallel work. Clinical English scoring development/validation is a separate later track.

## Implementation status

Multilingual runtime foundations implemented as of 2026-08-26:

- Generated Flutter `ko`/`en` ARB and `supportedLocales`.
- New-install OS resolution, unsupported `en-US` fallback, Korean-install migration.
- Persistent System default/Korean/English (US) settings.
- Language passed to STT/TTS/AI; native iOS Korean hardcoding removed.
- Separate bundle/download paths per language.
- Bundled `en-US` seed for initial/medial/final flow.
- Required API `language`, optional `target_occurrence`, English `medial` contract.
- Per-language MFA registry/readiness/configuration.
- English phone map and `english_us_mfa`/`english_mfa` installation automation.
- Separate results/baselines and localized disclaimers/errors.
- Tests for resolution, migration, preferences, content, routing, and mapping.

The English bundle is a seed for flow/model-contract validation. Full inventory quotas, all UI strings migrated to English ARB, US SLP review, target-user evaluation, and store/privacy documents remain release gates. Automatic generation or translation alone does not complete them.

`ConsonantContentRepository` supports per-language JSON manifest download, SHA-256 verification, and atomic temporary-file replacement of `current.json`. It covers only consonant content, without catalog signatures, dependencies, rollback, storage policy, UI packs, or large-media background resume. The platform below generalizes this later.

## Remote resource-pack platform

### Goals and boundaries

Separate a small binary from mutable resources, like downloadable game data.

- Bundle minimal `ko-KR`/`en-US` catalog, UI, and core content for first launch/offline.
- Independently update languages, UI, consonant/sentence/game content, images/audio/video through CDN.
- Data only: no Dart/native code, libraries, scripts, or permission declarations.
- Intersect catalog with locale/font/plural/STT/TTS/analysis capabilities.
- Separate changes to privacy/consent/treatment-safety meaning from ordinary copy; record legal/clinical revision and renewed-consent requirements.

Remote additions require both `catalog enabled` by operations and `client compatible` declared by the installed binary. This allows content/copy updates without promising that new MFA integration or native permission translations can avoid binary updates.

### Resource classes

| Type | Examples | Install policy | Updates |
|---|---|---|---|
| Bootstrap catalog | Fallback languages, keys, schema | Bundled mandatory | App update |
| UI strings | Menus, errors, accessibility, unit/date rules | Required for chosen language | Small/frequent |
| Core content | Consonants, vowel-combination words, sentences, clinical metadata | Required for training language | Locale/feature specific |
| Game | Stages, reward-rule data, questions | Required/optional on entry | Code stays in binary |
| Media | Guides, reviewed audio, images, animation | Optional | Large; background/resume |
| Models | On-device speech/LLM | Separately optional | Large; verify device requirements |

Install `requiredPacks` before switching; fetch `optionalPacks` on feature entry. Do not bundle the roughly 1.35 GB Gemma model or video into UI/core download units.

### Catalog and manifest contracts

Keep the root catalog small/cacheable:

```json
{
  "schemaVersion": 1,
  "catalogVersion": "2026.09.0",
  "generatedAt": "2026-09-01T00:00:00Z",
  "minClientVersion": "1.4.0",
  "keyId": "catalog-2026-01",
  "languages": [
    {
      "locale": "en-US",
      "nativeName": "English (US)",
      "fallbackLocale": "en",
      "enabled": true,
      "minAppVersion": "1.4.0",
      "capabilities": {
        "ui": true,
        "content": true,
        "tts": true,
        "stt": true,
        "analysis": true
      },
      "requiredPacks": ["ui.en-US", "consonant-core.en-US"],
      "optionalPacks": ["guided-video.en-US"]
    }
  ],
  "signature": "base64-ed25519-signature"
}
```

Pack manifests point to immutable version URLs:

```json
{
  "schemaVersion": 1,
  "id": "ui.en-US",
  "type": "ui_strings",
  "locale": "en-US",
  "version": "2026.09.2",
  "minAppVersion": "1.4.0",
  "url": "https://cdn.example.com/packs/ui/en-US/2026.09.2.zip",
  "sizeBytes": 48123,
  "sha256": "...",
  "compression": "zip",
  "dependencies": [],
  "files": [{"path": "strings.json", "sizeBytes": 92031, "sha256": "..."}],
  "keyId": "pack-2026-01",
  "signature": "base64-ed25519-signature"
}
```

Verify catalog/manifest with bundled Ed25519 public keys; verify packs/files with SHA-256. Never overwrite a version URL. Reject incompatible `minAppVersion`, schema, or dependencies before download. Block zip traversal, symlinks, excessive unpacked size/file counts. Allow JSON and approved media MIME only, not HTML/executable content.

### Internal architecture

```text
Presentation
├── LanguageSettingsScreen
├── ResourceCenterScreen
└── DownloadRequiredSheet
        ↓
Riverpod Controllers
├── AppLanguageController
└── ResourcePackController
        ↓
Domain Services
├── LanguageRegistry
├── RuntimeLocalizationRepository
├── ResourcePackManager
└── ResourceDownloadCoordinator
        ↓
Data
├── ResourceCatalogRepository
├── ResourceIndexStore
├── BundledResourceSource
├── CdnResourceSource
└── SignatureVerifier
```

Responsibilities:

- `ResourceCatalogRepository`: immediate bundle, verified cache, conditional CDN requests/fallback.
- `LanguageRegistry`: catalog/`ClientCapabilities` intersection and language/feature states.
- `ResourcePackManager`: dependency planning, free space, staging, verification, installation, activation, rollback, deletion.
- `ResourceDownloadCoordinator`: Dio for small catalogs/strings; a directly declared background downloader for large media/models, pause/resume, OS jobs.
- `ResourceIndexStore`: installed/active/previous versions, size, last use, pinned sessions in SQLite or atomic index.
- `RuntimeLocalizationRepository`: lookup, placeholder/plural checks, fallback, change notifications.
- `ConsonantContentRepository`: remove networking/install responsibilities; typed decoder for active content.

Replace `AppLanguagePreference` enum with a value object holding `system` or arbitrary BCP-47, validated by `LanguageRegistry`. Keep generated `AppLocalizations` for bootstrap; gradually move mutable screens to `context.tr('training.start', args)`.

```text
Verified downloaded selected-locale pack → bundled selected-locale pack
→ catalog fallback locale → bundled en-US
→ development: [missing:key]; release: safe generic wording
```

Declare placeholder names/types and plural categories; compare every locale with the base during build/deploy. Allow limited Markdown only through a dedicated renderer; never render server strings directly as HTML.

### Storage and atomic activation

```text
Application Support/resource_packs/
├── catalog/
│   ├── active.json
│   └── previous.json
├── locales/<locale>/
│   ├── ui_strings/<version>/
│   ├── content/<pack-id>/<version>/
│   └── media/<pack-id>/<version>/
├── shared/<pack-id>/<version>/
├── staging/<download-task-id>/
└── state/resource_index.json
```

Plan → reserve space → download to staging → signature/hash verification → safe extraction → schema validation → swap active pointer. Preserve current active version on any failure. Keep one previous known-good version after success and automatically roll back on startup/parsing errors.

Evict optional media/models by LRU first. Never automatically delete current required packs, session-pinned versions, or bootstrap. History retains `locale`, `contentPackId`, `contentVersion`, `analysisModelRevision` for reproducibility.

### Launch, switching, and training entry

Launch immediately from bundled/cached catalog and active packs; refresh catalog in background; compute compatible updates; download automatically or notify according to policy.

Switch: choose language → show required packs/size → download/verify → ensure recording/analysis ends → transactionally switch locale and active pack. Retain old language on failure.

For missing optional resources, show a download sheet. Continue reduced functionality when required data is enough; block only features that truly require media. Languages without a backend have `analysis=false`, while reading, recording, and playback remain available.

### CDN deployment and operations

```text
/catalog/v1/stable/catalog.json
/catalog/v1/canary/catalog.json
/packs/ui_strings/en-US/2026.09.2.zip
/packs/content/consonant/en-US/2026.09.0.zip
/packs/media/guided_training/en-US/2026.09.4.zip
```

Pipeline: build → validate schema/placeholders/MIME/clinical metadata → test → sign → immutable upload → canary catalog → inspect metrics → stable catalog last. Roll back to a previous catalog; deny-list damaged/withdrawn pack IDs/versions. Use ETag/If-None-Match, exponential backoff, and cached catalogs during outages.

Compare catalog with `/v1/capabilities/languages` before release. Fail publishing if an `analysis=true` language or model revision is not server-ready.

### Change locations

| Location | Change |
|---|---|
| `lib/services/app_language_service.dart` | BCP-47 preference and catalog-based `LanguageRegistry` |
| `lib/features/settings/view/language_settings_screen.dart` | Dynamic states and download-then-switch |
| `lib/l10n/` | Bootstrap ARB plus runtime schema/bundled JSON |
| `lib/main.dart` | Central resource bootstrap/background refresh instead of individual consonant refresh |
| `lib/features/consonant_training/data/consonant_content_repository.dart` | Move Dio/install to manager; keep typed adapter |
| `pubspec.yaml` | Register bootstrap; directly depend on background downloader if needed |
| `tools/pronunciation_content/` | General builder, manifests, signing, placeholder/content lint |
| `server/` | Capability endpoint and pre-publish readiness validator |
| Settings | Resource center, auto-update, Wi-Fi, storage policies |

### Failures and security

- Catalog network/signature failure: verified cache, otherwise bundle.
- Pack hash/schema failure: delete staging, retain active, allow retry.
- Exit during download: never activate unverified files; resume supported large jobs only.
- Low storage: show space/candidates; never delete required packs without confirmation.
- Suspended locale: do not destroy installed data immediately; explain fallback. Only security revocation forces disabling.
- Concurrent download/switch: per-locale mutex and install transactions.
- Downgrade/replay: minimum catalog version and issuance-time policy as well as signatures.
- Telemetry: URL/version/error only, no recordings, user sentences, or identifiers.

### Tests and acceptance

Unit: signatures/schema/app versions/capability intersection; dependency ordering/cycles; hashes/traversal/zip bombs; staging/rollback/index recovery; fallback/missing keys/placeholder types/plurals; migration of `system|ko-KR|en-US`.

Integration/widget: download-switch/relaunch; offline/corrupt/interrupted/low-space/concurrent requests; progress/retry/deletion restrictions; required/optional gates and reduced mode; non-speech practice with `analysis=false` or unavailable TTS/STT.

Release acceptance:

- First launch in airplane mode supports bundled-language practice.
- Corrupt catalogs/packs preserve screens and active data.
- Forced exit never activates partial packs.
- UI keys/placeholders match base; zero missing keys.
- Remote order/enablement/copy/content-version changes work without app redeploy.
- Unsupported third languages are not presented as supported merely because catalog entries exist.

### Phased adoption

1. General catalog/index/manager and consonant JSON adapter.
2. Runtime UI strings, dynamic registry, download-before-switch.
3. Resource center, optional game/video/audio, background/resume, storage policy.
4. Ed25519 pipeline, immutable CDN, canary/stable, rollback tooling.
5. Third languages after capability checks; automate readiness/deployment gates.

Initially include only `ko-KR` and `en-US` to validate remote enablement/order/copy/pack updates. Runtime UI translation alone does not justify another language's release: explicitly approve TTS, STT, analysis, and clinical-content capabilities separately.

## Launch metrics

Resolution/switch errors; English download/fallback success; per-language STT/TTS availability; alignment success/OOV; first-practice completion, 7-day return, repetitions; abandonment after unavailable analysis; accessibility use/support topics.

Before accuracy scores are available, alignment success must not be used as pronunciation-improvement evidence.

## Tradeoffs

One app shares code/history but requires mandatory locale metadata to prevent mixing. OS defaults ease entry but can change existing users' language, so distinguish new/existing initialization. English MFA is quick to adopt but is not clinical scoring; first release offers alignment/interval feedback. Supporting every English variety at once expands validation; start with `en-US`, then separate locale/model contracts.

## Future extensions

`en-GB`/`en-AU` content/dictionaries; nonnative English mode; English CTC posteriors and clinically calibrated GoP; language-specific therapist portal/reports; preferred TTS voice/rate profiles; multilingual CDN manifests and gradual rollout.

## Open questions

Whether to retain Speech Rehab as the English store brand; retain raw audio/TextGrid or delete immediately; US beta SLP/user recruitment; develop a clinical model internally or integrate an externally validated one.

## References

- [Flutter internationalization](https://docs.flutter.dev/ui/internationalization)
- [Apple Speech locale](https://developer.apple.com/documentation/speech/sfspeechrecognizer)
- [English MFA acoustic models](https://mfa-models.readthedocs.io/en/latest/acoustic/English/index.html)
- [English MFA dictionaries](https://mfa-models.readthedocs.io/en/latest/dictionary/index.html)
