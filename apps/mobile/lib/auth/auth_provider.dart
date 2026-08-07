import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfile {
  final String userId;
  final String phoneNumber;
  final String displayName;
  final String username;
  final String status;
  final String avatarUrl;

  const UserProfile({
    required this.userId,
    required this.phoneNumber,
    required this.displayName,
    required this.username,
    required this.status,
    this.avatarUrl = '',
  });

  UserProfile copyWith({
    String? displayName,
    String? username,
    String? status,
    String? avatarUrl,
  }) {
    return UserProfile(
      userId: userId,
      phoneNumber: phoneNumber,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class AuthState {
  final bool isAuthenticated;
  final bool isOnboardingCompleted;
  final String? phoneNumber;
  final String? challengeId;
  final String? accessToken;
  final String? deviceId;
  final UserProfile? profile;

  const AuthState({
    this.isAuthenticated = false,
    this.isOnboardingCompleted = false,
    this.phoneNumber,
    this.challengeId,
    this.accessToken,
    this.deviceId,
    this.profile,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isOnboardingCompleted,
    String? phoneNumber,
    String? challengeId,
    String? accessToken,
    String? deviceId,
    UserProfile? profile,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      challengeId: challengeId ?? this.challengeId,
      accessToken: accessToken ?? this.accessToken,
      deviceId: deviceId ?? this.deviceId,
      profile: profile ?? this.profile,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  void setPhoneNumber(String phone, String challengeId) {
    state = state.copyWith(phoneNumber: phone, challengeId: challengeId);
  }

  void setVerified({
    required String accessToken,
    required String userId,
    required String deviceId,
  }) {
    state = state.copyWith(
      isAuthenticated: true,
      accessToken: accessToken,
      deviceId: deviceId,
      profile: UserProfile(
        userId: userId,
        phoneNumber: state.phoneNumber ?? '+977 9800000000',
        displayName: 'Nepal User',
        username: 'nepal_user',
        status: 'GuffSuff test user 🇳🇵',
      ),
    );
  }

  void updateProfile({String? displayName, String? username, String? status}) {
    if (state.profile != null) {
      state = state.copyWith(
        isOnboardingCompleted: true,
        profile: state.profile!.copyWith(
          displayName: displayName,
          username: username,
          status: status,
        ),
      );
    }
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
