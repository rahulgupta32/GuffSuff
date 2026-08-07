import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

class AppStrings {
  final Locale locale;
  AppStrings(this.locale);

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppStrings(locale);
  }

  bool get isNepali => locale.languageCode == 'ne';

  String get appName => 'GuffSuff';
  String get tagLine =>
      isNepali
          ? 'नेपालको आफ्नै सुरक्षित म्यासेजिङ एप'
          : 'Nepal-First Secure Messaging';

  // Onboarding
  String get welcomeTitle =>
      isNepali ? 'GuffSuff मा स्वागत छ' : 'Welcome to GuffSuff';
  String get welcomeSubTitle =>
      isNepali
          ? 'नेपाल-केन्द्रित सञ्चार प्रणाली।'
          : 'Nepal-first messaging platform.';
  String get privacyPolicyNotice =>
      isNepali
          ? 'GuffSuff गोपनीयता-केन्द्रित आर्किटेक्चरको साथ निर्माण गरिँदैछ। यो आन्तरिक बिल्डमा सुरक्षित सन्देश उपलब्ध छैन।'
          : 'GuffSuff is being built with a privacy-first architecture. Secure messaging is not available in this internal build.';

  String get getStarted => isNepali ? 'शुरु गर्नुहोस्' : 'Get Started';
  String get continueButton => isNepali ? 'आगे बढ्नुहोस्' : 'Continue';

  // Phone Entry
  String get enterPhoneNumber =>
      isNepali ? 'फोन नम्बर राख्नुहोस्' : 'Enter Phone Number';
  String get phoneSubtitle =>
      isNepali
          ? 'GuffSuff ले प्रमाणीकरणको लागि तपाईंको नम्बर प्रयोग गर्छ।'
          : 'GuffSuff uses your phone number for secure verification.';
  String get selectCountry => isNepali ? 'देश छान्नुहोस्' : 'Select Country';
  String get phoneNumberLabel => isNepali ? 'फोन नम्बर' : 'Phone Number';
  String get sendCode =>
      isNepali ? 'ओटीपी पठाउनुहोस्' : 'Send Verification Code';

  // OTP
  String get verifyOtpTitle =>
      isNepali ? 'नम्बर प्रमाणीकरण' : 'Verify Phone Number';
  String get otpSentTo => isNepali ? 'कोड पठाइएको नम्बर:' : 'Code sent to';
  String get devOtpNotice =>
      isNepali
          ? 'विकास मोड: परीक्षण कोड १२३४५६ हो'
          : 'DEVELOPMENT OTP MODE — Use code: 123456';
  String get resendIn => isNepali ? 'पुनः पठाउनुहोस्' : 'Resend code in';
  String get resendOtp => isNepali ? 'कोड पुनः पठाउनुहोस्' : 'Resend OTP';
  String get verifyButton =>
      isNepali ? 'प्रमाणित गर्नुहोस्' : 'Verify & Continue';

  // Profile Setup
  String get setupProfile =>
      isNepali ? 'प्रोफाइल तयार गर्नुहोस्' : 'Set Up Your Profile';
  String get displayName => isNepali ? 'प्रदर्शन नाम' : 'Display Name';
  String get bioStatus => isNepali ? 'स्ट्याटस / बायो' : 'Status / Bio';
  String get username => isNepali ? 'प्रयोगकर्ता नाम' : 'Username';
  String get completeProfile =>
      isNepali ? 'सम्पन्न गर्नुहोस्' : 'Complete Setup';

  // Navigation
  String get tabChats => isNepali ? 'गफफफ (Chats)' : 'Chats';
  String get tabPeople => isNepali ? 'मानिसहरू (People)' : 'People';
  String get tabUpdates => isNepali ? 'अपडेट्स' : 'Updates';
  String get tabSettings => isNepali ? 'सेटिङहरू' : 'Settings';

  // Disabled messaging banner
  String get providerUnavailableTitle =>
      isNepali
          ? 'सुरक्षित म्यासेजिङ उपलब्ध छैन'
          : 'Secure messaging is not available in this build.';
  String get providerUnavailableDetail =>
      isNepali
          ? 'यो आन्तरिक डेमोग्राफिक बिल्ड हो। उत्पादन cryptographic provider स्वीकृत नभएसम्म वास्तविक सन्देश पठाउन पाइने छैन।'
          : 'This is an internal demo build. Real message transmission is disabled until an approved production cryptographic provider is integrated.';
  String get demoDataNotice =>
      isNepali
          ? 'डेमो डेटा मोड: यो देखाउनको लागि मात्र हो।'
          : 'INTERNAL DEMO DATA MODE';

  // Settings
  String get accountSettings => isNepali ? 'खाता' : 'Account';
  String get privacySettings => isNepali ? 'गोपनीयता' : 'Privacy';
  String get devicesSettings => isNepali ? 'यन्त्रहरू' : 'Linked Devices';
  String get appearanceSettings => isNepali ? 'रंग / डिजाइन' : 'Appearance';
  String get languageSettings => isNepali ? 'भाषा' : 'Language';
  String get diagnosticsSettings =>
      isNepali ? 'प्रणाली स्थिति (Diagnostics)' : 'Internal Diagnostics';
  String get internalFeedback =>
      isNepali ? 'आन्तरिक प्रतिक्रिया' : 'Internal Feedback';
  String get buildInfo => isNepali ? 'बिल्ड जानकारी' : 'Build Information';
  String get logout => isNepali ? 'लगआउट' : 'Log Out';
}
