import 'package:appflowy/plugins/document/application/doc_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';

extension DocumentBlocExtension on DocumentBloc {
  bool get isLocalMode {
    final userProfilePB = state.userProfilePB;
    final type = userProfilePB?.authenticator ?? AuthenticatorPB.Local;
    return type == AuthenticatorPB.Local;
  }
}
