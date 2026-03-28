class ShortNoteModel {
  final String id;
  final String title;
  final String desc;
  final String content;
  final String date;

  ShortNoteModel({
    required this.id,
    required this.title,
    required this.desc,
    required this.content,
    required this.date,
  });

  factory ShortNoteModel.fromJson(Map<String, dynamic> json) {
    return ShortNoteModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      desc: json['desc'] ?? '',
      content: json['content'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'desc': desc,
      'content': content,
      'date': date,
    };
  }
}
