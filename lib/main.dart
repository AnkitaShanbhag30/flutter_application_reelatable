import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reelatable',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF070D35),
          background: const Color(0xFF070D35),
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),  // Changed from MyHomePage to MainScreen
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Reelatable')),
      body: const MyHomePage(title: 'Reelatable'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textController = TextEditingController();
  List<Map<String, dynamic>> movies = [];
  Map<String, dynamic> selectedMovie = {};
  bool showResonated = false; // State to toggle display of resonated data
  String _errorMessage = '';
  int _mainTabIndex = 0;
  String _apiResponse = ''; 
  // final List<String> allMoviesList = [
  //   "Up", "Moana", "Frozen", "Interstellar", "Inception", "Batman Begins", "The Matrix"
  // ];
  final List<String> allMoviesList = []; 

  @override
  void initState() {
    super.initState();
    _fetchAllMovies();
  }

  Future<void> _fetchAllMovies() async {
    const url = 'http://34.82.187.110/all_movies/get_all_movies';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> responseData = json.decode(response.body);
        setState(() {
          allMoviesList.addAll(responseData.map<String>((movie) => movie as String));
        });
      } else {
        print('Failed to load all movies: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred while fetching all movies: $e');
    }
  }

   // Change to store detailed information
  Map<String, Map<String, String>> userResonatedData = {};

  Map<String, List<String>> userResonatedDataForRecommendations = {
    "beliefs": [],
    "desires": [],
    "personality_traits": [],
    "flaws": []
  };

  
  // Helper function to extract and organize data from each category
  Map<String, dynamic> _parseTraits(Map<String, dynamic> categoryData) {
    // Extract cluster traits
    List<String> clusterTraits = List<String>.from(categoryData['cluster_traits']);

    // Extract traits from each cluster
    List<List<String>> traitsByCluster = categoryData['clusters']
        .map<List<String>>((cluster) => List<String>.from(cluster['traits']))
        .toList();

    // Ensure there are at least two clusters, filling with empty lists if necessary
    while (traitsByCluster.length < 2) {
      traitsByCluster.add([]);
    }

    return {
      'clusterTraits': clusterTraits,
      'traitsByCluster': traitsByCluster,
    };
  }


  Future<void> _sendDataToBackend([String? movieName]) async {
    movieName ??= _textController.text;
    var url = Uri.parse('http://34.82.187.110/metadata/get_movie_metadata?title=${Uri.encodeComponent(movieName)}');
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          movies.add(data);
          _errorMessage = '';
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch data for the movie: $movieName';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sending data to backend: $e';
      });
    }
  }

  Widget attributeList(Map<String, dynamic> movie, String attributeKey) {
    List<Widget> listItems = [];

    try {
      for (int i = 1; i <= 5; i++) {
        var traitKey = '${attributeKey}_${i}_trait';
        var evidenceKey = '${attributeKey}_${i}_evidence';
        print(i);
        print(movie['title']);
        print('\n');
        // Ensure the movie map contains the keys before accessing them
        if (movie.containsKey(traitKey) && movie.containsKey(evidenceKey)) {
          String fullKey = '${movie['title']} - ${movie[traitKey]}';
          listItems.add(CheckboxListTile(
            title: Text(movie[traitKey], style: const TextStyle(color: Color(0xFFF2DBAF))),
            subtitle: Text(movie[evidenceKey], style: const TextStyle(color: Color(0xFFF2DBAF))),
            value: userResonatedData.containsKey(fullKey),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  userResonatedData[fullKey] = {
                    'trait': movie[traitKey],
                    'evidence': movie[evidenceKey],
                    'movie': movie['title']
                  };
                  // Optionally add to recommendations data
                  userResonatedDataForRecommendations[attributeKey]?.add(movie[traitKey]);
                } else {
                  userResonatedData.remove(fullKey);
                  // Optionally remove from recommendations data
                  userResonatedDataForRecommendations[attributeKey]?.remove(movie[traitKey]);
                }
              });
            },
            activeColor: Colors.red,
          ));
        }
      }
      print('try finished');
      print(movie['title']);
      print('\n');
    } catch (e) {
      print('Error building attribute list for $attributeKey: $e');
      // Display an error message or an error widget
      listItems.add(Center(
        child: Text('Failed to load data for $attributeKey.', style: const TextStyle(color: Colors.red)),
      ));
    }

    return SingleChildScrollView(
      child: Column(children: listItems),
    );
  }

  Widget buildResonatedList() {
    List<Widget> items = userResonatedData.entries.map((entry) => ListTile(
      title: Text("${entry.value['trait']} (${entry.value['movie']})", style: const TextStyle(color: Color(0xFFF2DBAF))),
      subtitle: Text(entry.value['evidence']!, style: const TextStyle(color: Color(0xFFF2DBAF)))
    )).toList();

    return SingleChildScrollView(
      child: Column(children: items),
    );
  }

