import unittest

from wordfreq import most_frequent_word


class MostFrequentWordTests(unittest.TestCase):
    def test_sample(self):
        self.assertEqual(most_frequent_word("Twinkle, twinkle! TWINKLE."), (3, "twinkle"))

    def test_first_word_wins_a_tie(self):
        self.assertEqual(most_frequent_word("Beta alpha"), (1, "beta"))

    def test_empty_text(self):
        self.assertIsNone(most_frequent_word("... !?"))


if __name__ == "__main__":
    unittest.main()
