/// url : "https://www.mini4k.com/shows/694884"
/// img : "https://www.mini4k.com/sites/default/files/styles/size_180_270/public/images/poster/2023-09/p1696080418.jpg?itok=wYuImScs"
/// title : "V世代"
/// update : "第1季第4集"
/// star : "8.2"

class Movie {
  Movie({
    String? url,
    String? img,
    String? title,
    String? update,
    String? star,
  }) {
    _url = url;
    _img = img;
    _title = title;
    _update = update;
    _star = star;
  }

  @override
  String toString() {
    return 'Movie{_url: $_url, _img: $_img, _title: $_title, _update: $_update, _star: $_star}';
  }

  Movie.fromJson(dynamic json) {
    _url = json['url'];
    _img = json['img'];
    _title = json['title'];
    _update = json['update'];
    _star = json['star'];
  }

  String? _url;
  String? _img;
  String? _title;
  String? _update;
  String? _star;

  Movie copyWith({
    String? url,
    String? img,
    String? title,
    String? update,
    String? star,
  }) =>
      Movie(
        url: url ?? _url,
        img: img ?? _img,
        title: title ?? _title,
        update: update ?? _update,
        star: star ?? _star,
      );

  String? get url => _url;

  String? get img => _img;

  String? get title => _title;

  String? get update => _update;

  String? get star => _star;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['url'] = _url;
    map['img'] = _img;
    map['title'] = _title;
    map['update'] = _update;
    map['star'] = _star;
    return map;
  }
}
