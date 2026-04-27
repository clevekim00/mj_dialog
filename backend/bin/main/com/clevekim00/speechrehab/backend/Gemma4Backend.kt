package com.clevekim00.speechrehab.backend

import org.springframework.web.bind.annotation.*
import org.springframework.web.multipart.MultipartFile
import org.springframework.http.ResponseEntity
import org.springframework.stereotype.Service

@RestController
@RequestMapping("/api/ai")
class PronunciationController(private val gemmaService: Gemma4InferenceService) {

    @PostMapping("/evaluate")
    suspend fun evaluate(
        @RequestParam("audio") audioFile: MultipartFile,
        @RequestParam("targetText") targetText: String
    ): ResponseEntity<GemmaResponse> {
        val audioBytes = audioFile.bytes
        val result = gemmaService.infer(audioBytes, targetText)
        return ResponseEntity.ok(result)
    }
}

@Service
class Gemma4InferenceService {

    /**
     * Interface for Gemma 4 4B-it model inference using native audio tokens.
     */
    suspend fun infer(audioBytes: ByteArray, targetText: String): GemmaResponse {
        // 1. Convert raw audio to native audio tokens (Multimodal Tokenization)
        val audioTokens = tokenizeAudio(audioBytes)

        // 2. Build prompt for Gemma 4 4B-it
        val prompt = """
            <start_of_turn>user
            Native Audio: [AUDIO_TOKENS]
            Target Text: "$targetText"
            Task: Provide phoneme-level accuracy and intonation feedback in JSON.
            <end_of_turn>
            <start_of_turn>model
        """.trimIndent()

        // 3. Execute inference (Placeholder for Actual Gemma 4 Engine)
        // In reality, this would call a JNI wrapper for the Gemma C++ engine or a GPU-accelerated service.
        return GemmaResponse(
            replyText = "좋은 시도입니다! 전체적인 억양이 자연스러워요.",
            pronunciationScore = 85,
            pronunciationFeedback = "'연습' 발음 시 강세를 조금 더 주면 좋겠습니다.",
            phonemeAccuracy = listOf(
                PhonemeAccuracy("연", 90, null),
                PhonemeAccuracy("습", 75, "Weak final consonant")
            ),
            intonationFeedback = "문장 중간의 상승조가 적절하게 유지되었습니다."
        )
    }

    private fun tokenizeAudio(audioBytes: ByteArray): String {
        // Multimodal tokenization logic would go here
        return "tok_audio_0123456789"
    }
}

data class GemmaResponse(
    val replyText: String,
    val pronunciationScore: Int,
    val pronunciationFeedback: String,
    val phonemeAccuracy: List<PhonemeAccuracy>,
    val intonationFeedback: String
)

data class PhonemeAccuracy(
    val phoneme: String,
    val score: Int,
    val issue: String?
)
