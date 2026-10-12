# mj-dialog architecture plan without an owned backend

[한국어](server-free-architecture-plan.md) | [English](server-free-architecture-plan.en.md)

Written: 2026-10-11 · Status: implementation plan · Code baseline: 2026-10-10

Keep the current Flutter app and provide core learning and records offline. Offer AI through optional on-device models, verify signed content before activation, and transfer data directly between devices through encrypted QR pairing. The React MVP and GPT-4o proposal are historical context; the implementation baseline is the current SpeechBridge repository.

The completion criteria below are future verification requirements. Existing code does not imply that every feature has passed mobile release testing.

## Goals and scope

- Make core lessons, words, sentences, and learning records available without a network or AI.
- Unlock the app with biometrics or the device credential and protect local data with platform-protected keys.
- Encrypt records, recordings, and videos locally.
- Let users choose model and content installations; retain file import.
- Exclude automatic cloud sync, a central account server, GPT-4o-level cloud responses, and blockchain.
- Treat IPFS/libp2p as optional distribution paths, never prerequisites for core use.

Operating no owned backend differs from using no external infrastructure. Optional downloads require static hosting or distribution peers, with separate availability and traffic considerations. OS backups can occur without app-level synchronization, so implement explicit backup exclusions as well.

## Current repository and reusable implementation

| Area | Current implementation | Required change |
|---|---|---|
| App | Flutter, Dart SDK `^3.10.4`, Riverpod | Retain screens and state management |
| Features | Chat, sentence/consonant practice, games, records, settings | Define lesson progress and personal vocabulary models explicitly |
| AI | `flutter_gemma`, Gemma 2B installation from assets | Separate optional installation and device capability checks |
| iOS AI | Disabled in code because of startup crashes | Validate native registration and inference on devices before enabling |
| Model asset | Approximately 1.3GB file registered as an app asset | Remove from the base distribution and install verified external files |
| Records | SharedPreferences, ordinary SQLite, separate media | Introduce shared storage interfaces, encryption, and migration |
| Speech | OS STT/TTS, native channels, recording/playback | Check offline support and provide fallback flows |
| Updates | Ed25519, SHA-256, version comparison, previous-pack recovery | Add file input, model packs, key rotation, and stronger interrupted-install recovery |
| Servers | FastAPI analysis service and Kotlin/Spring inference example | Exclude calls, polling, and retries from the backend-free distribution |

The current product supports speech rehabilitation practice. General language lessons and vocabulary lists are not automatically equivalent to existing training. Preserve existing practice flows while adding the necessary learning models. Continue distinguishing text matching, local signal measurements, and generated conversation from pronunciation accuracy or treatment-effect assessment.

## Proposed modules

Paths below are proposed additions or reorganizations. Screens call feature repositories, which use storage, AI, content services, and native adapters. Screens must not retrieve keys directly or activate downloaded files themselves.

| Module | Location | Responsibility |
|---|---|---|
| Runtime policy | `lib/services/runtime/` | Backend-free build policy, network permissions, feature availability |
| App lock and keys | `lib/services/security/` | Unlocking, device keys, data-key protection, background locking |
| Encrypted storage | `lib/services/storage/` | Database/media encryption, migration, recovery |
| Learning data | Existing feature repositories | Lessons, vocabulary, progress, records |
| Local AI | `lib/services/ai/` | Conversation engine, model lifecycle, capability checks |
| Speech | Existing `lib/services/audio/` | Local STT/TTS checks, recording/playback, alternative input |
| Content | Existing `lib/services/resources/` | Signature, compatibility and hash checks; installation, activation and recovery |
| Device transfer | `lib/services/transfer/` | QR pairing, transfer sessions, import validation |
| Release tooling | `tools/content_release/` | Pack creation and manifest generation, signing and validation |

## App locking and encrypted storage

