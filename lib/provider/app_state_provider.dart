import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/anime.dart';
import '../data/dummy_data.dart';

class AppStateProvider extends ChangeNotifier {
  // Data yang ingin disimpan di sini
  List<Anime> _favorites = [];

  // Kunci Penyimpanan
  static const String _storageKey = 'favorite_anime_list';

  // Constructor: otomatis memuat favorit saat provider dibuat
  AppStateProvider() {
    _loadFavorites();
  }

  // Getters
  List<Anime> get favorites => _favorites;

  // State Genre & Search
  String _selectedGenre = "All";
  String _homeSearchQuery = "";
  String _favoriteSearchQuery = "";

  String get selectedGenre => _selectedGenre;
  String get homeSearchQuery => _homeSearchQuery;
  String get favoriteSearchQuery => _favoriteSearchQuery;

  void setSelectedGenre(String genre) {
    _selectedGenre = genre;
    notifyListeners();
  }

  void setHomeSearchQuery(String query) {
    _homeSearchQuery = query;
    notifyListeners();
  }

  void setFavoriteSearchQuery(String query) {
    _favoriteSearchQuery = query;
    notifyListeners();
  }

/// Filter untuk Home (Genre + Search)
  List<Anime> getFilteredAnimeForHome() {
    List<Anime> result = DummyData.animeList;

    // Filter berdasarkan Genre
    if (_selectedGenre != "All") {
      result = result.where((anime) {
        // Mengubah string genre (misal: "Action, Adventure") menjadi list dengan memisahkannya berdasarkan koma
        final animeGenres = anime.genre.toLowerCase().split(',').map((e) => e.trim()).toList();
        return animeGenres.contains(_selectedGenre.toLowerCase());
      }).toList();
    }

    // Filter berdasarkan Search Query Home
    if (_homeSearchQuery.isNotEmpty) {
      result = result.where((anime) {
        return anime.title.toLowerCase().contains(_homeSearchQuery.toLowerCase());
      }).toList();
    }

    return result;
  }

// Filter untuk Favorites (Search)
  List<Anime> getFilteredFavorites() {
    if (_favoriteSearchQuery.isEmpty) {
      return _favorites;
    }
    return _favorites.where((anime) {
      return anime.title.toLowerCase().contains(_favoriteSearchQuery.toLowerCase());
    }).toList();
  }

  // Helper functions untuk tahu apakah anime sudah ada di favorite atau belum
  bool isFavorite(String id) {
    return _favorites.any((anime) => anime.id == id);
  }

  void toggleFavorite(Anime anime) {
    if (isFavorite(anime.id)) {
      removeFavorite(anime.id);
    } else {
      addFavorite(anime);
    }
  }

  // Fungsi untuk menambahkan anime ke daftar favorit
  void addFavorite(Anime anime) {
    if (!isFavorite(anime.id)) {
      _favorites.add(anime);
      _saveFavorites(); // Tambahkan, untuk menyimpan data ke shared preferences
      notifyListeners();
    }
  }

  // Fungsi untuk menghapus anime berdasarkan ID dari daftar favorit
  void removeFavorite(String animeId) {
    _favorites.removeWhere((anime) => anime.id == animeId);
    _saveFavorites(); // Tambahkan, untuk menyimpan data ke shared preferences
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // List Anime -> List Map
      final List<Map<String, dynamic>> favoritesJson =
      _favorites.map((anime) => anime.toJson()).toList();

      // List Map di-encode ke JSON string lalu disimpan
      await prefs.setString(_storageKey, jsonEncode(favoritesJson));
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? favoritesJson = prefs.getString(_storageKey);

      if (favoritesJson != null) {
        final List<dynamic> decoded = jsonDecode(favoritesJson);

        _favorites = decoded
            .map((item) => Anime.fromJson(item as Map<String, dynamic>))
            .toList();

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }
}