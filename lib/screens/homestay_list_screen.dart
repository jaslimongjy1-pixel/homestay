import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:homestay/models/homestay.dart';
import 'package:homestay/screens/homestay_detail_screen.dart';

class HomestayListScreen extends StatefulWidget {
  const HomestayListScreen({super.key});

  @override
  State<HomestayListScreen> createState() => _HomestayListScreenState();
}

class _HomestayListScreenState extends State<HomestayListScreen> {
  List<Homestay> homestays = [];
  List<String> states = ['All States']; 
  List<String> recentSearches = []; 
  String selectedState = 'All States';
  
  bool isLoading = false;
  String errorMessage = '';
  
  final TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    fetchStates();
    fetchHomestays();
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _addSearchToHistory(String query) {
    String trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      setState(() {
        recentSearches.remove(trimmed); 
        recentSearches.insert(0, trimmed); 
        if (recentSearches.length > 5) {
          recentSearches.removeLast(); 
        }
      });
    }
  }

  Future<void> fetchStates() async {
    try {
      final response = await http.get(Uri.parse('http://slum78.myddns.me/homestay2u/api/states'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('data')) {
          final List stateList = data['data'];
          setState(() {
            states = ['All States', ...stateList.map((e) => e['state'].toString())];
          });
        }
      }
    } catch (e) {
      debugPrint("Could not load states: $e");
    }
  }

  Future<void> fetchHomestays({String query = ''}) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    String url = 'http://slum78.myddns.me/homestay2u/api/homestays?limit=20';
    
    if (query.isNotEmpty) {
      url += '&search=$query';
    }
    if (selectedState != 'All States') {
      url += '&state=$selectedState';
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        List dynamicList = [];
        if (data is List) {
          dynamicList = data;
        } else if (data is Map && data.containsKey('data')) {
          dynamicList = data['data'];
        }

        setState(() {
          homestays = dynamicList.map((json) => Homestay.fromJson(json)).toList();
          if (homestays.isEmpty) {
            errorMessage = 'No homestays found.\nPlease try a different keyword.';
          }
        });
      } else {
        setState(() {
          errorMessage = 'Unable to load data from server. (Error ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Please check your internet connection.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homestay2U Malaysia'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      TextField(
                        controller: searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search (e.g. river, beach)',
                          prefixIcon: const Icon(Icons.house_outlined),
                          // Extra right padding prevents text from overlapping custom suffix layout
                          contentPadding: const EdgeInsets.only(top: 0, bottom: 0, left: 10, right: 75),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onSubmitted: (value) {
                          _addSearchToHistory(value);
                          fetchHomestays(query: value);
                        },
                      ),
                      
                      // Integrated Dropdown List Actions Layout inside the Search Bar
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (recentSearches.isNotEmpty)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              tooltip: 'Search History Dropdown List',
                              offset: const Offset(0, 48),
                              onSelected: (String value) {
                                setState(() {
                                  searchController.text = value;
                                });
                                fetchHomestays(query: value);
                              },
                              itemBuilder: (BuildContext context) {
                                return recentSearches.map((String historyItem) {
                                  return PopupMenuItem<String>(
                                    value: historyItem,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.history, size: 18, color: Colors.grey),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            historyItem,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          IconButton(
                            icon: Icon(Icons.search, color: Theme.of(context).primaryColor),
                            onPressed: () {
                              _addSearchToHistory(searchController.text);
                              fetchHomestays(query: searchController.text);
                              _searchFocusNode.unfocus();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedState,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    ),
                    items: states.map((String state) {
                      return DropdownMenuItem<String>(
                        value: state,
                        child: Text(state, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedState = newValue;
                        });
                        fetchHomestays(query: searchController.text);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => fetchHomestays(query: searchController.text),
                        child: ListView.builder(
                          itemCount: homestays.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            final homestay = homestays[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(10),
                                leading: homestay.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          homestay.imageUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.house, size: 60, color: Colors.grey),
                                        ),
                                      )
                                    : const Icon(Icons.house, size: 60, color: Colors.grey),
                                title: Text(
                                  homestay.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('${homestay.district}, ${homestay.state}'),
                                    const SizedBox(height: 4),
                                    Text(
                                      'RM ${homestay.price}',
                                      style: const TextStyle(
                                          color: Color.fromARGB(255, 65, 201, 203), fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HomestayDetailScreen(homestay: homestay),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}