Separate app unlocking, device identity keys, and data-encryption keys. Biometrics or device credentials authorize local access. Device keys prove possession to a paired peer; they do not establish a central account or verified human identity. Use separate random data keys for the database and media.

On iOS, combine Secure Enclave P-256 keys with access-controlled Keychain storage. Do not treat Secure Enclave as arbitrary storage for a database password. On Android, use Keystore protection and inspect hardware security capabilities. Bind access control to actual key use rather than merely showing a successful biometric prompt.

Evaluate SQLCipher first, but select the library only after validating native integration with the current `sqlite3` setup. Ordinary SQLite `secure_delete` is not encryption. Use separate authenticated encryption for recordings and videos, accounting for temporary plaintext, WAL files, caches, shared files, and OS backups.

Migrate existing records in this order:

1. Inventory SharedPreferences, SQLite, media, and schema versions.
2. Create encrypted storage and copy records while preserving UUIDs and relationships.
3. Verify record counts, media hashes, and referential integrity.
4. Record completion and switch to the new storage.
5. Clean up old plaintext only after a verified switch; make interruptions resumable.

Do not claim guaranteed physical erasure of historical plaintext on flash storage. Define recovery behavior for lock changes, key invalidation, and device loss. Explain that a lost device cannot be recovered without a separate export.

## On-device AI and speech

Split `AiService` into `ConversationEngine`, `ModelManager`, and `DeviceCapabilityService`. Keep existing text comparison independent of the LLM. Distinguish model states: absent, downloading, verifying, ready, unsupported, and failed. Installation failure must not block core practice.

Select models using Korean/English quality, peak memory, latency, heat, file format, runtime compatibility, and redistribution license. Finalize models and package versions after device testing. Do not advertise iOS AI support before resolving the current disabled path.

LLM, STT, and TTS are independent capabilities. Current speech recognition does not enforce on-device-only execution, so update both Flutter and native iOS paths. When local recognition is unavailable, provide typing, recording, and manual completion rather than automatically using remote recognition. Check local TTS voice availability; essential examples may use bundled audio with appropriate distribution rights.

## Signed model and content updates

Extend `ResourceCatalogRepository`, `ResourceSignatureVerifier`, and `ResourcePackManager`. Route file input, HTTPS, and optional IPFS through the same validation pipeline. Bundle trusted public keys with the app; keep release-signing private keys out of the app and repository.

Proposed fields are `schemaVersion`, `packId`, `version`, `minAppVersion`, `sizeBytes`, `sha256`, optional `cid`, `mirrors`, `keyId`, and `signature`. Model metadata also identifies runtime, format, languages, and license. Define identical canonical signing bytes in the release tools and app.

Installation order:

1. Verify the manifest signature against a trusted public key.
2. Check schema, app compatibility, version, and size limits.
3. Download or import into a temporary file.
4. Verify size, SHA-256, content format, and path safety.
5. Activate the verified version and retain the previous working version.

Stream large model downloads and hashing instead of loading all bytes into memory. Recover files and metadata consistently after process termination. Define key rotation, authorized recovery, and incoming downgrade prevention separately so legitimate recovery is not confused with malicious replay.

A CID addresses content; it does not authenticate the publisher. Depending on IPFS file construction, the CID can differ from the original file SHA-256, so retain separate fields. A fully offline device cannot immediately discover a newer release or key revocation. Failed update checks or expiry must not block core lessons.

## QR device transfer

Limit the first implementation to two foreground apps on the same Wi-Fi network or hotspot. A QR code does not provide internet NAT traversal. Offer encrypted file export/import when a direct connection is unavailable.

Put a one-time session ID, connection information, and public-key fingerprint/pairing information in the QR code, never records or private keys. Use a reviewed key-exchange protocol, confirmation codes on both devices, session expiry, replay prevention, and encrypted transport. Do not invent a cryptographic protocol.

