import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/l10n/app_strings.dart';
import '../services/auth_session.dart';

class ProfileSetupScreen extends StatefulWidget {
  final RegistrationChallenge challenge;
  const ProfileSetupScreen({super.key, required this.challenge});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _username = TextEditingController();
  bool _busy = false, _accepted = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await authSession.register(
        widget.challenge,
        _name.text,
        _username.text,
        accepted: _accepted,
      );
      if (mounted) context.go('/chats');
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              _error =
                  e is AuthFailure
                      ? e.message
                      : 'Unable to create account. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                strings.setupProfile,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: strings.displayName,
                  border: const OutlineInputBorder(),
                ),
                validator:
                    (v) =>
                        (v?.trim().length ?? 0) < 2 ||
                                (v?.trim().length ?? 0) > 50
                            ? 'Use 2–50 characters.'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _username,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: strings.username,
                  prefixText: '@',
                  border: const OutlineInputBorder(),
                ),
                validator:
                    (v) =>
                        RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(v?.trim() ?? '')
                            ? null
                            : 'Use 3–20 lowercase letters, numbers or underscores.',
              ),
              CheckboxListTile(
                value: _accepted,
                onChanged:
                    _busy
                        ? null
                        : (v) => setState(() => _accepted = v ?? false),
                title: const Text('I accept the terms and privacy policy.'),
              ),
              if (_error != null) Text(_error!),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _register,
                child: Text(
                  _busy ? 'Creating account…' : strings.completeProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
