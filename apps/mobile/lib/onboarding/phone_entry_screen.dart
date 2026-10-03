import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/l10n/app_strings.dart';
import '../services/auth_session.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});
  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _phone = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final challenge = await authSession.requestOtp(_phone.text);
      if (mounted) context.push('/otp-verification', extra: challenge);
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              _error =
                  e is AuthFailure
                      ? e.message
                      : 'Unable to request code. Please try again.',
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
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              strings.enterPhoneNumber,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(strings.phoneSubtitle),
            const SizedBox(height: 24),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              enabled: !_busy,
              decoration: InputDecoration(
                prefixText: '+977 ',
                labelText: strings.phoneNumberLabel,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                if (!_busy) _send();
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, semanticsLabel: _error),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _send,
              child: Text(_busy ? 'Requesting code…' : strings.sendCode),
            ),
          ],
        ),
      ),
    );
  }
}