@override
Widget build(BuildContext context) {
  return DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(100.0),
          child: Text(widget.title),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF070D35),
        foregroundColor: const Color(0xFFF2DBAF),
        bottom: TabBar(
          onTap: (index) {
            setState(() {
              _mainTabIndex = index;
            });
          },
          labelStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          indicatorColor: Colors.red,
          labelColor: Colors.red,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Home'),
            Tab(text: 'Patterns'),
            Tab(text: 'Recommendations'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 100.0, right: 100.0),
        child: TabBarView(
          children: [
            homeTab(), // Your existing content
            Center(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: getMoviePatterns,
                      child: const Text('Show Pattern'),
                    ),
                    if (_apiResponse.isNotEmpty)
                      buildDataTable(), // Display DataTable if data is available
                  ],
                ),
              ),
            ),
            // const Center(child: Text('Recommendations content goes here')),
            recommendationsTab(),
          ],
        ),
      ),
    ),
  );
}


Map<String, dynamic> _patternData = {}; // To store the parsed pattern data

Future<void> getMoviePatterns() async {
  List<String> movieTitles = movies.map((movie) => movie['title'] as String).toList();
  var url = Uri.parse('http://34.82.187.110/patterns/get_movie_patterns');
  var response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"titles": movieTitles}),
  );

  if (response.statusCode == 200) {
    setState(() {
      _apiResponse = response.body;
      _patternData = json.decode(response.body); // Parsing and storing the data
      _generateTableRows(_patternData); // Prepare rows for DataTable
    });
  } else {
    print('Request failed with status: ${response.statusCode}.');
  }
}

// Function to generate rows for the DataTable with specific styling
List<DataRow> _generateTableRows(Map<String, dynamic> data) {
  List<DataRow> rows = [];
  data.forEach((category, details) {
    Map<String, dynamic> parsedData = _parseTraits(details);
    List<String> clusterTraits = parsedData['clusterTraits'];
    List<List<String>> traitsByCluster = parsedData['traitsByCluster'];

    rows.add(DataRow(cells: [
      DataCell(Text(category, style: const TextStyle(color: Color(0xFFF2DBAF)))),
      DataCell(Text(clusterTraits.join(", "), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
      DataCell(Text(traitsByCluster[0].join(", "), style: const TextStyle(color: Color(0xFFF2DBAF)))),
      DataCell(Text(traitsByCluster.length > 1 ? traitsByCluster[1].join(", ") : "", style: const TextStyle(color: Color(0xFFF2DBAF)))),
    ]));
  });
  return rows;
}

// Widget to build the DataTable
Widget buildDataTable() {
  List<DataRow> rows = _generateTableRows(_patternData);  // Ensure _patternData is your parsed JSON data

  return DataTable(
    columns: const [
      DataColumn(label: Text('Attribute', style: TextStyle(color: Color(0xFFF2DBAF)))),
      DataColumn(label: Text('Cluster Traits', style: TextStyle(color: Color(0xFFF2DBAF)))),
      DataColumn(label: Text('Traits in First Cluster', style: TextStyle(color: Color(0xFFF2DBAF)))),
      DataColumn(label: Text('Traits in Second Cluster', style: TextStyle(color: Color(0xFFF2DBAF)))),
    ],
    rows: rows,
  );
}

Widget homeTab() {
  print("Building home tab..."); // Log when home tab is being built

  return DefaultTabController(
    length: 4,
    child: SingleChildScrollView(
      child: Column(
        children: <Widget>[
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)),
            ),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return allMoviesList.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              print("Movie selected: $selection"); // Log the movie selected
              setState(() {
                _textController.text = selection; // Set text to the selected movie
                _sendDataToBackend(selection); // Optionally fetch data right after selection
              });
            },
            fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
              return TextField(
                controller: fieldTextEditingController,
                focusNode: fieldFocusNode,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Color(0xFF070D35)),
                  fillColor: Color(0xFFF2DBAF),
                  filled: true,
                  border: OutlineInputBorder(),
                  labelText: 'List movies that made the deepest impact on you',
                ),
                onSubmitted: (String value) => onFieldSubmitted(),
              );
            },
            optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 48,
                      maxHeight: 200,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return GestureDetector(
                          onTap: () => onSelected(option),
                          child: ListTile(
                            title: Text(option),
                            tileColor: const Color(0xFFAAAAAA),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () => _sendDataToBackend(),
              child: const Text('Add'),
            ),
          ),
          Wrap(
            spacing: 20,
            children: movies.map((movie) {
              final bool isSelected = selectedMovie == movie;
              final double size = isSelected ? 130.0 : 100.0;
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  InkWell(
                    onTap: () => setState(() {
                      print("Movie tapped: ${movie['title']}"); // Log which movie was tapped
                      selectedMovie = movie;
                    }),
                    child: Image.network(movie['poster_url'], width: size, height: size * 1.5, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: -10,
                    top: -10,
                    child: IconButton(
                      icon: const Icon(Icons.highlight_remove, color: Colors.white, size: 24),
                      onPressed: () {
                        setState(() {
                          print("Removing movie: ${movie['title']}"); // Log movie removal
                          movies.remove(movie);
                        });
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          if (selectedMovie.isNotEmpty) ...[
            const SizedBox(height: 30),
            Text('Protagonist: ' + (selectedMovie['protagonist'] ?? 'Protagonist not found'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF2DBAF))),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text("Select characteristics that resonate with you", style: TextStyle(fontSize: 18, color: Color(0xFFF2DBAF))),
            ),
            DefaultTabController(
              length: 4,
              child: Column(
                children: <Widget>[
                  TabBar(
                    onTap: (index) {
                      print("Tab selected: $index"); // Log tab selection
                      setState(() {});
                    },
                    indicatorColor: Colors.red,
                    labelColor: Colors.red,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Flaws'),
                      Tab(text: 'Personality Traits'),
                      Tab(text: 'Desires'),
                      Tab(text: 'Beliefs'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        attributeList(selectedMovie, 'flaws'),
                        attributeList(selectedMovie, 'personality_traits'),
                        attributeList(selectedMovie, 'desires'),
                        attributeList(selectedMovie, 'beliefs'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    print("Toggling resonated list visibility"); // Log toggle action
                    showResonated = !showResonated;
                  });
                },
                child: const Text('Show Resonated'),
              ),
            ),
            if (showResonated) buildResonatedList(),
          ],
        ],
      ),
    ),
  );
}

  // State to hold movie poster URLs

  List<Map<String, String>> _movieDetails = [];

Future<void> _getMovieRecommendations() async {
  const url = 'http://34.82.187.110/recommendations/get_movie_recommendations';
  List<String> movieTitles = movies.map((movie) => movie['title'] as String).toList();

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'movie_titles': movieTitles,
        'alpha': 0.0,
        'num_movies': 5
      }),
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      setState(() {
        _movieDetails = responseData.map<Map<String, String>>((movie) => {
          'poster_url': movie['poster_url'],
          'title': movie['title'],
          'overview': movie['overview'],
        }).toList();
      });
    } else {
      print('Failed to load recommendations');
    }
  } catch (e) {
    print('Error occurred while fetching recommendations: $e');
  }
}

