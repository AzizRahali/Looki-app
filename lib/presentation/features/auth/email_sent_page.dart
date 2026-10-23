import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/services/localization_service.dart';
import '../../../logic/blocs/password_reset/password_reset_bloc.dart';
import '../../../logic/blocs/password_reset/password_reset_event.dart';
import '../../../logic/blocs/password_reset/password_reset_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/loomea_ui.dart';

class EmailSentPage extends StatelessWidget {
  const EmailSentPage({super.key});

  Future<void> _openMailApp() async {
    final uri = Uri(scheme: 'mailto');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: LoomeaAppBarLeading(onPressed: () => context.pop()),
      ),
      body: BlocConsumer<PasswordResetBloc, PasswordResetState>(
        listener: (context, state) {
          if (state.status == PasswordResetStatus.loading) {
            // Resending — handled by UI
          } else if (state.status == PasswordResetStatus.emailSent) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(SnackBar(
                content: Text(tr('otp_code_resent')),
                backgroundColor: AppColors.success,
              ));
          } else if (state.status == PasswordResetStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.errorMessage.isNotEmpty
                  ? state.errorMessage
                  : tr('something_went_wrong')),
              backgroundColor: AppColors.error,
            ));
          }
        },
        builder: (context, state) {
          final isLoading = state.status == PasswordResetStatus.loading;
          final hint = state.hint.isNotEmpty ? state.hint : '●●●@●●●.com';

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: LoomeaTokens.screenPaddingH),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        const Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Icon(Icons.mail_outline_rounded,
                              size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          tr('check_inbox'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.025 * 32,
                            height: 1.1,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text.rich(
                          TextSpan(
                            text: '${tr('link_sent_to')} ',
                            style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: AppColors.textSecondary),
                            children: [
                              TextSpan(
                                text: hint,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              TextSpan(text: '. ${tr('link_expires_15min')}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Illustration — inbox envelope card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(LoomeaTokens.radiusCard),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.mark_email_unread_outlined,
                                  size: 30,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                tr('link_sent_to'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hint,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Open Mail App button
                        SizedBox(
                          height: LoomeaTokens.buttonHeight,
                          child: ElevatedButton.icon(
                            onPressed: _openMailApp,
                            icon: const Icon(Icons.open_in_new_rounded,
                                size: 18),
                            label: Text(tr('open_mail_app')),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Resend link
                        SizedBox(
                          height: LoomeaTokens.buttonHeight,
                          child: OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () => context
                                    .read<PasswordResetBloc>()
                                    .add(SendRecoveryEmail(
                                      state.email,
                                    )),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5),
                                  )
                                : Text(tr('nothing_in_inbox')),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Center(
                          child: GestureDetector(
                            onTap: () => context.pop(),
                            child: Text(
                              tr('back_to_sign_in'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
