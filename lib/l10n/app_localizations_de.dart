// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get updateAvailable =>
      'Update verfügbar. Bitte melden Sie sich mit einem Administratorkonto an, um das Update durchzuführen.';

  @override
  String get criticalUpdateRequired =>
      'Kritisches Update erforderlich. Bitte melden Sie sich mit einem Administratorkonto an und führen Sie das Update durch.';

  @override
  String get inFaceTraining => 'Gesichtstraining läuft';

  @override
  String get pleaseWaitAMoment => 'Bitte warten Sie einen Moment';

  @override
  String get systemNotification => 'Systembenachrichtigung';

  @override
  String get rainRadarNow => 'Jetzt';

  @override
  String get noEvents => 'Keine Ereignisse';

  @override
  String get faceTrainingSearch => 'Gesichtssuche';

  @override
  String get faceTrainingSearchSub =>
      'Bitte bleiben Sie vor dem Spiegel stehen';

  @override
  String get faceTrainingStarted => 'Training gestartet';

  @override
  String get faceTrainingStartedSub =>
      'Gesicht gefunden, bitte warten Sie einen Moment';

  @override
  String get faceTrainingDone => 'Training beendet';

  @override
  String get faceTrainingDoneSub => 'Erfolgreich abgeschlossen';
}
