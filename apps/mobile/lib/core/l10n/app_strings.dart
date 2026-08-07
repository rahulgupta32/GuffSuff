import 'package:flutter/material.dart';

class AppStrings {
  final Locale locale;

  AppStrings(this.locale);

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings) ??
        AppStrings(const Locale('en'));
  }

  bool get isNepali => locale.languageCode == 'ne';

  // App Title
  String get appTitle => 'GuffSuff';
  String get appTagline =>
      isNepali ? 'नेपालको लागि आधुनिक मेसेजिङ' : 'Nepal-First Messaging';

  // Privacy Explanation
  String get privacyExplainTitle =>
      isNepali ? 'गोपनीयता र सुरक्षा' : 'Privacy & Security';
  String get privacyExplainBody =>
      isNepali
          ? 'GuffSuff तपाईंको गोपनीयतालाई प्राथमिकता दिँदै निर्माण भइरहेको छ। हाल यो प्रिमियम मोबाइल अनुभवको रूपमा उपलब्ध छ।'
          : 'GuffSuff is built with privacy at its core. Secure messaging features are currently in development.';

  String get getStarted => isNepali ? 'शुरु गर्नुहोस्' : 'Get Started';
  String get continueButton => isNepali ? 'अगाडि बढ्नुहोस्' : 'Continue';

  // Phone Entry
  String get enterPhoneNumber =>
      isNepali ? 'फोन नम्बर राख्नुहोस्' : 'Enter Phone Number';
  String get phoneSubtitle =>
      isNepali
          ? 'GuffSuff ले प्रमाणीकरणको लागि तपाईंको फोन नम्बर प्रयोग गर्छ।'
          : 'GuffSuff uses your phone number for simple, secure verification.';
  String get selectCountry => isNepali ? 'देश छान्नुहोस्' : 'Select Country';
  String get phoneNumberLabel => isNepali ? 'फोन नम्बर' : 'Phone Number';
  String get sendCode =>
      isNepali ? 'ओटीपी कोड पठाउनुहोस्' : 'Send Verification Code';

  // OTP Verification
  String get verifyOtpTitle =>
      isNepali ? 'नम्बर प्रमाणीकरण' : 'Verify Phone Number';
  String get otpSentTo => isNepali ? 'कोड पठाइएको नम्बर:' : 'Code sent to';
  String get devOtpNotice =>
      isNepali
          ? 'विकास मोड: परीक्षण कोड १२३४५६ हो'
          : 'DEVELOPMENT MODE — Code: 123456';
  String get resendIn => isNepali ? 'पुनः पठाउनुहोस्' : 'Resend code in';
  String get resendOtp => isNepali ? 'कोड पुनः पठाउनुहोस्' : 'Resend OTP';
  String get verifyButton =>
      isNepali ? 'प्रमाणित गर्नुहोस्' : 'Verify & Continue';

  // Profile Setup
  String get setupProfile =>
      isNepali ? 'प्रोफाइल तयार गर्नुहोस्' : 'Set Up Profile';
  String get displayName => isNepali ? 'प्रदर्शन नाम' : 'Display Name';
  String get bioStatus => isNepali ? 'बायो / स्ट्याटस' : 'Status / Bio';
  String get username => isNepali ? 'प्रयोगकर्ता नाम' : 'Username';
  String get completeProfile =>
      isNepali ? 'सम्पन्न गर्नुहोस्' : 'Complete Setup';

  // Navigation (3-tab IA: Chats, People, Settings)
  String get tabChats => isNepali ? 'गफगाफ' : 'Chats';
  String get tabPeople => isNepali ? 'सम्पर्क' : 'People';
  String get tabSettings => isNepali ? 'सेटिङहरू' : 'Settings';

  // Status Banner / Notice
  String get providerUnavailableTitle =>
      isNepali
          ? 'सुरक्षित मेसेजिङ सुविधा हाल उपलब्ध छैन।'
          : 'Secure messaging isn\'t available yet.';

  // Chats Screen
  String get searchPlaceholder => isNepali ? 'खोज्नुहोस्...' : 'Search...';
  String get noConversationsTitle =>
      isNepali ? 'कुनै गफगाफ भेटिएन' : 'No conversations yet';
  String get noConversationsSub =>
      isNepali
          ? 'तपाईंले सुरु गर्नुभएका कुराकानीहरू यहाँ देखिनेछन्।'
          : 'People you chat with will appear here.';
  String get startChatAction =>
      isNepali ? 'कुराकानी सुरु गर्नुहोस्' : 'Start a Chat';

  // People Screen
  String get findPeoplePrompt =>
      isNepali
          ? 'GuffSuff मा साथीहरू खोज्नुहोस्'
          : 'Find people you know on GuffSuff.';
  String get contactsPermissionSub =>
      isNepali
          ? 'तपाईंका साथीहरू GuffSuff मा छन् कि छैनन् भनेर हेर्न सम्पर्क अनुमति दिनुहोस्।'
          : 'Allow contacts access to discover friends already using GuffSuff.';
  String get contactsOnGuffSuff =>
      isNepali ? 'GuffSuff मा भएका सम्पर्कहरू' : 'Contacts on GuffSuff';
  String get inviteToGuffSuff =>
      isNepali ? 'GuffSuff मा निमन्त्रणा गर्नुहोस्' : 'Invite to GuffSuff';
  String get newGroup => isNepali ? 'नयाँ समूह' : 'New Group';
  String get newContact => isNepali ? 'नयाँ सम्पर्क' : 'New Contact';

  // Settings Screen
  String get accountSettings => isNepali ? 'खाता' : 'Account';
  String get privacySettings =>
      isNepali ? 'गोपनीयता र सुरक्षा' : 'Privacy & Safety';
  String get chatsSettings => isNepali ? 'गफगाफ सेटिङ' : 'Chats';
  String get notificationsSettings =>
      isNepali ? 'सूचनाहरू (Notifications)' : 'Notifications';
  String get appearanceSettings =>
      isNepali ? 'स्वरुप (Appearance)' : 'Appearance';
  String get storageSettings => isNepali ? 'डाटा र भण्डारण' : 'Storage & Data';
  String get devicesSettings =>
      isNepali ? 'जोडिएका उपकरणहरू' : 'Linked Devices';
  String get languageSettings => isNepali ? 'भाषा (Language)' : 'Language';
  String get helpSettings => isNepali ? 'सहयोग (Help)' : 'Help';
  String get buildInfo => isNepali ? 'GuffSuff बारे' : 'About GuffSuff';
  String get diagnosticsSettings =>
      isNepali ? 'आन्तरिक डायग्नोस्टिक्स' : 'Developer Diagnostics';
  String get internalFeedback =>
      isNepali ? 'आन्तरिक प्रतिक्रिया' : 'Internal Feedback';
  String get logout => isNepali ? 'लगआउट' : 'Log Out';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ne'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async {
    return AppStrings(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
