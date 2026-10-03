# 훈련 열기·닫기와 관리 서버 설계

[한국어](training-availability-and-server.md) | [English](training-availability-and-server.en.md) | [전체 문서](README.md)

<!-- reader-link --> [언어 탭으로 읽기](https://clevekim00.github.io/mj_dialog/documents/docs/training-availability-and-server.html)

작성: 2026-10-01. 이 문서는 과거 문서의 ‘전문가 확인 훈련은 잠금’ 설명을 대체한다.

## 이번에 구현한 동작

- **훈련 → 구강 훈련**의 46개 운동(혀 14, 입술 12, 교호 10, 호흡 10)을 모두 기본 열림으로 변경했다. 전문가 확인 등급도 목록 진입·시작·내 루틴 선택이 가능하다.
- `safetyTier`는 주의 문구와 표시 색상만 결정한다. 훈련 가능 여부는 `TrainingAvailability.isEnabled(exerciseId)`가 별도로 판단한다. 전문가와 상의하라는 안내는 유지한다.
- 내장 카탈로그는 `defaultEnabled: true`, `overrides: {}`다. 이전 카탈로그처럼 해당 필드가 없어도 모두 열린다. 개별 ID의 `false`만 닫고, `true` 또는 항목 삭제로 다시 연다.
- 서버 정책이 닫은 운동은 목록에 잠금 표시를 하며 직접 플레이어로 진입해도 시작할 수 없다. 정책을 읽는 동안에는 실행을 기다리고, 읽기 실패 시 재시도를 제공한다.
- 루틴의 닫힌 항목은 `skipped: true`로 기록하고 건너뛴다. 모든 항목이 닫히면 새 루틴 시작을 막는다. 저장한 루틴 구성은 보존하고, 닫힌 항목을 새로 추가하는 것은 막는다. 저장된 이어하기도 현재 정책을 확인한다.
- 시작·저장된 이어하기 시점의 정책을 세션 동안 고정한다. 진행 중 서버 설정이 바뀌어도 갑자기 재생을 중단하지 않는다. 다음 세션에 새 정책을 적용한다.
- 기본 추천 루틴은 그대로다. 모든 운동을 열었다고 전문가 확인 항목을 자동 추천하지는 않는다.

적용 범위는 구강·호흡 카탈로그의 **46개 개별 운동**이다. 자음·문장·MPT·게임은 기존처럼 열려 있다. 이들의 개별 콘텐츠 ID까지 원격으로 통제하려면 같은 정책 조회를 각 실행 경계에 연결하는 추가 작업이 필요하다.

## 앱과 서버 연결

```mermaid
flowchart LR
  A[관리자 화면 · 후속 개발] --> B[관리 API · 후속 개발]
  B --> C[정책 DB · 변경 감사 기록]
  C --> D[서명된 전체 리소스 카탈로그 발행]
  D --> E[앱: 서명·버전 검사와 로컬 캐시]
  E --> F[목록 / 내 루틴 / 플레이어]
```

앱 연결은 구현되어 있다. 기존 `RESOURCE_CATALOG_URL`에 HTTPS 카탈로그 주소, `RESOURCE_CATALOG_PUBLIC_KEY`에 Ed25519 공개키를 빌드 설정으로 전달한다. 개인키와 관리자 토큰은 앱에 넣지 않는다. 시작 시 백그라운드 확인 후 구독 화면을 갱신하며, 기본 확인 간격은 6시간이다. 설정의 리소스 관리에서 강제 확인할 수도 있다. 실시간 push나 주기적 백그라운드 polling은 없다.

원격 응답은 기존 전체 리소스 카탈로그에 아래 필드를 추가한다. 아래 조각만을 응답으로 보내면 안 된다. `languages`, `packs`, `catalogVersion`, `schemaVersion`, `signature`도 필요하다.

```json
{
  "trainingAvailability": {
    "schemaVersion": 1,
    "defaultEnabled": true,
    "overrides": {
      "breathing_03_rapid_deep": false,
      "tongue_08_resistance": true
    }
  }
}
```

각 변경 발행은 `catalogVersion`을 증가시키고 전체 문서를 다시 서명해야 한다. 키를 재귀적으로 정렬한 compact UTF-8 JSON에서 `signature`만 제외해 서명하고, 64바이트 서명을 base64로 넣는다. 기존 `canonicalResourceJson`/`Ed25519ResourceSignatureVerifier`와 같은 규칙이다. 정수 등 제한된 JSON 값만 사용하고 양쪽 서명 호환 테스트를 둔다.

오프라인·잘못된 응답·유효하지 않은 서명은 마지막 검증된 캐시를 유지한다. active 손상이 있으면 previous, 둘 다 사용할 수 없으면 내장 전체 열림 정책으로 복구한다. 캐시 삭제·재설치 후에는 서버 연결 전 전체 열림이다. 따라서 이 기능은 운영 편의용 설정이며, 결제 권한이나 즉각적인 보안 차단을 보장하는 기능이 아니다. 누락된 새 ID도 기본 열림이므로 서버 발행 전 ID 검증이 필요하다.

## 관리 API 계약 — 설계 완료, 서버 미구현

기계 판독 계약: [OpenAPI JSON](../server/training_management/openapi.json). 경로는 미래 서비스의 계약이며 현재 발음 분석 서버에는 등록되어 있지 않다.

| 메서드·경로 | 역할 | 인증 |
|---|---|---|
| `GET /v1/admin/trainings` | 46개 ID, 종류, 표시명, 현재 개별 상태 목록 | 관리자 읽기 |
| `GET /v1/admin/training-policy` | 전체 정책과 revision/ETag 조회 | 관리자 읽기 |
| `PUT /v1/admin/trainings/{trainingId}/availability` | 한 운동의 enabled 변경, reason 필수 | 관리자 쓰기 |
| `POST /v1/admin/training-policy/publish` | 지정 revision을 서명 카탈로그로 발행 | 발행 권한 |
| `GET /v1/admin/training-policy/audit` | 누가 언제 무엇을 왜 변경·발행했는지 조회 | 감사 읽기 |
| `GET /v1/resources/catalog` | 앱이 전체 서명 카탈로그 수신, ETag/304 지원 | 공개 읽기 |

개별 변경 예:

```http
PUT /v1/admin/trainings/breathing_03_rapid_deep/availability
Authorization: Bearer <관리자 액세스 토큰>
If-Match: "policy-12"
Content-Type: application/json

{"enabled": false, "reason": "안내 영상 교체"}
```

성공 시 `200`, 새 revision과 `ETag: "policy-13"`을 반환한다. `true`로 같은 요청을 보내면 다시 열린다. 변경은 초안에만 반영되고 발행 전 앱에는 적용되지 않는다. 발행 요청은 `{"revision":13}`과 고유 `Idempotency-Key`를 사용한다. UI는 **저장됨 / 발행됨 / 앱 반영까지 지연 가능**을 구분한다.

오류: 미인증 `401`, 권한 부족 `403`, 알 수 없는 ID `404`, stale If-Match `412`, If-Match 누락 `428`, 잘못된 값 `422`, 발행 충돌·동일 idempotency key의 다른 본문 `409`, 제한 초과 `429`. HTTP 성공만으로 모든 오프라인 앱이 즉시 바뀌었다고 표시하지 않는다.

## 서버 데이터와 구현 순서

- `training_registry`: id(PK), category, title_ko, title_en, app_content_version. 앱 카탈로그 ID와 일치하며 임의 ID 생성 불가.
- `policy_revision`: revision(PK), full_overrides JSON, created_at, actor_id. 수정 대신 새 revision 생성.
- `policy_audit`: actor_id, action, training_id, before/after, reason, revision, request_id, timestamp. 음성·환자 정보를 저장하지 않는다.
- `policy_publication`: revision, catalog_version(unique), signed_document, etag, published_at, actor_id, idempotency_key, request_hash.
- 관리자 인증은 OIDC/조직 로그인과 역할(read/write/publish/audit) 검증으로 구현한다. 분석 서버의 사용자 토큰을 관리자 권한으로 재사용하지 않는다.
- DB 트랜잭션에서 revision과 감사 기록을 함께 저장한다. 발행은 기존 언어/팩 정보를 유지한 전체 카탈로그 생성 → 서명 → 불변 오브젝트 업로드 → 공개 포인터 원자적 변경 순서로 처리한다. 실패하면 기존 공개 버전을 유지한다.
- 되돌리기는 과거 상태를 **새 revision 및 더 높은 catalogVersion**으로 다시 발행한다. 앱은 낮은 버전을 채택하지 않는다.
- 1단계: DB·인증·목록/개별 변경·동시 수정 테스트. 2단계: 서명·발행·ETag·감사·실패 복구 테스트. 3단계: 관리자 웹 화면·HTTPS 배포·키 관리·모니터링·앱 연결 검증.

## 서버 기능과 현재 구현 수준

‘구현’은 저장소 코드 기준이며 운영 서버가 배포되었다는 뜻이 아니다.

| 기능 | 현재 수준 | 남은 작업 |
|---|---|---|
| 분석 `GET /health`, `/ready` | FastAPI 구현 | 운영 배포 및 실제 모델 준비 확인 |
| 분석 작업 생성·조회·삭제 | 구현, 테스트 존재 | 운영 사용자 로그인·토큰 공급 연결 |
| 한국어/영어 MFA 정렬 | backend/설치 스크립트 구현 | 모델 설치, 실행 환경과 실제 음성 검증 |
| 발음 정확도 점수·GoP | 의도적으로 미제공 (`null`) | 검증된 채점 모델 필요 |
| 분석 토큰 검증·소유자 제한·TTL·업로드 제한 | 구현 | 외부 로그인/토큰 발급 서버와 연결 |
| 다중 분석 worker·영구 작업 DB | 미구현, 현재 메모리/단일 worker | 공통 DB·큐·분산 제한 |
| 리소스 카탈로그/팩 다운로드 | 앱 클라이언트 구현 | 공개 호스팅·관리 API·서명 발행 파이프라인 |
| 46개 훈련별 정책 판정 | 이번 앱 구현 | 실제 관리 서버 연결 |
| 관리자 인증·훈련 CRUD 정책·감사·발행 | API/데이터 설계만 완료 | 서버 및 관리자 UI 개발 |
| 기록·루틴·MPT 클라우드 동기화 | 서버 미구현, 앱 로컬 저장 | 계정·동의·저장·동기화 별도 설계 |
| AI 대화 | 앱의 로컬 Gemma 계층 존재 | 자체 클라우드 AI 서버로 구현된 것은 아님 |

주요 근거: `server/pronunciation_analysis/app/main.py`, `app/security.py`, `lib/services/resources/`, `lib/services/training/training_availability*.dart`, `lib/features/guided_training/view/`.

## 검증

기본 46개 열림, 이전 카탈로그 호환, 개별 닫기/열기, 잘못된 정책 거절, 오프라인 캐시 유지, 직접 진입 차단, 루틴 건너뛰기, 기존 플레이어 진행·저장 회귀 테스트를 포함한다. 원격 관리 서버의 운영 E2E는 서버 구현·배포 후 수행해야 한다.

## 문장 분석 서버 추가 (2026-10-02)

자유 문장용 `/v1/sentence-analysis` 기능이 추가되었다. 언어·준비 상태 조회, 업로드·영속 큐·조회·취소/삭제, 한국어/영어 로컬 ASR, 관찰값/고정 안내, 소유자 인증·멱등성·15분 만료를 구현했다. 관리 서버의 개별 훈련 열기/닫기 API와는 별도이며 관리 UI나 운영 로그인 발급 서비스는 추가 구현이 필요하다. [실행 방법과 정확한 구현 한계](../server/pronunciation_analysis/README.md#자유-문장-분석-서버-2026-10-02).
