import 'dart:math';

import 'package:cyberme_flutter/api/gitea.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'util.dart';

class GiteaView extends ConsumerStatefulWidget {
  const GiteaView({super.key});

  @override
  ConsumerState<GiteaView> createState() => _GiteaViewState();
}

class _GiteaViewState extends ConsumerState<GiteaView>
    with SingleTickerProviderStateMixin {
  final timeColor = const Color.fromARGB(255, 94, 94, 94);
  late var timeStyle = TextStyle(fontSize: 11, color: timeColor);
  late final tabController = TabController(length: 2, vsync: this);
  bool showOpen = true;
  @override
  Widget build(BuildContext context) {
    final setting = ref.watch(gitSettingsProvider).value;
    final issues = ref.watch(GetGitIssuesProvider(showOpen)).value ?? [];
    final repos = ref.watch(getGitReposProvider).value ?? [];

    return Scaffold(
        appBar: AppBar(
            title: const Text("Pocket Gitea"),
            actions: [
              IconButton(
                  onPressed: () => showLoginPopup(setting, context),
                  icon: (setting?.endpoint ?? "").isEmpty
                      ? const Icon(Icons.cloud_off)
                      : const Icon(Icons.cloud)),
              const SizedBox(width: 5)
            ],
            bottom: PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelPadding: const EdgeInsets.only(bottom: 5, top: 5),
                    tabs: [Text("ISSUE(${issues.length})"), const Text("REPO")],
                    controller: tabController))),
        body: Stack(children: [
          AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              width: issues.isEmpty
                  ? MediaQuery.sizeOf(context).width + 180
                  : MediaQuery.sizeOf(context).width + 100,
              curve: Curves.linear,
              bottom: 20,
              child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 600),
                  opacity: issues.isEmpty ? 1 : 0.1,
                  child: Image.asset("images/ship.jpg", fit: BoxFit.cover))),
          TabBarView(controller: tabController, children: [
            buildIssueView(issues, repos),
            buildReposView(repos, setting)
          ])
        ]));
  }

  void showLoginPopup(GitSetting? setting, BuildContext context) {
    {
      final endPoint = TextEditingController(text: setting?.endpoint ?? "");
      final token = TextEditingController(text: setting?.token ?? "");
      final ghToken = TextEditingController(text: setting?.githubToken ?? "");
      String? endpointErr;
      String? tokenErr;
      ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
          content:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 10),
            Text("登录到 Gitea",
                style: Theme.of(context).textTheme.headlineMedium),
            TextField(
                controller: endPoint,
                decoration: InputDecoration(
                    border: const UnderlineInputBorder(),
                    labelText: "Endpoint",
                    errorText: endpointErr)),
            TextField(
                controller: token,
                decoration: InputDecoration(
                    border: const UnderlineInputBorder(),
                    labelText: "Token",
                    errorText: tokenErr)),
            TextField(
                controller: ghToken,
                decoration: const InputDecoration(
                    border: UnderlineInputBorder(), labelText: "Github Token")),
            Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 10),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  OutlinedButton(
                      onPressed: () =>
                          ScaffoldMessenger.of(context).clearMaterialBanners(),
                      child: const Text("取消", textAlign: TextAlign.center)),
                  const SizedBox(width: 10),
                  OutlinedButton(
                      onPressed: () {
                        final ep = endPoint.text.endsWith("/")
                            ? endPoint.text
                                .substring(0, endPoint.text.length - 1)
                            : endPoint.text;
                        ref.read(gitSettingsProvider.notifier).set(GitSetting(
                            token: token.text,
                            endpoint: ep,
                            githubToken: ghToken.text));
                        ScaffoldMessenger.of(context).clearMaterialBanners();
                      },
                      child: const Text("确定", textAlign: TextAlign.center)),
                ]))
          ]),
          actions: const [SizedBox()]));
    }
  }

  Widget buildReposView(List<GitRepoDetail> repos, GitSetting? setting) {
    return Column(children: [
      Expanded(
          child: ListView.builder(
              itemBuilder: (context, index) {
                final i = repos[index];
                return InkWell(
                    onLongPress: () => launchUrlString(i.htmlUrl),
                    onTap: () => showRepoPopup(i),
                    child: Padding(
                        padding: const EdgeInsets.only(
                            bottom: 7, top: 7, left: 10, right: 10),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(i.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1),
                                const Spacer(),
                                Opacity(
                                    opacity: i.openIssuesCount == 0 ? 0 : 1,
                                    child: Container(
                                        padding: const EdgeInsets.only(
                                            left: 10, right: 10),
                                        decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Text("${i.openIssuesCount}",
                                            style: const TextStyle(
                                                color: Colors.white))))
                              ]),
                              Row(children: [
                                i.private
                                    ? const Text("私有")
                                    : const Text("公开",
                                        style: TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                            fontWeight: FontWeight.bold)),
                                const SizedBox(width: 5),
                                i.pushMirrors.isNotEmpty
                                    ? Text(
                                        i.pushMirrors.any((element) =>
                                                element.syncOnCommit)
                                            ? "推送同步"
                                            : "定时同步",
                                        style: const TextStyle(
                                            color: Colors.green))
                                    : i.mirror
                                        ? const Text("镜像",
                                            style: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 26, 76, 185)))
                                        : const Text("无同步",
                                            style: TextStyle(color: Colors.red))
                              ]),
                              const SizedBox(height: 5),
                              Row(children: [
                                Icon(Icons.access_time,
                                    size: 13, color: timeColor),
                                Text(" ${i.updatedAt}", style: timeStyle)
                              ])
                            ])));
              },
              itemCount: repos.length)),
      SafeArea(
          child: ButtonBar(alignment: MainAxisAlignment.center, children: [
        TextButton(
            onPressed: () => launchUrlString(setting?.endpoint ?? ""),
            child: const Text("主页")),
        TextButton(
            onPressed: () async {
              ScaffoldMessenger.of(context)
                  .showMaterialBanner(const MaterialBanner(
                      content: Row(children: [
                        SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text("正在刷新...")
                      ]),
                      actions: [SizedBox()]));
              final _ = await ref.refresh(getGitReposProvider.future);
              ScaffoldMessenger.of(context).clearMaterialBanners();
            },
            child: const Text("刷新"))
      ]))
    ]);
  }

  void showIssuePopup(GitIssue issue) async {
    await showDialog(
        context: context,
        builder: (context) => SimpleDialog(title: Text(issue.title), children: [
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.of(context).pop();
                    launchUrlString(issue.htmlUrl);
                  },
                  child: const Text("在 Web 查看...")),
              SimpleDialogOption(
                  onPressed: () async {
                    final res = await ref.read(deleteGitIssueProvider
                        .call(issue.repository.owner, issue.repository.name,
                            issue.number)
                        .future);
                    await showSimpleMessage(context,
                        content: res.isEmpty ? "删除成功" : res,
                        withPopFirst: true);
                    ref.invalidate(getGitIssuesProvider.call(showOpen));
                  },
                  child: Text("删除",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)))
            ]));
  }

  void showRepoPopup(GitRepoDetail repo) async {
    await showDialog(
        context: context,
        builder: (context) =>
            SimpleDialog(title: Text(repo.fullName), children: [
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.of(context).pop();
                    launchUrlString(repo.htmlUrl);
                  },
                  child: const Text("在 Web 查看...")),
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showModalBottomSheet(
                        context: context,
                        builder: (context) => GiteaRepoSyncView(repo: repo));
                  },
                  child: const Text("查看同步信息"))
            ]));
  }

  Widget buildIssueView(List<GitIssue> issues, List<GitRepoDetail> repos) {
    return Column(children: [
      Expanded(
          child: ListView.builder(
              itemBuilder: (context, index) {
                final i = issues[index];
                return InkWell(
                    onLongPress: () => launchUrlString(i.htmlUrl),
                    onTap: () => showIssuePopup(i),
                    child: Padding(
                        padding: const EdgeInsets.only(
                            bottom: 7, top: 7, left: 10, right: 10),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(i.title,
                                  style: TextStyle(
                                      color:
                                          showOpen ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1),
                              Row(children: [
                                Text(i.user.username),
                                const Text("/"),
                                Text(i.repository.name,
                                    style: const TextStyle())
                              ]),
                              const SizedBox(height: 5),
                              Row(children: [
                                Icon(Icons.more_time,
                                    size: 13, color: timeColor),
                                Text(" ${i.createdAt}", style: timeStyle)
                              ]),
                              Row(children: [
                                Icon(Icons.access_time,
                                    size: 13, color: timeColor),
                                Text(" ${i.updatedAt}", style: timeStyle)
                              ])
                            ])));
              },
              itemCount: issues.length)),
      ButtonBar(alignment: MainAxisAlignment.center, children: [
        TextButton(
            onPressed: () {
              showWaitingBar(context,
                  func: () async => await ref
                      .refresh(getGitIssuesProvider.call(showOpen).future));
            },
            child: const Text("刷新")),
        TextButton(
            onPressed: () {
              var choosedRepo = "";
              final title = TextEditingController();
              final content = TextEditingController();
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                          title: const Text("新建 Issue"),
                          content: SizedBox(
                              width: min(
                                  MediaQuery.sizeOf(context).width / 1.3, 800),
                              child: StatefulBuilder(
                                  builder: (context, setState) => Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            PopupMenuButton(
                                                child: Text(choosedRepo.isEmpty
                                                    ? "点此选择目标仓库"
                                                    : choosedRepo),
                                                onSelected: (e) {},
                                                itemBuilder: (c) => repos
                                                    .map((e) => PopupMenuItem(
                                                        child: Text(e.fullName),
                                                        onTap: () => setState(
                                                            () => choosedRepo =
                                                                e.fullName)))
                                                    .toList(growable: false)),
                                            TextField(
                                                controller: title,
                                                maxLines: 1,
                                                decoration: const InputDecoration(
                                                    border:
                                                        UnderlineInputBorder(),
                                                    labelText: "标题*")),
                                            TextField(
                                                controller: content,
                                                maxLines: null,
                                                decoration: const InputDecoration(
                                                    border:
                                                        UnderlineInputBorder(),
                                                    labelText: "内容"))
                                          ]))),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text("取消")),
                            TextButton(
                                onPressed: () async {
                                  if (title.text.isEmpty ||
                                      choosedRepo.isEmpty) {
                                    await showSimpleMessage(context,
                                        content: "请选择 Repo 并填写标题");
                                    return;
                                  } else {
                                    final cr = choosedRepo.split("/");
                                    final res = await ref.read(
                                        postGitIssueProvider
                                            .call(cr.last, cr.first, title.text,
                                                content.text)
                                            .future);
                                    await showSimpleMessage(context,
                                        content: "结果：$res", withPopFirst: true);
                                    final _ = await ref.refresh(
                                        getGitIssuesProvider
                                            .call(showOpen)
                                            .future);
                                  }
                                },
                                child: const Text("确定"))
                          ]));
            },
            child: const Text("新建 Issue")),
        TextButton(
            onPressed: () => setState(() => showOpen = !showOpen),
            child: Text(!showOpen ? "显示打开" : "显示已关闭"))
      ])
    ]);
  }
}

