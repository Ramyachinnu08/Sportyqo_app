import 'package:flutter/material.dart';

import '../api/api_config.dart';
import '../api/mappers.dart';
import '../api/services.dart';

/// Instagram-style comments bottom sheet.
/// Returns the latest comment count when closed.
class CommentsSheet extends StatefulWidget {
  final String postId;
  final void Function(int total)? onCountChanged;
  const CommentsSheet(
      {super.key, required this.postId, this.onCountChanged});

  /// Opens the sheet; [onCountChanged] fires whenever the total changes.
  static Future<void> open(BuildContext context, String postId,
          {void Function(int total)? onCountChanged}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF111111),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20))),
        builder: (sheetCtx) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: CommentsSheet(
              postId: postId, onCountChanged: onCountChanged),
        ),
      );

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _inputCtrl = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _comments = [];
  int _total = 0;
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _sending = false;
  Map<String, dynamic>? _replyTo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await FeedService.comments(widget.postId);
      if (!mounted) return;
      setState(() {
        _comments = (res['items'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        _total = (res['total'] as int?) ?? _comments.length;
        _page = 1;
        _loading = false;
      });
      widget.onCountChanged?.call(_total);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _comments.length >= _total) return;
    setState(() => _loadingMore = true);
    try {
      final res = await FeedService.comments(widget.postId,
          page: _page + 1);
      if (!mounted) return;
      setState(() {
        _comments.addAll((res['items'] as List<dynamic>)
            .cast<Map<String, dynamic>>());
        _total = (res['total'] as int?) ?? _total;
        _page += 1;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final res = await FeedService.addComment(
        postId: widget.postId,
        body: text,
        parentId: _replyTo?['id'] as String?,
      );
      if (!mounted) return;
      setState(() {
        _comments.add(res);
        _total += 1;
        widget.onCountChanged?.call(_total);
        _inputCtrl.clear();
        _replyTo = null;
        _sending = false;
      });
      // jump to the newest comment
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not comment: $e'),
          backgroundColor: Colors.redAccent));
    }
  }

  /// Top-level comments first, replies nested under their parents.
  List<Map<String, dynamic>> get _ordered {
    final tops = _comments
        .where((c) => c['parent_id'] == null)
        .toList();
    final byParent = <String, List<Map<String, dynamic>>>{};
    for (final c in _comments) {
      final p = c['parent_id'] as String?;
      if (p != null) (byParent[p] ??= []).add(c);
    }
    final out = <Map<String, dynamic>>[];
    for (final t in tops) {
      out.add(t);
      out.addAll(byParent[t['id']] ?? const []);
    }
    return out;
  }

  Widget _avatar(Map<String, dynamic> author, double size) {
    final url =
        ApiConfig.resolveMediaUrl(author['avatar_url'] as String?);
    final name = (author['name'] as String?) ?? '';
    final initial = Center(
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w800)));
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
          color: Color(0xFF1E1E3A), shape: BoxShape.circle),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? Image.network(url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => initial)
            : initial,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _ordered;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.72,
      child: Column(children: [
        const SizedBox(height: 10),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Text('Comments ($_total)',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ),
        Container(height: 1, color: Colors.white10),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF7B2FFF)))
              : items.isEmpty
                  ? const Center(
                      child: Text(
                          'No comments yet.\nBe the first to comment!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                              height: 1.5)))
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels >=
                            n.metrics.maxScrollExtent - 80) {
                          _loadMore();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(
                            16, 12, 16, 12),
                        itemCount: items.length +
                            (_loadingMore ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i >= items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(
                                  child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(
                                                  0xFF7B2FFF)))),
                            );
                          }
                          final c = items[i];
                          final author = (c['author']
                                  as Map<String, dynamic>?) ??
                              const {};
                          final isReply =
                              c['parent_id'] != null;
                          return Padding(
                            padding: EdgeInsets.only(
                                left: isReply ? 40 : 0,
                                bottom: 14),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _avatar(author,
                                    isReply ? 28 : 34),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Row(children: [
                                        Flexible(
                                          child: Text(
                                              (author['name']
                                                      as String?) ??
                                                  '',
                                              overflow:
                                                  TextOverflow
                                                      .ellipsis,
                                              style: const TextStyle(
                                                  color: Colors
                                                      .white,
                                                  fontWeight:
                                                      FontWeight
                                                          .w700,
                                                  fontSize:
                                                      13)),
                                        ),
                                        if (author[
                                                'verified'] ==
                                            true) ...[
                                          const SizedBox(
                                              width: 4),
                                          const Icon(
                                              Icons.verified,
                                              color: Color(
                                                  0xFF7B2FFF),
                                              size: 12),
                                        ],
                                        const SizedBox(
                                            width: 8),
                                        Text(
                                            relativeTime(c[
                                                    'created_at']
                                                as String?),
                                            style: const TextStyle(
                                                color: Colors
                                                    .white30,
                                                fontSize:
                                                    11)),
                                      ]),
                                      const SizedBox(
                                          height: 3),
                                      Text(
                                          (c['body']
                                                  as String?) ??
                                              '',
                                          style: const TextStyle(
                                              color: Colors
                                                  .white70,
                                              fontSize: 13,
                                              height: 1.35)),
                                      const SizedBox(
                                          height: 4),
                                      GestureDetector(
                                        onTap: () =>
                                            setState(() =>
                                                _replyTo = c),
                                        child: const Text(
                                            'Reply',
                                            style: TextStyle(
                                                color: Colors
                                                    .white38,
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight
                                                        .w600)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
        if (_replyTo != null)
          Container(
            color: const Color(0xFF1A1A2E),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Row(children: [
              Expanded(
                child: Text(
                    'Replying to ${(_replyTo!['author'] as Map<String, dynamic>?)?['name'] ?? ''}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ),
              GestureDetector(
                onTap: () => setState(() => _replyTo = null),
                child: const Icon(Icons.close,
                    color: Colors.white38, size: 16),
              ),
            ]),
          ),
        Container(height: 1, color: Colors.white10),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14),
                maxLength: 1000,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Add a comment…',
                  hintStyle:
                      const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF1A1A2E),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                    color: Color(0xFF7B2FFF),
                    shape: BoxShape.circle),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                    : const Icon(Icons.send,
                        color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
