import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../l10n/strings.dart';
import '../../models/chat.dart';
import '../settings/settings_screen.dart';
import '../terminal/terminal_screen.dart';
import '../widgets/ambient_background.dart';
import '../widgets/message_bubble.dart';
import 'model_switcher.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Attachment> _pending = [];

  L get l => L(context.read<AppState>().settings.locale);

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (file == null) return;
    final bytes = await File(file.path).readAsBytes();
    final mime = file.path.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
    setState(() => _pending.add(
        Attachment(path: file.path, mime: mime, base64: base64Encode(bytes))));
  }

  void _send() {
    final app = context.read<AppState>();
    final text = _input.text.trim();
    if (text.isEmpty && _pending.isEmpty) return;
    final imgs = List<Attachment>.from(_pending);
    _input.clear();
    setState(() => _pending.clear());
    app.send(text, images: imgs);
    _scrollDown();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final provider = app.activeProvider;
    if (app.messages.isNotEmpty) _scrollDown();

    return Scaffold(
      key: _scaffoldKey,
      drawerEdgeDragWidth: 60,
      drawer: ChatDrawer(l: l),
      body: AmbientBackground(
        intensity: 0.7,
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                l: l,
                onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                providerName: provider?.name ?? '',
                model: app.settings.activeModel,
                onModel: () => showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => ModelSwitcher(l: l),
                ),
                onNewChat: app.clearChat,
                onSettings: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const SettingsScreen())),
              ),
              Expanded(
                child: app.messages.isEmpty
                    ? _Empty(l: l)
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: app.messages.length,
                        itemBuilder: (_, i) => MessageBubble(
                          msg: app.messages[i],
                          l: l,
                          showReasoning: app.settings.showReasoning,
                        ),
                      ),
              ),
              _Composer(
                controller: _input,
                pending: _pending,
                l: l,
                sending: app.sending,
                onSend: _send,
                onStop: app.stopGenerating,
                onImage: provider?.supportsVision == true ? _pickImage : null,
                onRemoveImage: (i) => setState(() => _pending.removeAt(i)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final L l;
  final String providerName, model;
  final VoidCallback onModel, onNewChat, onSettings, onMenu;
  const _TopBar({
    required this.l,
    required this.providerName,
    required this.model,
    required this.onModel,
    required this.onNewChat,
    required this.onSettings,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 12, 10),
      child: Row(
        children: [
          IconButton(
              onPressed: onMenu,
              icon: const Icon(Icons.menu_rounded,
                  color: AppColors.textSecondary, size: 24)),
          Expanded(
            child: GestureDetector(
              onTap: onModel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(providerName,
                      style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(model,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      const Icon(Icons.expand_more_rounded,
                          size: 20, color: AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
              onPressed: onNewChat,
              icon: const Icon(Icons.add_comment_rounded,
                  color: AppColors.textSecondary, size: 22)),
          IconButton(
              onPressed: onSettings,
              icon: const Icon(Icons.settings_rounded,
                  color: AppColors.textSecondary, size: 22)),
        ],
      ),
    );
  }
}

class ChatDrawer extends StatelessWidget {
  final L l;
  const ChatDrawer({super.key, required this.l});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final sessions = app.orderedSessions;
    return Drawer(
      backgroundColor: AppColors.surface,
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
              child: Row(
                children: [
                  Text(l.chats,
                      style: Theme.of(context).textTheme.displaySmall),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      app.newChat();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.edit_square,
                        color: AppColors.violetSoft, size: 22),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.stroke, height: 1),
            Expanded(
              child: sessions.isEmpty || (sessions.length == 1 && sessions.first.messages.isEmpty)
                  ? Center(
                      child: Text(l.noChats,
                          style: Theme.of(context).textTheme.bodyMedium))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: sessions.length,
                      itemBuilder: (_, i) {
                        final s = sessions[i];
                        if (s.messages.isEmpty) return const SizedBox.shrink();
                        final active = s.id == app.currentSession.id;
                        return ListTile(
                          selected: active,
                          selectedTileColor:
                              AppColors.violet.withValues(alpha: 0.1),
                          leading: Icon(Icons.chat_bubble_outline_rounded,
                              size: 20,
                              color: active
                                  ? AppColors.violetSoft
                                  : AppColors.textSecondary),
                          title: Text(
                            s.title.isEmpty ? l.newChat : s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 14.5),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: AppColors.textFaint),
                            onPressed: () {
                              app.deleteSession(s.id);
                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(SnackBar(
                                  backgroundColor: AppColors.surfaceHigh,
                                  content: Text(l.chatDeleted,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary)),
                                  action: SnackBarAction(
                                    label: l.undo,
                                    textColor: AppColors.violetSoft,
                                    onPressed: app.restoreLastDeleted,
                                  ),
                                ));
                            },
                          ),
                          onTap: () {
                            app.openSession(s.id);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
            const Divider(color: AppColors.stroke, height: 1),
            ListTile(
              leading: const Icon(Icons.terminal_rounded,
                  size: 20, color: AppColors.violetSoft),
              title: Text(l.terminal,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14.5)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text('BETA',
                    style: TextStyle(
                        color: AppColors.violetSoft,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TerminalScreen(l: l)));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final L l;
  const _Empty({required this.l});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded,
                  size: 54, color: AppColors.violetSoft)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn()
              .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.05, 1.05),
                  duration: 2000.ms),
          const SizedBox(height: 16),
          Text(l.emptyChat, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final List<Attachment> pending;
  final L l;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final VoidCallback? onImage;
  final ValueChanged<int> onRemoveImage;

  const _Composer({
    required this.controller,
    required this.pending,
    required this.l,
    required this.sending,
    required this.onSend,
    required this.onStop,
    required this.onImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).viewInsets.bottom * 0),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        border: Border(top: BorderSide(color: AppColors.stroke)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pending.isNotEmpty)
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 8, top: 2),
                itemCount: pending.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(base64Decode(pending[i].base64),
                          width: 60, height: 60, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => onRemoveImage(i),
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.black87, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (onImage != null)
                IconButton(
                    onPressed: onImage,
                    icon: const Icon(Icons.add_photo_alternate_rounded,
                        color: AppColors.textSecondary)),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 130),
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: l.message,
                      hintStyle: const TextStyle(color: AppColors.textFaint),
                      filled: true,
                      fillColor: AppColors.surfaceHigh.withValues(alpha: 0.7),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SendButton(sending: sending, onTap: onSend, onStop: onStop),
            ],
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool sending;
  final VoidCallback onTap;
  final VoidCallback onStop;
  const _SendButton(
      {required this.sending, required this.onTap, required this.onStop});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: sending ? onStop : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: AppColors.violetGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: AppColors.violet.withValues(alpha: 0.5), blurRadius: 16)
          ],
        ),
        child: Icon(sending ? Icons.stop_rounded : Icons.arrow_upward_rounded,
            color: Colors.white),
      ),
    );
  }
}
