// ignore_for_file: non_constant_identifier_names

class _Strings {
  static _Strings instance = _Strings();

  String TITLE_CONTACTS_PAGE = "Contacts";
  String TITLE_WHATS_HAPPENING = "What's happening this week?";
  String TITLE_ADD_CONTACT = "Add Contact";
  String TITLE_EDIT_CONTACT = "Edit Contact";

  String BTN_OK = "Ok";
  String BTN_CANCEL = "Cancel";
  String BTN_SIGN_IN = "Sign In";
  String BTN_SIGN_OUT = "Sign Out";
  String BTN_COMPLETE = "Complete";
  String BTN_SAVE = "Save";

  String LBL_WELCOME = "Welcome!";
  String LBL_NAME_FIRST = "First Name";
  String LBL_NAME_MIDDLE = "Middle Name";
  String LBL_NAME_LAST = "Last Name";
  String LBL_STEP_X = "Step {0}";

  String ERR_DEVICE_OAUTH_FAILED_TITLE = "Unable to connect to your account.";
  String ERR_DEVICE_OAUTH_FAILED_MSG =
      "Please make sure you've completed the sign-in process in your browser.";

  String GOOGLE_OAUTH_TITLE = "GOOGLE SIGN-IN";
  String GOOGLE_OAUTH_INSTRUCTIONS_1 =
      "In order to import your Google Contacts, you'll need to authorize this application using your web browser.";
  String GOOGLE_OAUTH_INSTRUCTIONS_2 =
      "Copy this code to your clipboard by clicking the icon or selecting the text:";
  String GOOGLE_OAUTH_INSTRUCTIONS_3 =
      "Navigate to the following link in your web browser, and enter the above code:";
  String GOOGLE_OAUTH_INSTRUCTIONS_4 =
      "Press the button below when you've completed signup:";
}

_Strings get S => _Strings.instance;

extension AddSupplant on String {
  String sup(
      [dynamic v0,
      dynamic v1,
      dynamic v2,
      dynamic v3,
      dynamic v4,
      dynamic v5,
      dynamic v6]) {
    var _s = this;
    if (v0 != null) _s = _s.replaceAll("{0}", "$v0");
    if (v1 != null) _s = _s.replaceAll("{1}", "$v1");
    if (v2 != null) _s = _s.replaceAll("{2}", "$v2");
    if (v3 != null) _s = _s.replaceAll("{3}", "$v3");
    if (v4 != null) _s = _s.replaceAll("{4}", "$v4");
    if (v5 != null) _s = _s.replaceAll("{5}", "$v5");
    if (v6 != null) _s = _s.replaceAll("{6}", "$v6");
    return _s;
  }
}
