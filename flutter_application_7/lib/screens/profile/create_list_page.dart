import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/tmdb_movie_model.dart';
import '../../services/backend_service.dart';
import 'add_favorite_page.dart';

class CreateListPage extends StatefulWidget {
  const CreateListPage({super.key});

  @override
  State<CreateListPage> createState() => _CreateListPageState();
}

class _CreateListPageState extends State<CreateListPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final BackendService backend = BackendService();

  final List<TMDBMovie> _addedMovies = [];
  bool isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // 🔍 Pick movie using TMDB search
  Future<void> _pickMovie() async {
    final TMDBMovie? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFavoritePage()),
    );

    if (result != null && !_addedMovies.any((m) => m.id == result.id)) {
      setState(() => _addedMovies.add(result));
    }
  }

  // 💾 Save list + movies to DB
  Future<void> _saveList() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("List name is required")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) throw Exception("User not logged in");

      // 1️⃣ Create list
      final listId = await backend.createList(
        token: token,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
      );

      // 2️⃣ Add ALL selected movies
      for (final movie in _addedMovies) {
        await backend.addMovieToList(
          token: token,
          listId: listId,
          movieTmdbId: movie.id!,
        );
      }

      // 3️⃣ Done
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Create List"),
        actions: [
          IconButton(
            icon: isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check, color: Colors.green),
            onPressed: isSaving ? null : _saveList,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📝 List Name
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 22),
              decoration: const InputDecoration(
                hintText: "List name",
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: Colors.white12),

            // 📝 Description
            TextField(
              controller: _descController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white70),
              decoration: const InputDecoration(
                hintText: "Add a description...",
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 24),

            // ➕ Add Film
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: _pickMovie,
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: const Text(
                "Add a film...",
                style: TextStyle(color: Colors.white),
              ),
            ),

            // 🎞️ Poster Grid
            if (_addedMovies.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _addedMovies.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.66,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (_, i) {
                  final movie = _addedMovies[i];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      movie.posterUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.white10),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