class GiteaRepoSyncView extends ConsumerStatefulWidget {
  final GitRepoDetail repo;
  const GiteaRepoSyncView({super.key, required this.repo});

  @override
  ConsumerState<GiteaRepoSyncView> createState() => _GiteaRepoSyncViewState();
}

class _GiteaRepoSyncViewState extends ConsumerState<GiteaRepoSyncView> {
  @override
  Widget build(BuildContext context) {
    final mirror = ref
            .watch(gitMirrorsProvider.call(
                widget.repo.owner.username, widget.repo.name))
            .value ??
        [];
    final setting = ref.watch(gitSettingsProvider).value;
    return Scaffold(
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
          child: SingleChildScrollView(
              child: AnimatedOpacity(
                  opacity: mirror.isEmpty ? 0 : 1,
                  duration: const Duration(milliseconds: 400),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Padding(
                              padding: const EdgeInsets.only(
                                  left: 12, right: 12, top: 13),
                              child: Text(widget.repo.fullName,
                                  style: const TextStyle(fontSize: 20)))
                        ]),
                        ...widget.repo.description.isEmpty
                            ? []
                            : [
                                Padding(
                                    padding: const EdgeInsets.only(
                                        left: 12, right: 12),
                                    child: Text(widget.repo.description,
                                        style: const TextStyle(
                                            height: 1.2,
                                            fontSize: 12,
                                            color: Colors.grey))),
                                const SizedBox(height: 8)
                              ],
                        ...mirror.map((e) => buildMirroCard(e, context))
                      ])))),
      Padding(
          padding: const EdgeInsets.all(8.0),
          child: SafeArea(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(
                onPressed: () async => ref.invalidate(gitMirrorsProvider.call(
                    widget.repo.owner.username, widget.repo.name)),
                child: const Text("刷新页面")),
            TextButton(
                onPressed: setting?.githubToken?.isEmpty ?? true
                    ? null
                    : () async {
                        final user = widget.repo.owner.username;
                        final repoName = widget.repo.name;
                        final remotePass = setting?.githubToken ?? "";
                        final remoteAddress =
                            "https://github.com/$user/$repoName.git";
                        final res = await ref
                            .read(gitMirrorsProvider
                                .call(widget.repo.owner.username,
                                    widget.repo.name)
                                .notifier)
                            .setGitMirrors(user, repoName, remoteAddress, user,
                                remotePass, "8h0m0s", true);
                        await showSimpleMessage(context, content: res);
                      },
                child: const Text("新建 Github 同步")),
            TextButton(
                onPressed: () async {
                  final res = await ref
                      .read(gitMirrorsProvider
                          .call(widget.repo.owner.username, widget.repo.name)
                          .notifier)
                      .gitMirrorSync(
                          widget.repo.owner.username, widget.repo.name);
                  await showSimpleMessage(context, content: res);
                },
                child: const Text("所有镜像同步"))
          ])))
    ]));
  }

  ListTile buildMirroCard(GitRepoPushMirror e, BuildContext context) {
    return ListTile(
        onTap: () {
          showDialog(
              context: context,
              builder: (context) => SimpleDialog(
                      title: Text(e.remoteName.toUpperCase(),
                          style: const TextStyle(fontSize: 14)),
                      children: [
                        SimpleDialogOption(
                            child: const Text("删除"),
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await ref
                                  .read(gitMirrorsProvider
                                      .call(widget.repo.owner.username,
                                          widget.repo.name)
                                      .notifier)
                                  .deletePushMirror(widget.repo.owner.username,
                                      widget.repo.name, e.remoteName);
                            })
                      ]));
        },
        title: Row(children: [
          Text(
            e.repoName.toUpperCase(),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 5),
          Text(e.interval, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(e.syncOnCommit ? "推送同步" : "定时同步",
              style: const TextStyle(fontSize: 12, color: Colors.green))
        ]),
        subtitle:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.remoteAddress, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 5),
          Text("更新于${e.lastUpdate}，创建于${e.created}",
              style: const TextStyle(fontSize: 10)),
          e.lastError.isEmpty
              ? const SizedBox()
              : Text(e.lastError,
                  style: const TextStyle(fontSize: 10, color: Colors.red))
        ]));
  }
}
