import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_colors.dart';
import 'models/sign_word.dart';
import 'providers/theme_provider.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  // Kategori sesuai 24 gesture yang didukung model (API)
  final List<String> _categories = const [
    'Semua',
    'Kebutuhan',
    'Aksi',
    'Sapaan',
    'Orang',
    'Tanya',
    'Tempat',
    'Warna',
    'Lainnya',
  ];

  // 24 kata = persis kelas gesture yang dikenali model klasifikasi.
  // gifPath di-derive otomatis: 'assets/gifs/${kata.lowercase}.gif'
  static final List<SignWord> _allWords = _buildWords();

  static List<SignWord> _buildWords() {
    const data = {
      'Kebutuhan': ['Air', 'Makan'],
      'Aksi':      ['Belajar', 'Berangkat', 'Cari', 'Datang', 'Dengar'],
      'Sapaan':    ['Maaf', 'Terima Kasih'],
      'Orang':     ['Keluarga', 'Saya', 'Teman'],
      'Tanya':     ['Bagaimana', 'Di Mana', 'Kapan', 'Mengapa', 'Siapa'],
      'Tempat':    ['Rumah'],
      'Warna':     ['Hijau', 'Kuning', 'Merah'],
      'Lainnya':   ['Lagi', 'Motor', 'Tuli'],
    };
    return [
      for (final entry in data.entries)
        for (final word in entry.value)
          SignWord.auto(word, entry.key),
    ];
  }

  List<SignWord> get _filteredWords {
    var words = _allWords;
    if (_selectedCategory != 'Semua') {
      words = words.where((w) => w.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      words = words
          .where((w) =>
              w.word.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              w.category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return words;
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Kebutuhan': return AppColors.primary;
      case 'Aksi':      return AppColors.green;
      case 'Sapaan':    return AppColors.yellow;
      case 'Orang':     return AppColors.orange;
      case 'Tanya':     return AppColors.purple;
      case 'Tempat':    return AppColors.teal;
      case 'Warna':     return AppColors.pink;
      case 'Lainnya':   return AppColors.blueGrey;
      default:          return AppColors.primary;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    const Color primaryBlue = AppColors.primary;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: isDark ? Colors.white70 : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kamus Isyarat',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.bgDark1, AppColors.scaffoldDark]
                : [AppColors.bgLight, Colors.white],
          ),
        ),
        child: Column(
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

          // Category filter chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                final catColor =
                    cat == 'Semua' ? primaryBlue : _categoryColor(cat);
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = cat),
                  selectedColor: catColor,
                  backgroundColor:
                      isDark ? Colors.grey[800] : Colors.grey[100],
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? catColor
                        : Colors.transparent,
                  ),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),

          const SizedBox(height: 4),

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
                            color:
                                isDark ? Colors.white38 : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Coba kata lain',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark ? Colors.white24 : Colors.grey[400],
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
                      final catColor = _categoryColor(word.category);
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
                                color:
                                    Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: catColor.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: catColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                word.word,
                                style: TextStyle(
                                  fontSize: (screenWidth * 0.038)
                                      .clamp(14.0, 17.0),
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  word.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? catColor.withValues(alpha: 0.8)
                                        : catColor,
                                    fontWeight: FontWeight.w500,
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
      ),
    );
  }

  void _showGifDialog(BuildContext context, SignWord word) {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final catColor = _categoryColor(word.category);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      word.word,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        word.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: catColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sign_language_rounded,
                              size: 56,
                              color: catColor.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'GIF belum tersedia',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: catColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Tutup',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
