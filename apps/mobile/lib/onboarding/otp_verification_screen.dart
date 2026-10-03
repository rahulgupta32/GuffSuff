import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/l10n/app_strings.dart';
import '../services/auth_session.dart';

class OtpVerificationScreen extends StatefulWidget {
  final RegistrationChallenge challenge;
  const OtpVerificationScreen({super.key, required this.challenge});
  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _code = TextEditingController();
  final _pin = TextEditingController();
  late RegistrationChallenge _challenge;
  Timer? _timer;
  bool _busy = false;
  String? _error;
  int get _remaining => _challenge.resendAvailableAt
      .difference(DateTime.now())
      .inSeconds
      .clamp(0, 86400);
  @override
  void initState() {
    super.initState();
    _challenge = widget.challenge;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_challenge.verified) {
        _challenge = await authSession.verifyOtp(_challenge, _code.text);
      }
      final existingAccount = await authSession.login(
        _challenge,
        pin: _pin.text,
      );
      if (mounted) {
        if (existingAccount) {
          context.go('/chats');
        } else {
          context.go('/profile-setup', extra: _challenge);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AuthFailure ? e.message : 'Verification failed.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_remaining > 0) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final replacement = await authSession.requestOtp(_challenge.phoneNumber);
      if (mounted) {
        setState(() {
          _challenge = replacement;
          _code.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = e is AuthFailure ? e.message : 'Unable to resend code.',
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
              strings.verifyOtpTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text('${strings.otpSentTo} ${_challenge.phoneNumber}'),
            const SizedBox(height: 24),
            TextField(
              controller: _code,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofillHints: const [AutofillHints.oneTimeCode],
              decoration: const InputDecoration(
                labelText: 'Verification code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pin,
              enabled: !_busy,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 12,
              decoration: const InputDecoration(
                labelText: 'Registration PIN (if enabled)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) Text(_error!),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _verify,
              child: Text(strings.verifyButton),
            ),
            TextButton(
              onPressed: _busy || _remaining > 0 ? null : _resend,
              child: Text(
                _remaining > 0
                    ? '${strings.resendOtp} ($_remaining s)'
                    : strings.resendOtp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
