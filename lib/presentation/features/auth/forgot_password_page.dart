import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/services/localization_service.dart';
import '../../../logic/blocs/password_reset/password_reset_bloc.dart';
import '../../../logic/blocs/password_reset/password_reset_event.dart';
import '../../../logic/blocs/password_reset/password_reset_state.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/loomea_ui.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  static final _emailRegex = RegExp(r'^[\w\.\-\+]+@[\w\-]+\.\w{2,}$');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool get _isValid => _emailRegex.hasMatch(_emailController.text.trim());

  void _submit(BuildContext context) {
    if (!_isValid) return;
    context.read<PasswordResetBloc>().add(
          SendRecoveryEmail(_emailController.text.trim()),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: LoomeaAppBarLeading(onPressed: () => context.pop()),
      ),
      body: BlocListener<PasswordResetBloc, PasswordResetState>(
        listener: (context, state) {
          switch (state.status) {
            case PasswordResetStatus.emailSent:
              context.pushNamed(AppRoute.emailSent.name);
            case PasswordResetStatus.error:
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.errorMessage.isNotEmpty
                    ? state.errorMessage
                    : tr('something_went_wrong')),
                backgroundColor: AppColors.error,
              ));
            default:
              break;
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: LoomeaTokens.screenPaddingH),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Icon(Icons.lock_reset_rounded,
                            size: 40, color: AppColors.primary),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        tr('recover_account'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.025 * 32,
                          height: 1.1,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        tr('enter_email_to_reset'),
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'name@example.com',
                          prefixIcon: Icon(Icons.mail_outline_rounded,
                              size: 20, color: AppColors.textSecondary),
                        ),
                      ),
                      const Spacer(),
                      BlocBuilder<PasswordResetBloc, PasswordResetState>(
                        builder: (context, state) {
                          final isLoading =
                              state.status == PasswordResetStatus.loading;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: LoomeaTokens.buttonHeight,
                                child: ElevatedButton(
                                  onPressed: (_isValid && !isLoading)
                                      ? () => _submit(context)
                                      : null,
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white),
                                        )
                                      : Text(tr('send_me_a_link')),
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
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
