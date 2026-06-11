// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get updateAvailable =>
      'Update available. Please login with an admin account if you want to update.';

  @override
  String get criticalUpdateRequired =>
      'Critical update required. Please login with an admin account and update.';

  @override
  String get inFaceTraining => 'In face training';

  @override
  String get pleaseWaitAMoment => 'Please wait a moment';

  @override
  String get systemNotification => 'System notification';

  @override
  String get rainRadarNow => 'Now';

  @override
  String get noEvents => 'No events';

  @override
  String get faceTrainingSearch => 'Searching for face';

  @override
  String get faceTrainingSearchSub => 'Please stay in front of the mirror';

  @override
  String get faceTrainingStarted => 'Training started';

  @override
  String get faceTrainingStartedSub => 'Face found, please wait a moment';

  @override
  String get faceTrainingDone => 'Training finished';

  @override
  String get faceTrainingDoneSub => 'Finished';

  @override
  String get identifyUser => 'Identify User';
}
