from re import
  re,
  replace

const
  wordsUnnecessary * = [ #TODO: Optimise this list.
    "---{",
    ",",
    ";",
    ":",
    ".",
    "'",
    "",
    "}---",
    "☐",
    "☑",
    "1",
    "2",
    "a",
    "about",
    "acest",
    "after",
    "all",
    "also",
    "always",
    "an",
    "and",
    "are",
    "as",
    "at",
    "au",
    "be",
    "because",
    "been",
    "but",
    "că",
    "can",
    "când",
    "ce",
    "cu",
    "DE",
    "de",
    "do",
    "doesn't",
    "don't",
    "dont",
    "e",
    "este",
    "even",
    "ever",
    "every",
    "for",
    "from",
    "game",
    "get",
    "give",
    "go",
    "going",
    "good",
    "gra",
    "gud",
    "had",
    "has",
    "have",
    "how",
    "i'm",
    "i",
    "if",
    "in",
    "în",
    "into",
    "is",
    "it's",
    "it",
    "its",
    "joc",
    "just",
    "know",
    "la",
    "like",
    "lot",
    "mai",
    "make",
    "many",
    "me",
    "more",
    "most",
    "much",
    "my",
    "need",
    "never",
    "new",
    "nie",
    "no",
    "not",
    "now",
    "nu",
    "o",
    "of",
    "on",
    "on",
    "one",
    "only",
    "or",
    "other",
    "out",
    "pe",
    "pentru",
    "play",
    "players",
    "really",
    "să",
    "sau",
    "și",
    "so",
    "some",
    "still",
    "te",
    "than",
    "that",
    "the",
    "then",
    "their",
    "there",
    "they",
    "this",
    "to",
    "too",
    "u",
    "un",
    "us",
    "us",
    "very",
    "want",
    "was",
    "way",
    "what",
    "when",
    "which",
    "who",
    "will",
    "with",
    "would",
    "yes",
    "you",
    "your",
    "а",
    "в",
    "вас",
    "вы",
    "для",
    "если",
    "и",
    "игра",
    "Игра",
    "играть",
    "из",
    "когда",
    "лучше",
    "на",
    "не",
    "но",
    "по",
    "с",
    "что",
    "это",
    "этой",
    "эту",
    "я"
  ]

func stripSigns*(word: string): string =
  ## Remove all non alpha letters.
  word.replace(
    re"""[^\x{0000}-\x{00BF}]+"""
  )