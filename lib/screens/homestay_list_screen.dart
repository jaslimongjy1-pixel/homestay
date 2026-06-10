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
  bool isLoadingMore = false; // Tracks if we are loading the next page
  String errorMessage = '';
  
  // Pagination State Variables
  int currentPage = 1;
  bool hasMoreData = true;
  final int limit = 20;

  final TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController(); // Controls scroll tracking

  @override
  void initState() {
    super.initState();
    fetchStates();
    fetchHomestays(isRefresh: true); 
    
    // Listen to scroll movements
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose(); // Clean up the controller
    super.dispose();
  }

  // Detects when user scrolls near the bottom of the list
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // If aren't already loading and there is still more data on the server, get the next page
      if (!isLoading && !isLoadingMore && hasMoreData) {
        fetchHomestays(query: searchController.text, isRefresh: false);
      }
    }
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

  // Upgraded to handle page increments and appending list data
  Future<void> fetchHomestays({String query = '', bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        isLoading = true;
        errorMessage = '';
        currentPage = 1; // Reset to page 1 on new searches or pull-to-refresh
        hasMoreData = true;
        homestays.clear(); 
      });
    } else {
      setState(() {
        isLoadingMore = true; // Show bottom loading indicator for next pages
      });
    }


    String url = 'http://slum78.myddns.me/homestay2u/api/homestays?limit=$limit&page=$currentPage';
    
    if (query.isNotEmpty) {
      url += '&search=$query';
    }
    if (selectedState != 'All States') {
      url += '&state=$selectedState';
    }

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        List dynamicList = [];
        if (data is List) {
          dynamicList = data;
        } else if (data is Map && data.containsKey('data')) {
          dynamicList = data['data'];
        }

        final List<Homestay> fetchedItems = dynamicList.map((json) => Homestay.fromJson(json)).toList();

        setState(() {
          if (isRefresh) {
            homestays = fetchedItems;
            if (homestays.isEmpty) {
              errorMessage = 'No homestays found.\nPlease try a different keyword.';
            }
          } else {
            homestays.addAll(fetchedItems); // Append new data to existing items list
          }

          // If server returned fewer items than the limit, hit the end of the line
          if (fetchedItems.length < limit) {
            hasMoreData = false;
          } else {
            currentPage++; // Prep for the next page fetch
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
        isLoadingMore = false;
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
                          contentPadding: const EdgeInsets.only(top: 0, bottom: 0, left: 10, right: 75),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onSubmitted: (value) {
                          _addSearchToHistory(value);
                          fetchHomestays(query: value, isRefresh: true);
                        },
                      ),
                      
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
                                fetchHomestays(query: value, isRefresh: true);
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
                              fetchHomestays(query: searchController.text, isRefresh: true);
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
                    initialValue: selectedState,
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
                        fetchHomestays(query: searchController.text, isRefresh: true);
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
                        onRefresh: () => fetchHomestays(query: searchController.text, isRefresh: true),
                        child: ListView.builder(
                          controller: _scrollController, // Bound the scroll tracking controller here
                          // If there's more data, add +1 extra slot at the list end for loading spinner
                          itemCount: homestays.length + (hasMoreData ? 1 : 0),
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            if (index == homestays.length) {
                              // Reached the extra bottom item slot: render loading indicator
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

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