void _showMovieDetails(String title, String overview) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFFF2DBAF),
        title: Text(title),
        content: Text(overview),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


  Widget _buildMoviePosters() {
  return Wrap(
    spacing: 8.0, // Adds space between images
    children: _movieDetails.map((movieDetail) => GestureDetector(
      onTap: () => _showMovieDetails(movieDetail['title']!, movieDetail['overview']!),
      child: Image.network(movieDetail['poster_url']!, width: 100, height: 150),
    )).toList(),
  );
}


  Widget recommendationsTab() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          ElevatedButton(
            onPressed: _getMovieRecommendations,
            child: const Text('Get Movies Based on Selected Movies'),
          ),
          const SizedBox(height: 20),
          _buildMoviePosters(),
          const SizedBox(height: 20),
          ElevatedButton(
            // onPressed: _getMoviesBasedOnResonatedTraits,
            onPressed: () {
              // print(userResonatedData);
              _getMoviesBasedOnResonatedTraits();
            },
            child: const Text('Get Movies Based on Resonated Traits'),
          ),
          const SizedBox(height: 20),
          _buildTraitBasedMoviePosters(),
        ],
      ),
    );
  }

  // State to hold movie poster URLs for trait-based recommendations

List<Map<String, String>> _traitBasedMovieDetails = [];

Future<void> _getMoviesBasedOnResonatedTraits() async {
  const url = 'http://34.82.187.110/recommendations/search_by_traits';
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "traits": userResonatedDataForRecommendations, 
        "num_results": 5
      }),
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      setState(() {
        _traitBasedMovieDetails = responseData.map<Map<String, String>>((movie) => {
          'poster_url': movie['poster_url'] as String,
          'title': movie['title'] as String,
          'overview': movie['overview'] as String
        }).toList();
      });
    } else {
      print('Failed to load trait-based recommendations: ${response.body}');
    }
  } catch (e) {
    print('Error occurred while fetching trait-based recommendations: $e');
  }
}

void _showMovieDetails2(String title, String overview) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFFF2DBAF),
        title: Text(title),
        content: Text(overview),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Widget _buildTraitBasedMoviePosters() {
  return Wrap(
    spacing: 8.0, // Adds space between images
    children: _traitBasedMovieDetails.map((movieDetail) => GestureDetector(
      onTap: () => _showMovieDetails2(movieDetail['title']!, movieDetail['overview']!),
      child: Image.network(movieDetail['poster_url']!, width: 100, height: 150),
    )).toList(),
  );
}

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}