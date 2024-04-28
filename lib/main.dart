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
          seedColor: Color(0xFF070D35),
          background: Color(0xFF070D35),
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),  // Changed from MyHomePage to MainScreen
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome to Reelatable')),
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
  int _selectedTabIndex = 0; // To track the selected tab
  int _mainTabIndex = 0;
  String _apiResponse = ''; 

   // Change to store detailed information
  Map<String, Map<String, String>> userResonatedData = {};
  
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
    var url = Uri.parse('http://127.0.0.1:5001/metadata/get_movie_metadata?title=' + Uri.encodeComponent(movieName));
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
    for (int i = 1; i <= 5; i++) {
      var traitKey = '${attributeKey}_${i}_trait';
      var evidenceKey = '${attributeKey}_${i}_evidence';
      if (movie.containsKey(traitKey) && movie.containsKey(evidenceKey)) {
        String fullKey = '${movie['title']} - ${movie[traitKey]}'; // Combining movie title and trait

        listItems.add(CheckboxListTile(
          title: Text(movie[traitKey], style: TextStyle(color: Color(0xFFF2DBAF))),
          subtitle: Text(movie[evidenceKey], style: TextStyle(color: Color(0xFFF2DBAF))),
          value: userResonatedData.containsKey(fullKey),
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                userResonatedData[fullKey] = {
                  'trait': movie[traitKey],
                  'evidence': movie[evidenceKey],
                  'movie': movie['title']
                };
              } else {
                userResonatedData.remove(fullKey);
              }
            });
          },
          activeColor: Colors.red,
        ));
      }
    }
    return SingleChildScrollView(
      child: Column(children: listItems),
    );
  }

  Widget buildResonatedList() {
    List<Widget> items = userResonatedData.entries.map((entry) => ListTile(
      title: Text("${entry.value['trait']} (${entry.value['movie']})", style: TextStyle(color: Color(0xFFF2DBAF))),
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
        backgroundColor: Color(0xFF070D35),
        foregroundColor: Color(0xFFF2DBAF),
        bottom: TabBar(
          onTap: (index) {
            setState(() {
              _mainTabIndex = index;
            });
          },
          labelStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      child: Text('Show Pattern'),
                      onPressed: getMoviePatterns,
                    ),
                    if (_apiResponse.isNotEmpty)
                      buildDataTable(), // Display DataTable if data is available
                  ],
                ),
              ),
            ),
            const Center(child: Text('Recommendations content goes here')),
          ],
        ),
      ),
    ),
  );
}


Map<String, dynamic> _patternData = {}; // To store the parsed pattern data

Future<void> getMoviePatterns() async {
  List<String> movieTitles = movies.map((movie) => movie['title'] as String).toList();
  var url = Uri.parse('http://localhost:5001/patterns/get_movie_patterns');
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
      DataCell(Text(category, style: TextStyle(color: Color(0xFFF2DBAF)))),
      DataCell(Text(clusterTraits.join(", "), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
      DataCell(Text(traitsByCluster[0].join(", "), style: TextStyle(color: Color(0xFFF2DBAF)))),
      DataCell(Text(traitsByCluster.length > 1 ? traitsByCluster[1].join(", ") : "", style: TextStyle(color: Color(0xFFF2DBAF)))),
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
    return DefaultTabController(
      length: 4,
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_errorMessage, style: TextStyle(color: Colors.red, fontSize: 16)),
              ),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Color(0xFF070D35)),
                fillColor: Color(0xFFF2DBAF),
                filled: true,
                border: OutlineInputBorder(),
                labelText: 'List movies that made the deepest impact on you',
              ),
              onSubmitted: _sendDataToBackend,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),  // Adds 20 pixels padding around the button
              child: ElevatedButton(
                onPressed: () => _sendDataToBackend(),
                child: const Text('Add'),
              ),
            ),
            Wrap(
              spacing: 20,
              children: movies.map((movie) => InkWell(
                onTap: () => setState(() => selectedMovie = movie),
                child: Image.network(movie['poster_url'], width: 100, height: 150, fit: BoxFit.cover),
              )).toList(),
            ),
            if (selectedMovie.isNotEmpty) ...[
              Text(selectedMovie['protagonist'] ?? 'Protagonist not found', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF2DBAF))),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text("Select characteristics that resonate with you", style: TextStyle(fontSize: 18, color: Color(0xFFF2DBAF))),
              ),
                DefaultTabController(
                  length: 4,
                  child: Column(
                    children: <Widget>[
                      TabBar(
                        onTap: (index) {
                          setState(() {
                            _selectedTabIndex = index;
                          });
                        },
                        indicatorColor: Colors.red,
                        labelColor: Colors.red,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(text: 'Flaws'),
                          Tab(text: 'Personality Traits'),
                          Tab(text: 'Desires'),
                          Tab(text: 'Beliefs'),
                        ],
                      ),
                      Container(
                        height: 300,
                        child: Expanded(
                          child: TabBarView(
                            children: [
                              attributeList(selectedMovie, 'flaws'),
                              attributeList(selectedMovie, 'personality_traits'),
                              attributeList(selectedMovie, 'desires'),
                              attributeList(selectedMovie, 'beliefs'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20.0),  // Adds 20 pixels padding around the button
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showResonated = !showResonated; // Toggle the display of resonated items
                    });
                  },
                  child: Text('Show Resonated'),
                ),
              ),
              if (showResonated) buildResonatedList(),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}





