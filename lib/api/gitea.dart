// ignore_for_file: invalid_annotation_target

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'gitea.freezed.dart';
part 'gitea.g.dart';

@freezed
class GitSetting with _$GitSetting {
  factory GitSetting({String? token, String? endpoint, String? githubToken}) =
      _GitSetting;

  factory GitSetting.fromJson(Map<String, dynamic> json) =>
      _$GitSettingFromJson(json);
}

@riverpod
class GitSettings extends _$GitSettings {
  @override
  Future<GitSetting> build() async {
    try {
      final s = await SharedPreferences.getInstance();
      final d = s.getString("gitSetting") ?? "{}";
      return GitSetting.fromJson(jsonDecode(d));
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      return GitSetting();
    }
  }

  Future<void> set(GitSetting setting) async {
    final s = await SharedPreferences.getInstance();
    s.setString("gitSetting", jsonEncode(setting.toJson()));
    state = AsyncData(setting);
  }
}

@freezed
class GitUser with _$GitUser {
  const factory GitUser({
    @Default(0) int id,
    @Default("") String login,
    @Default("") @JsonKey(name: "login_name") String loginName,
    @Default("") @JsonKey(name: "full_name") String fullName,
    @Default("") String email,
    @Default("") @JsonKey(name: "avatar_url") String avatarUrl,
    @Default("") String language,
    @Default(false) @JsonKey(name: "is_admin") bool isAdmin,
    @Default("") @JsonKey(name: "last_login") String lastLogin,
    @Default("") String created,
    @Default(false) @JsonKey(name: "prohibit_login") bool prohibitLogin,
    @Default("") String location,
    @Default("") String description,
    @Default("") String visibility,
    @Default("") String username,
  }) = _GitUser;

  factory GitUser.fromJson(Map<String, dynamic> json) =>
      _$GitUserFromJson(json);
}

@freezed
class GitRepo with _$GitRepo {
  const factory GitRepo(
      {@Default(0) int id,
      @Default("") String name,
      @Default("") String owner,
      @Default("") @JsonKey(name: "full_name") String fullName}) = _GitRepo;

  factory GitRepo.fromJson(Map<String, dynamic> json) =>
      _$GitRepoFromJson(json);
}

@freezed
class GitIssue with _$GitIssue {
  factory GitIssue({
    @Default(0) int id,
    @Default("") String url,
    @Default("") @JsonKey(name: "html_url") String htmlUrl,
    @Default(0) int number,
    @Default("") String title,
    @Default("") String body,
    @Default("") String ref,
    @Default("") @JsonKey(name: "created_at") String createdAt,
    @Default("") @JsonKey(name: "updated_at") String updatedAt,
    @JsonKey(name: "closed_at") String? closedAt,
    @JsonKey(name: "due_date") String? dueDate,
    @Default(GitRepo()) GitRepo repository,
    @Default(GitUser()) GitUser user,
  }) = _GitIssue;

  factory GitIssue.fromJson(Map<String, dynamic> json) =>
      _$GitIssueFromJson(json);
}

@riverpod
Future<List<GitIssue>> getGitIssues(GetGitIssuesRef ref, bool open) async {
  final entity = await ref.watch(gitSettingsProvider.future);
  if (entity.endpoint == null || entity.token == null) return [];
  var stateQuery = open ? "state=open" : "state=closed";
  final resp = await get(Uri.parse(
      "${entity.endpoint}/api/v1/repos/issues/search?$stateQuery&token=${entity.token}"));
  return (jsonDecode(resp.body) as List? ?? [])
      .map((e) => GitIssue.fromJson(e))
      .toList(growable: false);
}

@freezed
class GitRepoDetail with _$GitRepoDetail {
  factory GitRepoDetail(
      {@Default(0) int id,
      @Default(GitUser()) GitUser owner,
      @Default("") String name,
      @Default("") @JsonKey(name: "full_name") String fullName,
      @Default("") String description,
      @Default(false) bool empty,
      @Default(false) bool private,
      @Default(false) bool template,
      @Default(false) bool fork,
      @Default(false) bool mirror,
      @Default(-1) int size,
      @Default("") String language,
      @Default("") @JsonKey(name: "languates_url") String languatesUrl,
      @Default("") @JsonKey(name: "html_url") String htmlUrl,
      @Default("") String link,
      @Default("") @JsonKey(name: "ssh_url") String sshUrl,
      @Default("") @JsonKey(name: "clone_url") String cloneUrl,
      @Default("") @JsonKey(name: "original_url") String originalUrl,
      @Default("") String website,
      @Default(0) @JsonKey(name: "stars_count") int startCount,
      @Default(0) @JsonKey(name: "forks_count") int forksCount,
      @Default(0) @JsonKey(name: "watchers_count") int watchedsCount,
      @Default(0) @JsonKey(name: "open_issues_count") int openIssuesCount,
      @Default(0) @JsonKey(name: "open_pr_counter") int openPrCounter,
      @Default(0) @JsonKey(name: "release_counter") int releaseCounter,
      @Default("") @JsonKey(name: "default_branch") String defaultBranch,
      @Default(false) bool archived,
      @Default("") @JsonKey(name: "created_at") String createdAt,
      @Default("") @JsonKey(name: "updated_at") String updatedAt,
      @Default("") @JsonKey(name: "avatar_url") String avatarUrl,
      @Default([]) List<GitRepoPushMirror> pushMirrors}) = _GitRepoDetail;

