class Trip {
  final String id;
  final String title;
  final String destination;
  final String price;
  final String advanceAmount;
  final String type; // 'camp', 'package', 'technical climb', or 'luxury retreat'
  final String? startDate;
  final String? endDate;
  final String imageUrl;
  final String difficulty; // 'Easy', 'Moderate', 'Hard'
  final String status; // 'Available', 'High Demand', 'Waitlist', 'Limited Slots', 'New Trek'
  final String description;

  Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.price,
    required this.advanceAmount,
    required this.type,
    this.startDate,
    this.endDate,
    required this.imageUrl,
    this.difficulty = 'Moderate',
    this.status = 'Available',
    this.description = '',
  });

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['_id'] ?? '',
      title: map['title'] ?? '',
      destination: map['destination'] ?? '',
      price: map['price']?.toString() ?? '0',
      advanceAmount: map['advanceAmount']?.toString() ?? '0',
      type: map['type'] ?? 'camp',
      startDate: map['startDate'],
      endDate: map['endDate'],
      imageUrl: map['imageUrl'] ?? 'https://via.placeholder.com/150',
      difficulty: map['difficulty'] ?? 'Moderate',
      status: map['status'] ?? 'Available',
      description: map['description'] ?? '',
    );
  }
}
