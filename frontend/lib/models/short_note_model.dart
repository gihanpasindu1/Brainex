class ShortNoteModel {
  final String id;
  final String title;
  final String desc;
  final String date;

  ShortNoteModel({
    required this.id,
    required this.title,
    required this.desc,
    required this.date,
  });

  factory ShortNoteModel.fromJson(Map<String, dynamic> json) {
    return ShortNoteModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      desc: json['desc'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'desc': desc,
      'date': date,
    };
  }
}
