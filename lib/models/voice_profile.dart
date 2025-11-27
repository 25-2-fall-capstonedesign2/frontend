class VoiceProfile {
  final int id;
  final String profileName;
  // 필요한 경우 생성일자 등 추가

  VoiceProfile({required this.id, required this.profileName});

  factory VoiceProfile.fromJson(Map<String, dynamic> json) {
    return VoiceProfile(
      id: json['id'], // 백엔드의 VoiceProfileResponseDto 필드명 확인 필요 (보통 id)
      profileName: json['profileName'],
    );
  }
}