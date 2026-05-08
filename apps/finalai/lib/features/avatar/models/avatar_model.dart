// ═══════════════════════════════════════════════════════════════
//  AVATAR MODEL — 2D character customization data
// ═══════════════════════════════════════════════════════════════

class AvatarModel {
  const AvatarModel({
    this.gender = AvatarGender.male,
    this.skinTone = 0,
    this.hairStyle = 0,
    this.hairColor = 0,
    this.eyeStyle = 0,
    this.eyebrowStyle = 0,
    this.mouthStyle = 0,
    this.accessory = -1,
    this.outfit = 0,
    this.outfitColor = 0,
    this.bgColor = 0,
  });

  final AvatarGender gender;
  final int skinTone;
  final int hairStyle;
  final int hairColor;
  final int eyeStyle;
  final int eyebrowStyle;
  final int mouthStyle;
  final int accessory;
  final int outfit;
  final int outfitColor;
  final int bgColor;

  AvatarModel copyWith({
    AvatarGender? gender,
    int? skinTone,
    int? hairStyle,
    int? hairColor,
    int? eyeStyle,
    int? eyebrowStyle,
    int? mouthStyle,
    int? accessory,
    int? outfit,
    int? outfitColor,
    int? bgColor,
  }) {
    return AvatarModel(
      gender: gender ?? this.gender,
      skinTone: skinTone ?? this.skinTone,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      eyeStyle: eyeStyle ?? this.eyeStyle,
      eyebrowStyle: eyebrowStyle ?? this.eyebrowStyle,
      mouthStyle: mouthStyle ?? this.mouthStyle,
      accessory: accessory ?? this.accessory,
      outfit: outfit ?? this.outfit,
      outfitColor: outfitColor ?? this.outfitColor,
      bgColor: bgColor ?? this.bgColor,
    );
  }

  Map<String, dynamic> toJson() => {
    'gender': gender.index,
    'skinTone': skinTone,
    'hairStyle': hairStyle,
    'hairColor': hairColor,
    'eyeStyle': eyeStyle,
    'eyebrowStyle': eyebrowStyle,
    'mouthStyle': mouthStyle,
    'accessory': accessory,
    'outfit': outfit,
    'outfitColor': outfitColor,
    'bgColor': bgColor,
  };

  factory AvatarModel.fromJson(Map<String, dynamic> json) {
    return AvatarModel(
      gender: AvatarGender.values[(json['gender'] as int?) ?? 0],
      skinTone: (json['skinTone'] as int?) ?? 0,
      hairStyle: (json['hairStyle'] as int?) ?? 0,
      hairColor: (json['hairColor'] as int?) ?? 0,
      eyeStyle: (json['eyeStyle'] as int?) ?? 0,
      eyebrowStyle: (json['eyebrowStyle'] as int?) ?? 0,
      mouthStyle: (json['mouthStyle'] as int?) ?? 0,
      accessory: (json['accessory'] as int?) ?? -1,
      outfit: (json['outfit'] as int?) ?? 0,
      outfitColor: (json['outfitColor'] as int?) ?? 0,
      bgColor: (json['bgColor'] as int?) ?? 0,
    );
  }
}

enum AvatarGender { male, female }
