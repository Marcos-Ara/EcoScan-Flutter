import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../services/firebase_session.dart';
import '../widgets/eco_brand.dart';
import '../widgets/google_sign_in_action.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  String? _message;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FirebaseSession>().prepareGoogleSignIn();
      }
    });
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    setState(() {
      _busy = true;
      _message = null;
      _success = false;
    });
    try {
      await action();
      if (mounted && success != null) {
        setState(() {
          _message = success;
          _success = true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error is AuthFailure
              ? error.toString()
              : 'Não foi possível concluir. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    if (_busy) return;
    if (!_form.currentState!.validate()) return;
    final auth = context.read<FirebaseSession>();
    _run(
      () => _register
          ? auth.register(_name.text, _email.text, _password.text)
          : auth.signIn(_email.text, _password.text),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: EcoBrand(size: 100)),
                  const SizedBox(height: 22),
                  Text(
                    _register ? 'Criar Conta' : 'EcoScan AI',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _register
                        ? 'Comece a usar o EcoScan AI'
                        : 'Entre na sua conta',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 28),
                  if (_register) ...[
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Informe seu nome.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (v) =>
                        v == null ||
                            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(v.trim())
                        ? 'Digite um e-mail válido.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: [
                      _register
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: 'Mostrar senha',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (v) => v == null || v.length < 6
                        ? 'Use pelo menos 6 caracteres.'
                        : null,
                    onFieldSubmitted: (_) {
                      if (!_register) _submit();
                    },
                  ),
                  if (_register) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmation,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar senha',
                      ),
                      validator: (v) => v != _password.text
                          ? 'As senhas não coincidem.'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Text(
                      _busy
                          ? 'Aguarde…'
                          : _register
                          ? 'Criar Conta'
                          : 'Entrar',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _register = !_register;
                            _message = null;
                            _form.currentState?.reset();
                          }),
                    child: Text(
                      _register ? 'Já tenho uma conta' : 'Criar Conta',
                    ),
                  ),
                  if (!_register)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () {
                              if (!_email.text.contains('@')) {
                                setState(
                                  () => _message = 'Digite seu e-mail acima para receber o link.',
                                );
                                return;
                              }
                              _run(
                                () => context
                                    .read<FirebaseSession>()
                                    .resetPassword(_email.text),
                                success: 'Se houver uma conta com esse e-mail, você receberá o link de recuperação.',
                              );
                            },
                      child: const Text('Recuperar Senha'),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('ou'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                  ),
                  Consumer<FirebaseSession>(
                    builder: (context, auth, _) => GoogleSignInAction(
                      busy: _busy,
                      ready: auth.googleReady,
                      onPressed: () => _run(auth.signInGoogle),
                      onCredential: (idToken) =>
                          _run(() => auth.signInGoogleWebToken(idToken)),
                    ),
                  ),
                  Consumer<FirebaseSession>(
                    builder: (context, auth, _) => auth.googleError == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              auth.googleError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.danger),
                            ),
                          ),
                  ),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _success
                              ? AppColors.primary
                              : AppColors.danger,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});
  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _busy = false;
  String? _message;
  Future<void> _action(bool resend) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final auth = context.read<FirebaseSession>();
      if (resend) {
        await auth.sendVerification();
      } else {
        await auth.reload();
      }
      if (mounted) {
        setState(
          () => _message = resend ? 'Novo e-mail de confirmação enviado.' : 'Ainda não identificamos a confirmação. Confira sua caixa de entrada.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EcoBrand(size: 94),
              const SizedBox(height: 24),
              Text(
                'Verifique seu e-mail',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                'Confirme o link enviado para ${context.watch<FirebaseSession>().account?.email ?? ''}.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _busy ? null : () => _action(false),
                child: const Text('Já verifiquei meu e-mail'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : () => _action(true),
                child: const Text('Reenviar e-mail'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : context.read<FirebaseSession>().signOut,
                child: const Text('Sair'),
              ),
              if (_message != null)
                Text(_message!, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    ),
  );
}
