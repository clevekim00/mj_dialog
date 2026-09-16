import hashlib
import json
from pathlib import Path
import unittest

from generate_core_pack import build_pack, target_count

ROOT = Path(__file__).resolve().parents[2]


class ContentPackTests(unittest.TestCase):
    def test_checked_in_pack_is_reproducible_and_manifest_matches(self):
        pack = build_pack()
        stored = ROOT / 'assets/pronunciation/content/ko_consonant_core.json'
        self.assertEqual(json.loads(stored.read_text()), pack)
        manifest = json.loads((stored.parent / 'manifest.json').read_text())
        self.assertEqual(manifest['version'], pack['version'])
        self.assertEqual(manifest['sha256'], hashlib.sha256(stored.read_bytes()).hexdigest())

    def test_every_sentence_has_written_targets_and_requires_review(self):
        pack = build_pack()
        self.assertEqual(len(pack['items']), 800)
        self.assertEqual(len({item['id'] for item in pack['items']}), 800)
        targets = {target['id']: target for target in pack['targets']}
        sentences = [item for item in pack['items'] if item['level'] == 'sentence']
        self.assertEqual(len(sentences), 500)
        for item in pack['items']:
            target = targets[item['targetId']]
            count = target_count(item['text'], target['grapheme'], target['position'])
            self.assertEqual(item['targetOccurrenceCount'], count)
            self.assertEqual(item['reviewStatus'], 'structural_validation_only_review_required')
            if item['level'] == 'sentence':
                self.assertGreaterEqual(count, 2)
                self.assertNotIn('연습 단어', item['text'])
                self.assertNotIn('라고 말', item['text'])
                self.assertNotIn('쭈꾸미', item['text'])
        for target in targets:
            texts = [item['text'] for item in sentences if item['targetId'] == target]
            self.assertEqual(len(set(texts)), 20)


if __name__ == '__main__':
    unittest.main()
