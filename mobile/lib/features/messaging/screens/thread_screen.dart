import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/messages_provider.dart';
import '../widgets/message_bubble.dart';

class ThreadScreen extends ConsumerStatefulWidget {
  const ThreadScreen({super.key, required this.threadId});
  final int threadId;

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  bool _didInitialScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      if (!mounted) return;
      ref.read(messagesProvider(widget.threadId).notifier)
        ..markRead()
        ..startPolling();
    });
  }

  @override
  void dispose() {
    ref.read(messagesProvider(widget.threadId).notifier).stopPolling();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = false}) {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (animate) {
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(max);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <= 80) {
      ref
          .read(messagesProvider(widget.threadId).notifier)
          .loadOlderMessages();
    }
  }

  Future<void> _send() async {
    final body = _textController.text.trim();
    if (body.isEmpty) return;
    _textController.clear();
    await ref
        .read(messagesProvider(widget.threadId).notifier)
        .sendMessage(body);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom(animate: true));
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.threadId));
    final detail = ref.watch(threadDetailProvider(widget.threadId));
    final currentUser = ref.watch(currentUserProvider);

    // Scroll to bottom once on first data load.
    ref.listen(messagesProvider(widget.threadId), (_, next) {
      if (!_didInitialScroll && next.valueOrNull != null) {
        _didInitialScroll = true;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    final title =
        detail.valueOrNull?.offerTitle ?? 'Conversation';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(messagesAsync, currentUser?.id)),
          _Composer(
            controller: _textController,
            onSend: _send,
            isSending: messagesAsync.valueOrNull?.isSending ?? false,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    AsyncValue<MessagesState> async,
    int? currentUserId,
  ) {
    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator.adaptive()),
      error: (_, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            const Text('Could not load messages'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ref
                  .read(messagesProvider(widget.threadId).notifier)
                  .loadInitial(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (state) {
        final msgs = state.messages;
        // Extra items at the top: loading spinner or "Load older" button.
        final topItems = state.isLoadingOlder
            ? 1
            : (state.nextOlderPage != null ? 1 : 0);

        if (msgs.isEmpty && !state.isLoadingOlder) {
          return const _EmptyThread();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          itemCount: msgs.length + topItems,
          itemBuilder: (context, index) {
            // Top item: spinner or "load older" button.
            if (topItems > 0 && index == 0) {
              if (state.isLoadingOlder) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2),
                    ),
                  ),
                );
              }
              return TextButton.icon(
                onPressed: () => ref
                    .read(messagesProvider(widget.threadId).notifier)
                    .loadOlderMessages(),
                icon: const Icon(Icons.expand_less, size: 16),
                label: const Text('Load older messages'),
              );
            }

            final msgIndex = index - topItems;
            final msg = msgs[msgIndex];
            final isOwn = msg.sender.id == currentUserId;
            // Show sender name on the first bubble of a consecutive run.
            final showName = !isOwn &&
                (msgIndex == 0 ||
                    msgs[msgIndex - 1].sender.id != msg.sender.id);

            return MessageBubble(
              message: msg,
              isOwn: isOwn,
              showSenderName: showName,
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Composer bar
// ---------------------------------------------------------------------------

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.isSending,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: 8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write a message…',
                filled: true,
                fillColor: cs.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          isSending
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
              : IconButton.filled(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: onSend,
                ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty thread state
// ---------------------------------------------------------------------------

class _EmptyThread extends StatelessWidget {
  const _EmptyThread();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_outlined,
                    size: 48, color: cs.onSurface.withValues(alpha: 0.25)),
                const SizedBox(height: 12),
                Text(
                  'No messages yet.\nSend the first one!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
