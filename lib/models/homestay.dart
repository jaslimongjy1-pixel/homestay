class Homestay {
  final String name;
  final String state;
  final String district;
  final String price;
  final String description;
  final String imageUrl;

  Homestay({
    required this.name,
    required this.state,
    required this.district,
    required this.price,
    required this.description,
    required this.imageUrl,
  });

  factory Homestay.fromJson(Map<String, dynamic> json) {
    return Homestay(
      name: json['name']?.toString() ?? 'Unknown Homestay',
      state: json['state']?.toString() ?? 'Unknown',
      district: json['district']?.toString() ?? 'Unknown',
      
      // Matched directly to the server's parameter:
      price: json['price_min']?.toString() ?? '0.00', 
      
      description: json['description']?.toString() ?? 'No description available.',
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }
}