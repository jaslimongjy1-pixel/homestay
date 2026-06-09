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
  String selectedState = 'All States';
  
  bool isLoading = false;
  String errorMessage = '';
  
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchStates();
    fetchHomestays();
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
            errorMessage = 'No homestays found.\nPlease try a different search.';
          }
        });
      } else {
        setState(() {
          errorMessage = 'Unable to load data from server. (Error ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Please check your internet connection.\nFailed to reach API.';
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
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search (e.g. river, beach)',
                      prefixIcon: const Icon(Icons.house_outlined),
                      
                      // 🟢 ADDED: Clickable Search Button on the right side of the text field
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: Colors.blue),
                        onPressed: () {
                          // Triggers search using the text currently inside the controller
                          fetchHomestays(query: searchController.text);
                        },
                      ),
                      
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    ),
                    onSubmitted: (value) => fetchHomestays(query: value), // Optional: keeps keyboard enter working too
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
                                          color: Colors.green, fontWeight: FontWeight.bold),
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