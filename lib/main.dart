import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

// ===================== MODEL =====================
class Meal {
  final String id;
  final String name;
  final String category;
  final String area;
  final String thumb;
  final String instructions;

  Meal({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.thumb,
    required this.instructions,
  });

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        id: json['idMeal'] ?? '',
        name: json['strMeal'] ?? '',
        category: json['strCategory'] ?? '-',
        area: json['strArea'] ?? '-',
        thumb: json['strMealThumb'] ?? '',
        instructions: json['strInstructions'] ?? '',
      );
}

// ===================== APP =====================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daftar Makanan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const MealListPage(),
    );
  }
}

// ===================== HALAMAN LIST =====================
class MealListPage extends StatefulWidget {
  const MealListPage({super.key});

  @override
  State<MealListPage> createState() => _MealListPageState();
}

class _MealListPageState extends State<MealListPage> {
  final ScrollController _scrollController = ScrollController();
  List<Meal> _meals = [];
  bool _isLoading = true;
  String? _error;
  bool _showToTop = false;

  @override
  void initState() {
    super.initState();
    _fetchMeals();

    // Fitur 2: tombol muncul setelah scroll > 300 px
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showToTop) {
        setState(() => _showToTop = show);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Fitur 3: ambil data makanan dari TheMealDB
  Future<void> _fetchMeals() async {
    try {
      final url =
          Uri.parse('https://www.themealdb.com/api/json/v1/1/search.php?s=');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['meals'] ?? [];
        if (!mounted) return;
        setState(() {
          _meals = list.map((e) => Meal.fromJson(e)).toList();
          _error = null;
          _isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data (${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Makanan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
      floatingActionButton: _showToTop
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              tooltip: 'Kembali ke atas',
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Fitur 1: pull-to-refresh
    return RefreshIndicator(
      onRefresh: _fetchMeals,
      child: _error != null
          ? ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 200),
                Center(child: Text(_error!)),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: _meals.length,
              itemBuilder: (context, index) {
                final meal = _meals[index];
                return Card(
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MealDetailPage(meal: meal),
                        ),
                      );
                    },
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        meal.thumb,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.fastfood, size: 40),
                      ),
                    ),
                    title: Text(meal.name),
                    subtitle: Text('${meal.category} • ${meal.area}'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
    );
  }
}

// ===================== HALAMAN DETAIL =====================
class MealDetailPage extends StatelessWidget {
  final Meal meal;
  const MealDetailPage({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(meal.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              meal.thumb,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 300,
                child: Center(child: Icon(Icons.fastfood, size: 80)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text('Kategori: ${meal.category}'),
                  const SizedBox(height: 4),
                  Text('Asal: ${meal.area}'),
                  const SizedBox(height: 16),
                  Text(
                    'Cara Membuat',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(meal.instructions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}