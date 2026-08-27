from __future__ import annotations

from dataclasses import dataclass

from .acoustic import AcousticBackend, backend_from_environment
from .mfa_backend import backend_from_environment as korean_mfa_from_environment
from .mfa_backend import english_backend_from_environment

SUPPORTED_LANGUAGES = frozenset({"ko-KR", "en-US"})


@dataclass
class BackendRegistry:
    backends: dict[str, AcousticBackend]

    def resolve(self, language: str) -> AcousticBackend:
        try:
            return self.backends[language]
        except KeyError as error:
            raise UnsupportedLanguage(language) from error

    def readiness(self) -> dict[str, dict]:
        return {
            language: {
                "ready": backend.ready,
                "modelVersion": backend.model_version,
            }
            for language, backend in sorted(self.backends.items())
        }


class UnsupportedLanguage(ValueError):
    pass


def registry_from_environment() -> BackendRegistry:
    # CTC remains a shared optional backend; MFA uses language-specific models.
    shared = backend_from_environment()
    if shared.model_version != "not-configured" and not shared.model_version.startswith("mfa-"):
        return BackendRegistry({language: shared for language in SUPPORTED_LANGUAGES})
    return BackendRegistry(
        {
            "ko-KR": korean_mfa_from_environment(),
            "en-US": english_backend_from_environment(),
        }
    )
