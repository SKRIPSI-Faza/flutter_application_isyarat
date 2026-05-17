import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

class SignWord {
  final String word;
  final String category;
  final String gifPath;

  const SignWord({
    required this.word,
    required this.category,
    required this.gifPath,
  });
}

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<SignWord> _allWords = const [
    SignWord(word: 'Air', category: 'Kebutuhan', gifPath: 'assets/gifs/air.gif'),
    SignWord(word: 'Berangkat', category: 'Aksi', gifPath: 'assets/gifs/berangkat.gif'),
    SignWord(word: 'Datang', category: 'Aksi', gifPath: 'assets/gifs/datang.gif'),
    SignWord(word: 'Di Mana', category: 'Tanya', gifPath: 'assets/gifs/dimana.gif'),
    SignWord(word: 'Keluarga', category: 'Orang', gifPath: 'assets/gifs/keluarga.gif'),
    SignWord(word: 'Maaf', category: 'Sapaan', gifPath: 'assets/gifs/maaf.gif'),
    SignWord(word: 'Makan', category: 'Kebutuhan', gifPath: 'assets/gifs/makan.gif'),
    SignWord(word: 'Rumah', category: 'Tempat', gifPath: 'assets/gifs/rumah.gif'),
    SignWord(word: 'Teman', category: 'Orang', gifPath: 'assets/gifs/teman.gif'),
    SignWord(word: 'Terima Kasih', category: 'Sapaan', gifPath: 'assets/gifs/terimakasih.gif'),
    SignWord(word: 'Minum', category: 'Kebutuhan', gifPath: 'assets/gifs/minum.gif'),
    SignWord(word: 'Ayah', category: 'Orang', gifPath: 'assets/gifs/ayah.gif'),
    SignWord(word: 'Ibu', category: 'Orang', gifPath: 'assets/gifs/ibu.gif'),
    SignWord(word: 'Kakak', category: 'Orang', gifPath: 'assets/gifs/kakak.gif'),
    SignWord(word: 'Adik', category: 'Orang', gifPath: 'assets/gifs/adik.gif'),
    SignWord(word: 'Siapa', category: 'Tanya', gifPath: 'assets/gifs/siapa.gif'),
    SignWord(word: 'Apa', category: 'Tanya', gifPath: 'assets/gifs/apa.gif'),
    SignWord(word: 'Kapan', category: 'Tanya', gifPath: 'assets/gifs/kapan.gif'),
    SignWord(word: 'Bagaimana', category: 'Tanya', gifPath: 'assets/gifs/bagaimana.gif'),
    SignWord(word: 'Kenapa', category: 'Tanya', gifPath: 'assets/gifs/kenapa.gif'),
    SignWord(word: 'Tolong', category: 'Sapaan', gifPath: 'assets/gifs/tolong.gif'),
    SignWord(word: 'Sama-sama', category: 'Sapaan', gifPath: 'assets/gifs/samasama.gif'),
    SignWord(word: 'Halo', category: 'Sapaan', gifPath: 'assets/gifs/halo.gif'),
    SignWord(word: 'Selamat Pagi', category: 'Sapaan', gifPath: 'assets/gifs/selamatpagi.gif'),
    SignWord(word: 'Selamat Malam', category: 'Sapaan', gifPath: 'assets/gifs/selamatmalam.gif'),
    SignWord(word: 'Jalan', category: 'Aksi', gifPath: 'assets/gifs/jalan.gif'),
    SignWord(word: 'Lari', category: 'Aksi', gifPath: 'assets/gifs/lari.gif'),
    SignWord(word: 'Tidur', category: 'Kebutuhan', gifPath: 'assets/gifs/tidur.gif'),
    SignWord(word: 'Belajar', category: 'Aksi', gifPath: 'assets/gifs/belajar.gif'),
    SignWord(word: 'Sekolah', category: 'Tempat', gifPath: 'assets/gifs/sekolah.gif'),
    SignWord(word: 'Pasar', category: 'Tempat', gifPath: 'assets/gifs/pasar.gif'),
    SignWord(word: 'Kantor', category: 'Tempat', gifPath: 'assets/gifs/kantor.gif'),
    SignWord(word: 'Saya', category: 'Orang', gifPath: 'assets/gifs/saya.gif'),
    SignWord(word: 'Kamu', category: 'Orang', gifPath: 'assets/gifs/kamu.gif'),
    SignWord(word: 'Dia', category: 'Orang', gifPath: 'assets/gifs/dia.gif'),
    SignWord(word: 'Mereka', category: 'Orang', gifPath: 'assets/gifs/mereka.gif'),
  ];

  List<SignWord> get _filteredWords {
    if (_searchQuery.isEmpty) return _allWords;
    return _allWords
        .where((word) =>
            word.word.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            word.category.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    const Color primaryBlue = Color(0xFF4FC3F7);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Kamus Isyarat'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: 8,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari kata atau kategori...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Info jumlah hasil
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: 4,
            ),
            child: Row(
              children: [
                Text(
                  '${_filteredWords.length} kata ditemukan',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Grid
          Expanded(
            child: _filteredWords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 56,
                          color: isDark ? Colors.white24 : Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Kata tidak ditemukan',
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white38 : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Coba kata lain',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white24 : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: 8,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: screenWidth * 0.03,
                      mainAxisSpacing: screenWidth * 0.03,
                    ),
                    itemCount: _filteredWords.length,
                    itemBuilder: (context, index) {
                      final word = _filteredWords[index];
                      return GestureDetector(
                        onTap: () {
                          _showGifDialog(context, word);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: primaryBlue.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: primaryBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_circle_fill,
                                  color: primaryBlue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                word.word,
                                style: TextStyle(
                                  fontSize: (screenWidth * 0.038).clamp(14.0, 17.0),
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryBlue.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  word.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white38 : primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showGifDialog(BuildContext context, SignWord word) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  word.word,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    word.gifPath,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        width: 200,
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 50,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'GIF belum tersedia',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FC3F7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Tutup', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
