class CustomNotification {
  final int? id;
  final String title;
  final String body;
  String? route;
  Map<String, dynamic>? arguments;
  String? image;
  final String payload;

  CustomNotification({
    required this.id,
    required this.title,
    required this.body,
    this.route,
    this.arguments,
    this.image,
    required this.payload,
  });
}