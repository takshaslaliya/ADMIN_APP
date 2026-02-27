class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime time;
  final bool isSystem;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.time,
    this.isSystem = false,
  });
}
