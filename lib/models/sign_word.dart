class SignWord {
  final String word;
  final String category;
  final String gifPath;

  const SignWord({
    required this.word,
    required this.category,
    required this.gifPath,
  });

  factory SignWord.auto(String word, String category) => SignWord(
        word: word,
        category: category,
        gifPath: 'assets/gifs/${word.toLowerCase().replaceAll(' ', '')}.gif',
      );
}
