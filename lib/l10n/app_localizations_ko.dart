// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Speech Rehab';

  @override
  String get today => '오늘';

  @override
  String get training => '훈련';

  @override
  String get records => '기록';

  @override
  String get communication => '소통';

  @override
  String get settings => '설정';

  @override
  String get more => '더보기';

  @override
  String get language => '언어';

  @override
  String get languageDescription => '화면, 음성 안내, 연습 콘텐츠와 발음 분석에 사용할 언어를 선택합니다.';

  @override
  String get systemDefault => '시스템 설정';

  @override
  String get korean => '한국어';

  @override
  String get englishUs => 'English (US)';

  @override
  String get languageChangeNotice => '화면, 음성 안내, 연습 콘텐츠와 발음 분석 언어가 함께 변경됩니다.';

  @override
  String get settingsDescription => '훈련 목표와 사용 환경을 관리하세요.';

  @override
  String get resetGoals => '재활 목표 다시 설정';

  @override
  String get resetGoalsDescription => '하루 훈련 횟수와 주요 훈련 목표를 조정합니다.';

  @override
  String get oralTrainingSettings => '구강·호흡 훈련 설정';

  @override
  String get oralTrainingSettingsDescription =>
      '반복 횟수, 재생 속도, 자막과 음성 안내를 설정합니다.';

  @override
  String get microphoneCheck => '마이크 점검';

  @override
  String get microphoneCheckDescription => '훈련 전 입력 장치와 주변 소음을 확인합니다.';

  @override
  String get accessibilityPrinciples => '접근성 원칙';

  @override
  String get accessibilityPrinciplesDescription =>
      '큰 조작 영역, 명확한 글자 안내, 일관된 훈련 버튼을 제공합니다.';
}
