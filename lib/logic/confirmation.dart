import 'package:medicine_app/data/models.dart';
import 'package:medicine_app/logic/matcher.dart';

enum ConfirmationMethod { autoConfident, userSelected }

/// A medicine whose identity has been established. Medicine-specific details
/// (including dosage) are only built from this type, so an unconfirmed
/// medicine can never reach the details screen.
class ConfirmedMedicine {
  const ConfirmedMedicine._(this.medicine, this.method, this.fromPhoto);

  final Medicine medicine;
  final ConfirmationMethod method;

  /// True when the identity came from text read off a package photo.
  final bool fromPhoto;

  /// Only works for a confident match; throws otherwise.
  factory ConfirmedMedicine.fromMatch(
    MatchResult result, {
    bool fromPhoto = false,
  }) {
    final top = result.top;
    if (result.status != MatchStatus.confident || top == null) {
      throw StateError('Medicine identity is not confirmed.');
    }
    return ConfirmedMedicine._(
      top.medicine,
      ConfirmationMethod.autoConfident,
      fromPhoto,
    );
  }

  /// The user picked this medicine from the list of candidates.
  factory ConfirmedMedicine.userSelected(
    Medicine medicine, {
    bool fromPhoto = false,
  }) =>
      ConfirmedMedicine._(medicine, ConfirmationMethod.userSelected, fromPhoto);
}