Transfer a versioned logical record format and media inventory rather than copying the database file. The receiving device creates new keys and re-encrypts data; hardware private keys never migrate. Validate hashes, schemas, and references in staging, deduplicate by UUID, and commit transactionally. Prefer transfer into an empty profile initially; use an explicit conflict policy rather than silently overwriting existing data.

Keep the source until receiver validation and user confirmation. Prevent partial imports after cancellation or disconnection. Treat the recovery secret for an archival encrypted export independently of device keys. Device transfer is not automatic synchronization.

## Implementation phases

| Phase | Scope | Completion criteria |
|---|---|---|
| 1 Offline MVP | Core learning, no server calls, app lock, encrypted storage and migration | Practice, save, playback and deletion on first launch and relaunch in airplane mode; interrupted migration recovery |
| 2 On-device AI | Remove bundled model; optional installation/deletion; fix iOS execution; device checks | Core features work without a model; installed model works offline; safe fallback for unsupported devices or memory pressure |
| 3 Signed content updates | File input, common manifests, key rotation, recovery policy | Reject modified, unsigned and incompatible packs; retain working content after interrupted installation |
| 4 QR transfer | Same-LAN pairing, encrypted transport, validated import | iOS↔Android transfer; interruption, cancellation and duplicate handling; preserve source until confirmation |
| 5 Optional P2P | IPFS adapter and libp2p experiments if needed | Bundled content and file imports work when peers and gateways fail |

**Dependency:** Model downloads in phase 2 already require signature verification. Bring the minimum verifier, trusted public keys, and safe installation procedure forward from phase 3, then expand them to all content in phase 3. Phase 1 relies on content included in the signed app distribution.

## First work items and validation

- [ ] Add the backend-free runtime policy; handle analysis buttons, calls, polling, retries, and deletion paths involving old remote jobs.
- [ ] Define storage adapters and key lifecycle; implement SQLite, SharedPreferences, and media migration.
- [ ] Separate model assets from optional installation and connect minimum signature verification.
- [ ] Check offline speech capabilities in Flutter and native paths.
- [ ] Extend resource tests for tampering, version replay, key rotation, interrupted installation, and size limits.
- [ ] Test migration, key invalidation, storage exhaustion, calls, and background transitions on physical devices.
- [ ] Verify QR transfer against spoofing, replay, disconnection, duplicate imports, and receiver failure.

Beyond unit tests, inspect first launch, network requests, memory, heat, and installed size in iOS and Android release builds. Publish only public content through P2P, never personal records. Estimate delivery dates and finalize packages after encrypted-storage and iOS-inference feasibility checks.

## Repository evidence and references

- [Dependencies and assets](../pubspec.yaml), [app entry point](../lib/main.dart)
- [AI service](../lib/services/api/ai_service.dart), [speech recognition](../lib/services/audio/stt_service.dart), [native iOS implementation](../ios/Runner/AppDelegate.swift)
- [Sentence SQLite repository](../lib/features/sentence_practice/sentence_repository.dart), [chat history](../lib/services/history_service.dart), [practice history](../lib/services/practice_history_service.dart)
- [Signature verification](../lib/services/resources/resource_signature_verifier.dart), [catalog](../lib/services/resources/resource_catalog_repository.dart), [pack manager](../lib/services/resources/resource_pack_manager.dart)
- [Sentence analysis client](../lib/features/sentence_practice/sentence_analysis_client.dart), [consonant analysis client](../lib/features/consonant_training/services/pronunciation_analysis_client.dart)
- [Apple Secure Enclave](https://developer.apple.com/documentation/security/protecting-keys-with-the-secure-enclave), [Android Keystore](https://developer.android.com/privacy-and-security/keystore)
- [SQLCipher design](https://www.zetetic.net/sqlcipher/design/), [Apple on-device speech recognition](https://developer.apple.com/documentation/speech/sfspeechrecognizer/supportsondevicerecognition), [IPFS CIDs](https://docs.ipfs.tech/concepts/content-addressing/)
