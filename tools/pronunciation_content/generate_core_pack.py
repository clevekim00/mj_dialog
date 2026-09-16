#!/usr/bin/env python3
"""Build the deterministic, offline Korean consonant practice content pack.

The checked-in output is runtime data. Candidate wording was authored with AI
assistance, then this script performs structural validation. It deliberately
does not claim speech-language-pathologist approval.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

ONSET_JAMO = "ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ"
CODA_JAMO = " ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ"
VOWEL_JAMO = "ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ"

TARGETS = [
    ("onset_g", "ㄱ", "k0", "onset", ["가게", "가방", "고기", "공원", "기차", "건강"]),
    ("onset_kk", "ㄲ", "kk", "onset", ["까치", "꽃", "꼬리", "꿈", "깨", "껌"]),
    ("onset_n", "ㄴ", "n", "onset", ["나무", "노래", "누나", "냉면", "나라", "내일"]),
    ("onset_d", "ㄷ", "t0", "onset", ["다리", "도로", "두부", "도시", "대화", "동네"]),
    ("onset_tt", "ㄸ", "tt", "onset", ["딸기", "떡", "땅", "뚜껑", "때", "띠"]),
    ("onset_r", "ㄹ", "r", "onset", ["라디오", "로봇", "리본", "라면", "레몬", "루비"]),
    ("onset_m", "ㅁ", "m", "onset", ["마을", "모자", "무릎", "미소", "메뉴", "마음"]),
    ("onset_b", "ㅂ", "p0", "onset", ["바다", "보리", "부모", "비누", "병원", "버스"]),
    ("onset_pp", "ㅃ", "pp", "onset", ["빨래", "빵", "뿌리", "뼈", "뽑기", "뻐꾸기"]),
    ("onset_s", "ㅅ", "s0", "onset", ["사과", "소리", "수건", "시간", "사람", "서울"]),
    ("onset_ss", "ㅆ", "ss", "onset", ["쌀", "씨앗", "쓰레기", "쑥", "썰매", "싸움"]),
    ("onset_j", "ㅈ", "c0", "onset", ["자전거", "주머니", "전화", "지갑", "저녁", "종이"]),
    ("onset_jj", "ㅉ", "cc", "onset", ["짜장면", "찌개", "쪽지", "짝", "찜", "짬뽕"]),
    ("onset_ch", "ㅊ", "ch", "onset", ["차", "치마", "친구", "책", "창문", "추억"]),
    ("onset_k", "ㅋ", "kh", "onset", ["카메라", "코", "쿠키", "키", "커피", "카드"]),
    ("onset_t", "ㅌ", "th", "onset", ["타월", "토끼", "튀김", "티셔츠", "테이블", "통"]),
    ("onset_p", "ㅍ", "ph", "onset", ["파도", "포도", "피아노", "편지", "풀", "표"]),
    ("onset_h", "ㅎ", "h", "onset", ["하늘", "호수", "휴지", "회사", "행복", "호텔"]),
    ("coda_g", "ㄱ", "kf", "coda", ["약", "국", "책", "목", "부엌", "밖"]),
    ("coda_n", "ㄴ", "nf", "coda", ["산", "문", "눈", "손", "돈", "반"]),
    ("coda_d", "ㄷ", "tf", "coda", ["옷", "꽃", "낮", "밭", "끝", "빛"]),
    ("coda_l", "ㄹ", "lf", "coda", ["물", "달", "길", "말", "발", "서울"]),
    ("coda_m", "ㅁ", "mf", "coda", ["밤", "몸", "마음", "이름", "김", "점"]),
    ("coda_b", "ㅂ", "pf", "coda", ["밥", "입", "집", "숲", "앞", "컵"]),
    ("coda_ng", "ㅇ", "ng", "coda", ["방", "공", "빵", "강", "병", "창"]),
]

# Complete sentences avoid noun-template particle errors such as "꽃를".
# Each base wording has four everyday time-context variants. This remains
# AI-assisted material requiring language and clinical review before release.
SENTENCE_CONTEXTS = ("", "지금 ", "오늘은 ", "오늘도 ")
SENTENCE_SOURCE = Path(__file__).with_name("korean_daily_sentences.json")


def decompose(character: str) -> tuple[int, int, int] | None:
    code = ord(character)
    if not 0xAC00 <= code <= 0xD7A3:
        return None
    offset = code - 0xAC00
    return offset // 588, (offset % 588) // 28, offset % 28


CODA_SURFACE_GROUPS = {
    "ㄱ": {"ㄱ", "ㄲ", "ㅋ"},
    "ㄴ": {"ㄴ"},
    "ㄷ": {"ㄷ", "ㅅ", "ㅆ", "ㅈ", "ㅊ", "ㅌ", "ㅎ"},
    "ㄹ": {"ㄹ"},
    "ㅁ": {"ㅁ"},
    "ㅂ": {"ㅂ", "ㅍ"},
    "ㅇ": {"ㅇ"},
}


def target_count(text: str, grapheme: str, position: str) -> int:
    count = 0
    for character in text:
        parts = decompose(character)
        if parts is None:
            continue
        if position == "onset" and parts[0] == ONSET_JAMO.index(grapheme):
            count += 1
        if position == "coda" and CODA_JAMO[parts[2]] in CODA_SURFACE_GROUPS[grapheme]:
            count += 1
    return count


def combine(grapheme: str, vowel: str, position: str) -> str:
    onset = ONSET_JAMO.index(grapheme) if position == "onset" else ONSET_JAMO.index("ㅇ")
    coda = CODA_JAMO.index(grapheme) if position == "coda" else 0
    return chr(0xAC00 + onset * 588 + VOWEL_JAMO.index(vowel) * 28 + coda)


def build_pack() -> dict:
    targets = []
    items = []
    vowels = "ㅏㅓㅗㅜㅡㅣ"
    daily_sentences = json.loads(SENTENCE_SOURCE.read_text(encoding="utf-8"))
    for target_id, grapheme, phone, position, words in TARGETS:
        targets.append(
            {
                "id": target_id,
                "grapheme": grapheme,
                "phone": phone,
                "position": position,
                "description": f"{position} 위치의 {grapheme} 발음",
                "isControl": False,
            }
        )
        for index, vowel in enumerate(vowels, start=1):
            text = combine(grapheme, vowel, position)
            items.append(
                {
                    "id": f"{target_id}_syllable_{index:02d}",
                    "targetId": target_id,
                    "level": "syllable",
                    "text": text,
                    "pronunciation": [phone],
                    "difficulty": 1,
                    "category": "음절",
                    "targetOccurrenceCount": 1,
                    "referenceAudioAsset": None,
                    "reviewStatus": "structural_validation_only_review_required",
                }
            )
        for index, word in enumerate(words, start=1):
            count = target_count(word, grapheme, position)
            if count == 0:
                raise ValueError(f"{target_id}: target missing from word {word}")
            items.append(
                {
                    "id": f"{target_id}_word_{index:02d}",
                    "targetId": target_id,
                    "level": "word",
                    "text": word,
                    "pronunciation": [phone],
                    "difficulty": 1 if index <= 3 else 2,
                    "category": "생활 단어",
                    "targetOccurrenceCount": count,
                    "referenceAudioAsset": None,
                    "reviewStatus": "structural_validation_only_review_required",
                }
            )
        bases = daily_sentences[target_id]
        if len(bases) != 5 or len(set(bases)) != 5:
            raise ValueError(f"{target_id}: expected five distinct daily sentences")
        sentences = [context + sentence for context in SENTENCE_CONTEXTS for sentence in bases]
        for index, text in enumerate(sentences):
            count = target_count(text, grapheme, position)
            if count < 2:
                raise ValueError(f"{target_id}: sentence has fewer than two targets: {text}")
            items.append(
                {
                    "id": f"{target_id}_sentence_{index + 1:02d}",
                    "targetId": target_id,
                    "level": "sentence",
                    "text": text,
                    "pronunciation": [phone] * count,
                    "difficulty": 1 + index // 7,
                    "category": "성인 생활",
                    "targetOccurrenceCount": count,
                    "referenceAudioAsset": None,
                    "reviewStatus": "structural_validation_only_review_required",
                }
            )
    return {
        "id": "ko-consonant-core",
        "schemaVersion": 1,
        "version": "2026.09.2",
        "language": "ko-KR",
        "generator": {
            "type": "ai_authored_deterministic_build",
            "reviewStatus": "automated_validation_complete_slp_review_required",
            "sentenceSource": "korean_daily_sentences.json",
            "targetCountBasis": "written_hangul_not_contextual_acoustic_phonemes",
        },
        "targets": targets,
        "items": items,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output",
        default="assets/pronunciation/content/ko_consonant_core.json",
    )
    parser.add_argument(
        "--manifest-output",
        default="assets/pronunciation/content/manifest.json",
    )
    parser.add_argument(
        "--download-url",
        default="https://cdn.example.invalid/pronunciation/ko_consonant_core.json",
    )
    args = parser.parse_args()
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    pack = build_pack()
    payload = json.dumps(pack, ensure_ascii=False, indent=2) + "\n"
    output.write_text(payload, encoding="utf-8")
    digest = hashlib.sha256(payload.encode("utf-8")).hexdigest()
    manifest = {
        "schemaVersion": 1,
        "language": pack["language"],
        "version": pack["version"],
        "url": args.download_url,
        "sha256": digest,
    }
    manifest_output = Path(args.manifest_output)
    manifest_output.parent.mkdir(parents=True, exist_ok=True)
    manifest_output.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        f"wrote {output}: {len(pack['targets'])} targets, "
        f"{len(pack['items'])} items, sha256={digest}"
    )


if __name__ == "__main__":
    main()
