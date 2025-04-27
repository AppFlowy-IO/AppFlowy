// import 'package:appflowy/generated/locale_keys.g.dart';
// import 'package:appflowy_ui/appflowy_ui.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flowy_infra_ui/flowy_infra_ui.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class PasswordBottomSheet extends StatefulWidget {
//   const PasswordBottomSheet(
//     this.context, {
//     required this.onSubmitted,
//     super.key,
//   });

//   final BuildContext context;
//   final void Function(String) onSubmitted;

//   @override
//   State<PasswordBottomSheet> createState() => _PasswordBottomSheetState();
// }

// class _PasswordBottomSheetState extends State<PasswordBottomSheet> {
//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: <Widget>[
//         Form(
//           key: _formKey,
//           child: TextFormField(
//             controller: _textFieldController,
//             keyboardType: TextInputType.text,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return LocaleKeys.settings_mobile_usernameEmptyError.tr();
//               }
//               return null;
//             },
//             onEditingComplete: submitUserName,
//           ),
//         ),
//         const VSpace(16),
//         AFFilledTextButton.primary(
//           text: LocaleKeys.button_update.tr(),
//           onTap: submitUserName,
//           size: AFButtonSize.l,
//           alignment: Alignment.center,
//         ),
//       ],
//     );
//   }
// }
