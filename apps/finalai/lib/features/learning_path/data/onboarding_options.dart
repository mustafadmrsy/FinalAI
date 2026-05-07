import 'package:flutter/material.dart';

class SubjectItem {
  const SubjectItem(this.name, this.icon, this.color);
  final String name;
  final IconData icon;
  final Color color;
}

class SubjectCategory {
  const SubjectCategory({required this.name, required this.icon, required this.color, required this.subjects});
  final String name;
  final IconData icon;
  final Color color;
  final List<SubjectItem> subjects;
}

class GoalItem {
  const GoalItem(this.label, this.emoji, this.desc);
  final String label;
  final String emoji;
  final String desc;
}

class DurationItem {
  const DurationItem(this.minutes, this.label, this.emoji);
  final int minutes;
  final String label;
  final String emoji;
}

class OnboardingOptions {
  OnboardingOptions._();

  static const categories = <SubjectCategory>[
    SubjectCategory(
      name: 'Matematik',
      icon: Icons.calculate_rounded,
      color: Color(0xFF58CC02),
      subjects: [
        SubjectItem('Temel Matematik', Icons.calculate_rounded, Color(0xFF58CC02)),
        SubjectItem('Cebir', Icons.functions_rounded, Color(0xFF58CC02)),
        SubjectItem('Geometri', Icons.architecture_rounded, Color(0xFF2FB7A4)),
        SubjectItem('Trigonometri', Icons.change_history_rounded, Color(0xFF1CB0F6)),
        SubjectItem('Kalkülüs', Icons.show_chart_rounded, Color(0xFFCE82FF)),
        SubjectItem('İstatistik', Icons.bar_chart_rounded, Color(0xFFFF9600)),
        SubjectItem('Olasılık', Icons.casino_rounded, Color(0xFFFFB24D)),
        SubjectItem('Lineer Cebir', Icons.grid_on_rounded, Color(0xFF1CB0F6)),
      ],
    ),
    SubjectCategory(
      name: 'Yazılım & Teknoloji',
      icon: Icons.terminal_rounded,
      color: Color(0xFF2FB7A4),
      subjects: [
        SubjectItem('Python', Icons.terminal_rounded, Color(0xFF2FB7A4)),
        SubjectItem('JavaScript', Icons.web_rounded, Color(0xFFFFB24D)),
        SubjectItem('Java', Icons.coffee_rounded, Color(0xFFFF9600)),
        SubjectItem('C++', Icons.memory_rounded, Color(0xFF1CB0F6)),
        SubjectItem('Swift', Icons.phone_iphone_rounded, Color(0xFFFF6B6B)),
        SubjectItem('Kotlin', Icons.phone_android_rounded, Color(0xFFCE82FF)),
        SubjectItem('SQL', Icons.storage_rounded, Color(0xFF1CB0F6)),
        SubjectItem('Git & Versiyon Kontrolü', Icons.merge_type_rounded, Color(0xFFFF6B6B)),
        SubjectItem('Linux Temelleri', Icons.terminal_rounded, Color(0xFF2FB7A4)),
        SubjectItem('Veri Yapıları & Algoritmalar', Icons.account_tree_rounded, Color(0xFF58CC02)),
        SubjectItem('Siber Güvenlik', Icons.security_rounded, Color(0xFFFF6B6B)),
        SubjectItem('Makine Öğrenmesi Temelleri', Icons.auto_awesome_rounded, Color(0xFFCE82FF)),
      ],
    ),
    SubjectCategory(
      name: 'Dil Öğrenimi',
      icon: Icons.language_rounded,
      color: Color(0xFF1CB0F6),
      subjects: [
        SubjectItem('İngilizce', Icons.language_rounded, Color(0xFF1CB0F6)),
        SubjectItem('Almanca', Icons.translate_rounded, Color(0xFFFF9600)),
        SubjectItem('Fransızca', Icons.translate_rounded, Color(0xFFFF6FAE)),
        SubjectItem('İspanyolca', Icons.translate_rounded, Color(0xFFFF6B6B)),
        SubjectItem('İtalyanca', Icons.translate_rounded, Color(0xFF58CC02)),
        SubjectItem('Japonca', Icons.translate_rounded, Color(0xFFCE82FF)),
        SubjectItem('Arapça', Icons.translate_rounded, Color(0xFF2FB7A4)),
        SubjectItem('Rusça', Icons.translate_rounded, Color(0xFF1CB0F6)),
        SubjectItem('Çince', Icons.translate_rounded, Color(0xFFFF6B6B)),
        SubjectItem('Korece', Icons.translate_rounded, Color(0xFFFFB24D)),
      ],
    ),
    SubjectCategory(
      name: 'Sınav Hazırlık',
      icon: Icons.school_rounded,
      color: Color(0xFFFF9600),
      subjects: [
        SubjectItem('YKS Matematik', Icons.school_rounded, Color(0xFF58CC02)),
        SubjectItem('YKS Türkçe', Icons.school_rounded, Color(0xFFFF9600)),
        SubjectItem('YKS Fen', Icons.school_rounded, Color(0xFF1CB0F6)),
        SubjectItem('YKS Sosyal', Icons.school_rounded, Color(0xFFCE82FF)),
        SubjectItem('KPSS Genel Kültür', Icons.school_rounded, Color(0xFFFF6FAE)),
        SubjectItem('KPSS Matematik', Icons.school_rounded, Color(0xFF2FB7A4)),
        SubjectItem('DGS', Icons.school_rounded, Color(0xFFFFB24D)),
        SubjectItem('YDS/YÖKDİL', Icons.school_rounded, Color(0xFF1CB0F6)),
        SubjectItem('IELTS', Icons.school_rounded, Color(0xFFFF6B6B)),
        SubjectItem('TOEFL', Icons.school_rounded, Color(0xFF58CC02)),
      ],
    ),
    SubjectCategory(
      name: 'Fen Bilimleri',
      icon: Icons.science_rounded,
      color: Color(0xFFCE82FF),
      subjects: [
        SubjectItem('Fizik', Icons.bolt_rounded, Color(0xFF1CB0F6)),
        SubjectItem('Kimya', Icons.science_rounded, Color(0xFFCE82FF)),
        SubjectItem('Biyoloji', Icons.eco_rounded, Color(0xFF2FB7A4)),
      ],
    ),
    SubjectCategory(
      name: 'Sosyal Bilimler',
      icon: Icons.groups_rounded,
      color: Color(0xFFFF6FAE),
      subjects: [
        SubjectItem('Tarih', Icons.menu_book_rounded, Color(0xFFFF9600)),
        SubjectItem('Coğrafya', Icons.public_rounded, Color(0xFF2FB7A4)),
        SubjectItem('Psikoloji', Icons.psychology_alt_rounded, Color(0xFFFF6FAE)),
        SubjectItem('Sosyoloji', Icons.groups_rounded, Color(0xFFCE82FF)),
        SubjectItem('Felsefe', Icons.lightbulb_rounded, Color(0xFFFFB24D)),
        SubjectItem('Ekonomi', Icons.trending_up_rounded, Color(0xFF58CC02)),
      ],
    ),
    SubjectCategory(
      name: 'İş & Kariyer',
      icon: Icons.business_center_rounded,
      color: Color(0xFFFFB24D),
      subjects: [
        SubjectItem('Proje Yönetimi', Icons.task_alt_rounded, Color(0xFF1CB0F6)),
        SubjectItem('Excel & Google Sheets', Icons.table_chart_rounded, Color(0xFF58CC02)),
        SubjectItem('İş İngilizcesi', Icons.business_center_rounded, Color(0xFFFF9600)),
        SubjectItem('Girişimcilik Temelleri', Icons.rocket_launch_rounded, Color(0xFFFF6B6B)),
        SubjectItem('Pazarlama Temelleri', Icons.campaign_rounded, Color(0xFFFFB24D)),
        SubjectItem('Muhasebe Temelleri', Icons.receipt_long_rounded, Color(0xFF2FB7A4)),
        SubjectItem('Finans Okuryazarlığı', Icons.account_balance_rounded, Color(0xFF58CC02)),
      ],
    ),
    SubjectCategory(
      name: 'Sanat & Tasarım',
      icon: Icons.palette_rounded,
      color: Color(0xFFFF6B6B),
      subjects: [
        SubjectItem('Grafik Tasarım Temelleri', Icons.palette_rounded, Color(0xFFCE82FF)),
        SubjectItem('Fotoğrafçılık', Icons.camera_alt_rounded, Color(0xFFFF6FAE)),
        SubjectItem('Müzik Teorisi', Icons.music_note_rounded, Color(0xFFFFB24D)),
        SubjectItem('UI/UX Temelleri', Icons.brush_rounded, Color(0xFF1CB0F6)),
      ],
    ),
  ];

  // Flat list for backward compat (search etc.)
  static List<SubjectItem> get subjects => categories.expand((c) => c.subjects).toList();

  static const goals = <GoalItem>[
    GoalItem('Temelden öğrenmek', '🌱', 'Sıfırdan başlayıp adım adım ilerle'),
    GoalItem('Sınav hazırlığı', '🎯', 'Hedefli ve yoğun çalışma planı'),
    GoalItem('İş / kariyer', '💼', 'Kariyerine yön verecek bilgiler'),
    GoalItem('Hobi / merak', '✨', 'Eğlenceli ve rahat tempoda öğren'),
  ];

  static const durations = <DurationItem>[
    DurationItem(5, '5 dk / gün', '🐢'),
    DurationItem(10, '10 dk / gün', '🚶'),
    DurationItem(15, '15 dk / gün', '🏃'),
    DurationItem(30, '30 dk / gün', '🔥'),
  ];
}
