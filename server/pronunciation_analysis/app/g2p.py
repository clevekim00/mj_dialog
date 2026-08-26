"""Small deterministic Hangul target extractor used before acoustic alignment."""

ONSETS = tuple("ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ")
CODAS = ("", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ")
CODA_SURFACE = {
    **{phone: "k_f" for phone in ("ㄱ", "ㄲ", "ㄳ", "ㄺ", "ㅋ")},
    **{phone: "n_f" for phone in ("ㄴ", "ㄵ", "ㄶ")},
    **{phone: "t_f" for phone in ("ㄷ", "ㅅ", "ㅆ", "ㅈ", "ㅊ", "ㅌ", "ㅎ")},
    **{phone: "l_f" for phone in ("ㄹ", "ㄼ", "ㄽ", "ㄾ", "ㅀ")},
    **{phone: "m_f" for phone in ("ㅁ", "ㄻ")},
    **{phone: "p_f" for phone in ("ㅂ", "ㅄ", "ㄿ", "ㅍ")},
    "ㅇ": "ng_f",
}


def decompose_hangul(text: str) -> list[dict[str, str]]:
    result: list[dict[str, str]] = []
    for character in text:
        code = ord(character)
        if not 0xAC00 <= code <= 0xD7A3:
            continue
        offset = code - 0xAC00
        onset_index, remainder = divmod(offset, 588)
        _, coda_index = divmod(remainder, 28)
        result.append(
            {
                "character": character,
                "onset": ONSETS[onset_index],
                "coda": CODA_SURFACE.get(CODAS[coda_index], ""),
            }
        )
    return result


def target_occurrences(text: str, target_phone: str, position: str) -> int:
    key = "onset" if position == "onset" else "coda"
    normalized = target_phone.replace("f", "_f") if target_phone.endswith("f") and "_" not in target_phone else target_phone
    return sum(1 for syllable in decompose_hangul(text) if syllable[key] in {target_phone, normalized})
