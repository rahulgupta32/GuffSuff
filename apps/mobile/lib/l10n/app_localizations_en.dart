// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'GuffSuff';

  @override
  String get welcomeTitle => 'Welcome to GuffSuff';

  @override
  String get devBannerNotice => 'Development build — not for production use';

  @override
  String get selectLanguageTitle => 'Select Language';

  @override
  String get englishLanguage => 'English';

  @override
  String get nepaliLanguage => 'नेपाली (Nepali)';

  @override
  String get continueButton => 'Continue';

  @override
  String get phoneInputTitle => 'Enter Phone Number';

  @override
  String get phoneInputSubtitle =>
      'GuffSuff uses your phone number for secure verification.';

  @override
  String get otpVerifyTitle => 'Verify Phone Number';

  @override
  String get otpVerifySubtitle =>
      'Enter 6-digit OTP code sent to your phone number.';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get profileSetupTitle => 'Set Up Profile';

  @override
  String get displayNameLabel => 'Display Name';

  @override
  String get bioLabel => 'Bio';

  @override
  String get usernameSetupTitle => 'Choose Username';

  @override
  String get usernameLabel => 'Username (e.g. rahul_g)';

  @override
  String get usernameHint => '3-20 lowercase letters, numbers, or underscore';

  @override
  String get privacyTitle => 'Privacy Settings';

  @override
  String get linkedDevicesTitle => 'Linked Devices';

  @override
  String get securityEventsTitle => 'Security Events';

  @override
  String get registrationLockTitle => 'Registration Lock PIN';
}
