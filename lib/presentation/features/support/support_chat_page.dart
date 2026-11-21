import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/repositories/loomea_repository.dart';
import '../../../data/services/localization_service.dart';
import '../../../logic/blocs/support/support_cubit.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/loomea_ui.dart';

const _supportEmail = 'support@loomea.app';

/// AI support assistant that answers from Looki's help articles.
class SupportChatPage extends StatelessWidget {
  const SupportChatPage({super.key, this.isOwner = false});

  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SupportCubit(
        repository: context.read<LoomeeaRepository>(),
        language: () => AppLocalizations.instance.locale,
      ),
      child: _SupportChatView(isOwner: isOwner),
    );
  }
}

class _SupportChatView extends StatefulWidget {
  const _SupportChatView({required this.isOwner});

  final bool isOwner;

  @override
  State<_SupportChatView> createState() => _SupportChatViewState();
}

class _SupportChatViewState extends State<_SupportChatView> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  List<String> get _suggestions => widget.isOwner
      ? [
          tr('support_q_owner_confirm'),
          tr('support_q_owner_service'),
          tr('support_q_owner_no_show'),
        ]
      : [
          tr('support_q_cancel'),
          tr('support_q_reliability'),
          tr('support_q_cant_book'),
        ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final message = text ?? _controller.text;
    if (message.trim().isEmpty) return;
    _controller.clear();
    context.read<SupportCubit>().send(message);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  static Future<void> _emailSupport() async {
    await launchUrl(Uri(scheme: 'mailto', path: _supportEmail));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: LoomeaAppBarLeading(onPressed: () => context.pop()),
        title: Text(
          tr('support_title'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: tr('support_email'),
            icon: const Icon(Icons.mail_outline_rounded,
                color: AppColors.textPrimary),
            onPressed: _emailSupport,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocConsumer<SupportCubit, SupportState>(
          listener: (_, __) => _scrollToEnd(),
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(
                        LoomeaTokens.screenPaddingH, 12,
                        LoomeaTokens.screenPaddingH, 12),
                    children: [
                      _Bubble(text: tr('support_intro'), fromUser: false),
                      if (state.entries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final q in _suggestions)
                                ActionChip(
                                  label: Text(q,
                                      style: const TextStyle(fontSize: 13)),
                                  backgroundColor: AppColors.surface,
                                  side: const BorderSide(
                                      color: AppColors.border),
                                  onPressed: () => _send(q),
                                ),
                            ],
                          ),
                        ),
                      for (final entry in state.entries) _entry(entry),
                      if (state.sending) const _ThinkingBubble(),
                    ],
                  ),
                ),
                _Composer(
                  controller: _controller,
                  enabled: !state.sending,
                  onSend: _send,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _entry(SupportEntry entry) {
    switch (entry.kind) {
      case SupportEntryKind.user:
        return _Bubble(text: entry.text!, fromUser: true);
      case SupportEntryKind.answer:
        return _Bubble(text: entry.text!, fromUser: false);
      case SupportEntryKind.noAnswer:
        return _Bubble(
          text: tr('support_no_answer', args: [_supportEmail]),
          fromUser: false,
          action: TextButton(
              onPressed: _emailSupport, child: Text(tr('support_email'))),
        );
      case SupportEntryKind.unavailable:
      case SupportEntryKind.error:
        return _Bubble(
          text: tr('support_unavailable', args: [_supportEmail]),
          fromUser: false,
          action: TextButton(
              onPressed: _emailSupport, child: Text(tr('support_email'))),
        );
      case SupportEntryKind.rateLimited:
        return _Bubble(text: tr('support_rate_limited'), fromUser: false);
    }
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.fromUser, this.action});

  final String text;
  final bool fromUser;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          fromUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: fromUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: fromUser ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: fromUser ? AppColors.onPrimary : AppColors.textPrimary,
              ),
            ),
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(tr('support_thinking'),
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final void Function([String? text]) onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          LoomeaTokens.screenPaddingH, 8, LoomeaTokens.screenPaddingH, 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  maxLength: SupportCubit.maxMessageLength,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: tr('support_hint'),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: tr('support_send'),
                onPressed: enabled ? () => onSend() : null,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tr('support_disclaimer'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