  factory GitRepoDetail.fromJson(Map<String, dynamic> json) =>
      _$GitRepoDetailFromJson(json);
}

@riverpod
Future<List<GitRepoDetail>> getGitRepos(GetGitReposRef ref) async {
  final entity = await ref.watch(gitSettingsProvider.future);
  if (entity.endpoint == null || entity.token == null) return [];
  final resp = await get(Uri.parse(
      "${entity.endpoint}/api/v1/repos/search?token=${entity.token}"));
  final repos = (jsonDecode(resp.body)["data"] as List? ?? [])
      .map((e) => GitRepoDetail.fromJson(e))
      .toList(growable: false);
  final reposWithPushMirror = repos.map((e) async {
    final owner = e.owner.username;
    final repo = e.name;
    var pushMirrors = <GitRepoPushMirror>[];
    try {
      final resp = await get(Uri.parse(
          "${entity.endpoint}/api/v1/repos/$owner/$repo/push_mirrors?token=${entity.token}"));
      pushMirrors = (jsonDecode(resp.body) as List? ?? [])
          .map((e) => GitRepoPushMirror.fromJson(e))
          .toList(growable: false);
    } catch (_, st) {
      debugPrintStack(stackTrace: st);
    }
    return e.copyWith(pushMirrors: pushMirrors);
  });
  return await Future.wait(reposWithPushMirror);
}

@riverpod
Future<String> postGitIssue(PostGitIssueRef ref, String repo, String owner,
    String title, String body) async {
  final entity = await ref.watch(gitSettingsProvider.future);
  if (entity.endpoint == null || entity.token == null) return "";
  final resp = await post(
      Uri.parse(
          "${entity.endpoint}/api/v1/repos/$owner/$repo/issues?token=${entity.token}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"body": body, "title": title}));
  return resp.body;
}

@riverpod
Future<String> deleteGitIssue(
    DeleteGitIssueRef ref, String owner, String repo, int index) async {
  final entity = await ref.watch(gitSettingsProvider.future);
  if (entity.endpoint == null || entity.token == null) return "";
  final url = Uri.parse(
      "${entity.endpoint}/api/v1/repos/$owner/$repo/issues/$index?token=${entity.token}");
  final resp = await delete(url);
  return resp.body;
}

@freezed
class GitRepoPushMirror with _$GitRepoPushMirror {
  const factory GitRepoPushMirror(
          {@Default("") @JsonKey(name: "repo_name") String repoName,
          @Default("") @JsonKey(name: "remote_name") String remoteName,
          @Default("") @JsonKey(name: "remote_address") String remoteAddress,
          @Default("") String created,
          @Default("") @JsonKey(name: "last_update") String lastUpdate,
          @Default("") @JsonKey(name: "last_error") String lastError,
          @Default("") String interval,
          @Default(false) @JsonKey(name: "sync_on_commit") bool syncOnCommit}) =
      _GitRepoPushMirror;

  factory GitRepoPushMirror.fromJson(Map<String, dynamic> json) =>
      _$GitRepoPushMirrorFromJson(json);
}

@riverpod
class GitMirrors extends _$GitMirrors {
  @override
  Future<List<GitRepoPushMirror>> build(String owner, String repo) async {
    final entity = await ref.watch(gitSettingsProvider.future);
    if (entity.endpoint == null || entity.token == null) return [];
    final resp = await get(Uri.parse(
        "${entity.endpoint}/api/v1/repos/$owner/$repo/push_mirrors?token=${entity.token}"));
    return (jsonDecode(resp.body) as List? ?? [])
        .map((e) => GitRepoPushMirror.fromJson(e))
        .toList(growable: false);
  }

  Future<String> setGitMirrors(
      String owner,
      String repo,
      String remoteAddress,
      String remoteUser,
      String remotePass,
      String interval,
      bool syncOnCommit) async {
    final entity = await ref.watch(gitSettingsProvider.future);
    if (entity.endpoint == null || entity.token == null) return "";
    final url = Uri.parse(
        "${entity.endpoint}/api/v1/repos/$owner/$repo/push_mirrors?token=${entity.token}");
    final resp = await post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "interval": interval,
          "remote_address": remoteAddress,
          "remote_password": remotePass,
          "remote_username": remoteUser,
          "sync_on_commit": syncOnCommit
        }));
    ref.invalidateSelf();
    return resp.body;
  }

  Future<String> gitMirrorSync(String owner, String repo) async {
    final entity = await ref.watch(gitSettingsProvider.future);
    if (entity.endpoint == null || entity.token == null) return "";
    final _ = await post(Uri.parse(
        "${entity.endpoint}/api/v1/repos/$owner/$repo/push_mirrors-sync?token=${entity.token}"));
    return "Sync 请求已提交";
  }

  Future<String> deletePushMirror(
      String owner, String repo, String name) async {
    final entity = await ref.watch(gitSettingsProvider.future);
    if (entity.endpoint == null || entity.token == null) return "";
    final url = Uri.parse(
        "${entity.endpoint}/api/v1/repos/$owner/$repo/push_mirrors/$name?token=${entity.token}");
    final res = await delete(url);
    ref.invalidateSelf();
    return res.body;
  }
}
