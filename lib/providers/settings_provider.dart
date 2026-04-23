import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 16.0;
  String _fontStyle = 'Inter'; // Default font style
  String _prayerLanguage = 'Ilocano'; // 'Ilocano' or 'Tagalog'
  int _colorSeedValue = Colors.blueAccent.toARGB32();
  bool _showChords = false;
  bool _showChordShapes = false;
  String _chordInstrument = 'Guitar';
  String _nickname = 'User';
  String _email = '';
  String _userId = '';
  String _district = '';
  String _position = '';
  String _firstName = '';
  String _middleName = '';
  String _surname = '';
  String _area = '';
  String _centerName = '';
  String _centerAddress = '';
  bool _hasAcceptedTerms = false;


  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  String get fontStyle => _fontStyle;
  String get prayerLanguage => _prayerLanguage;
  Color get colorSeed => Color(_colorSeedValue);
  bool get showChords => _showChords;
  bool get showChordShapes => _showChordShapes;
  String get chordInstrument => _chordInstrument;
  String get nickname => _nickname;
  String get email => _email;
  String get userId => _userId;
  String get district => _district;
  String get position => _position;
  String get firstName => _firstName;
  String get middleName => _middleName;
  String get surname => _surname;
  String get area => _area;
  String get centerName => _centerName;
  String get centerAddress => _centerAddress;
  bool get hasAcceptedTerms => _hasAcceptedTerms;

  bool get isProfileSetup =>
      _nickname != 'User' &&
      _email.isNotEmpty &&
      _firstName.isNotEmpty &&
      _surname.isNotEmpty;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    _fontStyle = prefs.getString('fontStyle') ?? 'Inter';
    _prayerLanguage = prefs.getString('prayerLanguage') ?? 'Ilocano';
    _colorSeedValue = prefs.getInt('colorSeed') ?? Colors.blueAccent.toARGB32();
    _showChords = false;
    _showChordShapes = false;
    prefs.setBool('showChords', false);
    prefs.setBool('showChordShapes', false);

    _chordInstrument = prefs.getString('chordInstrument') ?? 'Guitar';
    if (_chordInstrument == 'Piano') {
      _chordInstrument = 'Guitar';
    }
    _nickname = prefs.getString('nickname') ?? 'User';
    _email = prefs.getString('email') ?? '';
    _userId = prefs.getString('userId') ?? '';
    _district = prefs.getString('district') ?? '';
    _position = prefs.getString('position') ?? '';
    _firstName = prefs.getString('firstName') ?? '';
    _middleName = prefs.getString('middleName') ?? '';
    _surname = prefs.getString('surname') ?? '';
    _area = prefs.getString('area') ?? '';
    _centerName = prefs.getString('centerName') ?? '';
    _centerAddress = prefs.getString('centerAddress') ?? '';
    _hasAcceptedTerms = prefs.getBool('hasAcceptedTerms') ?? false;

    if (_userId.isEmpty) {
      const numbers = '0123456789';
      final random = Random();
      _userId =
          'USER${List.generate(9, (index) => numbers[random.nextInt(numbers.length)]).join()}';
      prefs.setString('userId', _userId);
    }

    notifyListeners();
  }

  void toggleDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', value);
  }

  void updateFontSize(double value) async {
    _fontSize = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('fontSize', value);
  }

  void updateFontStyle(String style) async {
    _fontStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('fontStyle', style);
  }

  void updatePrayerLanguage(String language) async {
    _prayerLanguage = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('prayerLanguage', language);
  }

  void updateColorSeed(Color color) async {
    _colorSeedValue = color.toARGB32();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('colorSeed', color.toARGB32());
  }

  void toggleShowChords(bool value) async {
    _showChords = value;
    if (!_showChords) {
      _showChordShapes = false;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('showChords', value);
    if (!_showChords) {
      prefs.setBool('showChordShapes', false);
    }
  }


  void toggleShowChordShapes(bool value) async {
    _showChordShapes = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('showChordShapes', value);
  }

  void updateChordInstrument(String instrument) async {
    _chordInstrument = instrument;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('chordInstrument', instrument);
  }

  void updateProfile(
    String nickname,
    String email,
    String district,
    String position,
    String firstName,
    String middleName,
    String surname,
    String area,
    String centerName,
    String centerAddress,
  ) async {
    _nickname = nickname;
    _email = email;
    _district = district;
    _position = position;
    _firstName = firstName;
    _middleName = middleName;
    _surname = surname;
    _area = area;
    _centerName = centerName;
    _centerAddress = centerAddress;

    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('nickname', nickname);
    prefs.setString('email', email);
    prefs.setString('district', district);
    prefs.setString('position', position);
    prefs.setString('firstName', firstName);
    prefs.setString('middleName', middleName);
    prefs.setString('surname', surname);
    prefs.setString('area', area);
    prefs.setString('centerName', centerName);
    prefs.setString('centerAddress', centerAddress);
  }

  void recoverProfile(
    String userId,
    String nickname,
    String email,
    String district,
    String position,
    String firstName,
    String middleName,
    String surname,
    String area,
    String centerName,
    String centerAddress,
  ) async {
    _userId = userId;
    _nickname = nickname;
    _email = email;
    _district = district;
    _position = position;
    _firstName = firstName;
    _middleName = middleName;
    _surname = surname;
    _area = area;
    _centerName = centerName;
    _centerAddress = centerAddress;

    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('userId', userId);
    prefs.setString('nickname', nickname);
    prefs.setString('email', email);
    prefs.setString('district', district);
    prefs.setString('position', position);
    prefs.setString('firstName', firstName);
    prefs.setString('middleName', middleName);
    prefs.setString('surname', surname);
    prefs.setString('area', area);
    prefs.setString('centerName', centerName);
    prefs.setString('centerAddress', centerAddress);
  }

  void setHasAcceptedTerms(bool value) async {
    _hasAcceptedTerms = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('hasAcceptedTerms', value);
  }
}
