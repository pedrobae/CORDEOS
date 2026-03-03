import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';
import 'package:flutter/material.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleObscurePassword() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleObscureConfirmPassword() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe o e-mail';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'E-mail inválido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a senha';
    }
    if (value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme a senha';
    }
    if (value != _passwordController.text) {
      return 'As senhas não coincidem';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MyAuthProvider>(
        builder: (context, auth, child) => Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                spacing: 16,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(),
                  Form(
                    key: _formKey,
                    child: Column(
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildEmailField(),
                        _buildPasswordField(),
                        _buildConfirmPasswordField(),
                        _buildStatusIndicators(auth),
                        _buildRegisterButton(auth),
                        _buildLoginLink(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64.0),
      child: Column(
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Image.asset(
              'assets/logos/app_icon_transparent.png',
              width: 120,
              height: 120,
            ),
          ),
          Text(
            AppLocalizations.of(context)!.createNewAccount,
            style: theme.textTheme.headlineSmall,
          ),
          Text(
            AppLocalizations.of(context)!.joinAppDescription,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return LabeledTextField(
      label: AppLocalizations.of(context)!.email,
      controller: _emailController,
      validator: _validateEmail,
    );
  }

  Widget _buildPasswordField() {
    final colorScheme = Theme.of(context).colorScheme;
    return LabeledTextField(
      label: AppLocalizations.of(context)!.password,
      controller: _passwordController,
      obscureText: _obscurePassword,
      validator: _validatePassword,
      prefixIcon: Icon(
        Icons.lock_outline,
        color: colorScheme.primary,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off : Icons.visibility,
          color: colorScheme.primary,
        ),
        tooltip: _obscurePassword
            ? AppLocalizations.of(context)!.showPassword
            : AppLocalizations.of(context)!.hidePassword,
        onPressed: _toggleObscurePassword,
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    final colorScheme = Theme.of(context).colorScheme;
    return LabeledTextField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      label: AppLocalizations.of(context)!.confirmPassword,
      prefixIcon: Icon(
        Icons.lock_outline,
        color: colorScheme.primary,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
          color: colorScheme.primary,
        ),
        tooltip: _obscureConfirmPassword
            ? AppLocalizations.of(context)!.showPassword
            : AppLocalizations.of(context)!.hidePassword,
        onPressed: _toggleObscureConfirmPassword,
      ),
      validator: _validateConfirmPassword,
    );
  }

  Widget _buildStatusIndicators(MyAuthProvider auth) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      spacing: 8,
      children: [
        if (auth.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(),
          ),
        if (auth.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              auth.error!,
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildRegisterButton(MyAuthProvider auth) {
    return FilledTextButton(
      text: AppLocalizations.of(context)!.createPlaceholder(
        AppLocalizations.of(context)!.account,
      ),
      isDark: true,
      icon: Icons.person_add,
      isDisabled: auth.isLoading,
      onPressed: () {
        if (_formKey.currentState?.validate() ?? false) {
          auth.signUpWithEmail(
            _emailController.text,
            _passwordController.text,
          );
        }
      },
    );
  }

  Widget _buildLoginLink() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.alreadyHaveAccount,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/login');
          },
          child: Text(
            AppLocalizations.of(context)!.login,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
