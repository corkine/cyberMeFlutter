// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'blog.freezed.dart';
part 'blog.g.dart';

@freezed
class BlogAuthor with _$BlogAuthor {
  const factory BlogAuthor({@Default("") String name}) = _BlogAuthor;

  factory BlogAuthor.fromJson(Map<String, dynamic> json) =>
      _$BlogAuthorFromJson(json);
}

@freezed
class Blog with _$Blog {
  const factory Blog(
      {@Default("") String id,
      @Default("") String url,
      @Default("") String title,
      @Default("") String content_html,
      @Default("") String summary,
      @Default("") String date_modified,
      BlogAuthor? author}) = _Blog;

  factory Blog.fromJson(Map<String, dynamic> json) => _$BlogFromJson(json);
}

@riverpod
Future<List<Blog>> fetchBlogs(FetchBlogsRef ref) async {
  final response =
      await get(Uri.parse('https://www.mazhangjing.com/rss/feed.json'));
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return (json["items"] as List).map((e) => Blog.fromJson(e)).toList();
}
