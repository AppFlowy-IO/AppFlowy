// DO NOT EDIT. This is code generated via package:easy_localization/generate.dart

// ignore_for_file: prefer_single_quotes

import 'dart:ui';

import 'package:easy_localization/easy_localization.dart' show AssetLoader;

class CodegenLoader extends AssetLoader{
  const CodegenLoader();

  @override
  Future<Map<String, dynamic>> load(String fullPath, Locale locale ) {
    return Future.value(mapLocales[locale.toString()]);
  }

  static const Map<String,dynamic> en = {
  "appName": "Appflowy",
  "defaultUsername": "Me",
  "welcomeText": "Welcome to @:appName",
  "githubStarText": "Star on GitHub",
  "subscribeNewsletterText": "Subscribe to Newsletter",
  "letsGoButtonText": "Let's Go",
  "title": "Title",
  "signUp": {
    "buttonText": "Sign Up",
    "title": "Sign Up to @:appName",
    "getStartedText": "Get Started",
    "emptyPasswordError": "Password can't be empty",
    "repeatPasswordEmptyError": "Repeat password can't be empty",
    "unmatchedPasswordError": "Repeat password is not the same as password",
    "alreadyHaveAnAccount": "Already have an account?",
    "emailHint": "Email",
    "passwordHint": "Password",
    "repeatPasswordHint": "Repeat password"
  },
  "signIn": {
    "loginTitle": "Login to @:appName",
    "loginButtonText": "Login",
    "buttonText": "Sign In",
    "forgotPassword": "Forgot Password?",
    "emailHint": "Email",
    "passwordHint": "Password",
    "dontHaveAnAccount": "Don't have an account?",
    "repeatPasswordEmptyError": "Repeat password can't be empty",
    "unmatchedPasswordError": "Repeat password is not the same as password"
  },
  "workspace": {
    "create": "Create workspace",
    "hint": "workspace",
    "notFoundError": "Workspace not found"
  },
  "shareAction": {
    "buttonText": "Share",
    "workInProgress": "Work in progress",
    "markdown": "Markdown",
    "copyLink": "Copy Link"
  },
  "disclosureAction": {
    "rename": "Rename",
    "delete": "Delete",
    "duplicate": "Duplicate"
  },
  "blankPageTitle": "Blank page",
  "newPageText": "New page",
  "trash": {
    "text": "Trash",
    "restoreAll": "Restore All",
    "deleteAll": "Delete All",
    "pageHeader": {
      "fileName": "File name",
      "lastModified": "Last Modified",
      "created": "Created"
    }
  },
  "deletePagePrompt": {
    "text": "This page is in Trash",
    "restore": "Restore page",
    "deletePermanent": "Delete permanently"
  },
  "dialogCreatePageNameHint": "Page name",
  "questionBubble": {
    "whatsNew": "What's new?",
    "help": "Help & Support"
  },
  "menuAppHeader": {
    "addPageTooltip": "Quickly add a page inside",
    "defaultNewPageName": "Untitled",
    "renameDialog": "Rename"
  },
  "toolbar": {
    "undo": "Undo",
    "redo": "Redo",
    "bold": "Bold",
    "italic": "Italic",
    "underline": "Underline",
    "strike": "Strikethrough",
    "numList": "Numbered List",
    "bulletList": "Bulleted List",
    "checkList": "Check List",
    "inlineCode": "Inline Code",
    "quote": "Quote Block"
  },
  "contactsPage": {
    "title": "Contacts",
    "whatsHappening": "What's happening this week?",
    "addContact": "Add Contact",
    "editContact": "Edit Contact"
  },
  "button": {
    "OK": "OK",
    "Cancel": "Cancel",
    "signIn": "Sign In",
    "signOut": "Sign Out",
    "complete": "Complete",
    "save": "Save"
  },
  "label": {
    "welcome": "Welcome!",
    "firstName": "First Name",
    "middleName": "Middle Name",
    "lastName": "Last Name",
    "stepX": "Step {X}"
  },
  "oAuth": {
    "err": {
      "failedTitle": "Unable to connect to your account.",
      "failedMsg": "Please make sure you've completed the sign-in process in your browser."
    },
    "google": {
      "title": "GOOGLE SIGN-IN",
      "instruction1": "In order to import your Google Contacts, you'll need to authorize this application using your web browser.",
      "instruction2": "Copy this code to your clipboard by clicking the icon or selecting the text:",
      "instruction3": "Navigate to the following link in your web browser, and enter the above code:",
      "instruction4": "Press the button below when you've completed signup:"
    }
  }
};
static const Map<String,dynamic> zh_CN = {
  "appName": "Appflowy",
  "defaultUsername": "我",
  "welcomeText": "欢迎使用 @:appName",
  "githubStarText": "Star on GitHub",
  "subscribeNewsletterText": "消息订阅",
  "letsGoButtonText": "开始",
  "title": "标题",
  "signUp": {
    "buttonText": "注册",
    "title": "注册 @:appName 账户",
    "getStartedText": "开始",
    "emptyPasswordError": "密码不能为空",
    "repeatPasswordEmptyError": "确认密码不能为空",
    "unmatchedPasswordError": "两次密码输入不一致",
    "alreadyHaveAnAccount": "已有账户?",
    "emailHint": "邮箱",
    "passwordHint": "密码",
    "repeatPasswordHint": "确认密码"
  },
  "signIn": {
    "loginTitle": "登录 @:appName",
    "loginButtonText": "登录",
    "buttonText": "登录",
    "forgotPassword": "忘记密码?",
    "emailHint": "邮箱",
    "passwordHint": "密码",
    "dontHaveAnAccount": "没有已注册的账户?",
    "repeatPasswordEmptyError": "确认密码不能为空",
    "unmatchedPasswordError": "两次密码输入不一致"
  },
  "workspace": {
    "create": "新建空间",
    "hint": "空间",
    "notFoundError": "未知的空间"
  },
  "shareAction": {
    "buttonText": "分享",
    "workInProgress": "进行中",
    "markdown": "Markdown",
    "copyLink": "复制链接"
  },
  "disclosureAction": {
    "rename": "重命名",
    "delete": "删除",
    "duplicate": "复制"
  },
  "blankPageTitle": "空白页",
  "newPageText": "新页面",
  "trash": {
    "text": "回收站",
    "restoreAll": "全部恢复",
    "deleteAll": "全部删除",
    "pageHeader": {
      "fileName": "文件名",
      "lastModified": "最近修改",
      "created": "创建"
    }
  },
  "deletePagePrompt": {
    "text": "此页面已被移动至回收站",
    "restore": "恢复页面",
    "deletePermanent": "彻底删除"
  },
  "dialogCreatePageNameHint": "页面名称",
  "questionBubble": {
    "whatsNew": "新功能?",
    "help": "帮助 & 支持"
  },
  "menuAppHeader": {
    "addPageTooltip": "在其中快速添加页面",
    "defaultNewPageName": "未命名页面",
    "renameDialog": "重命名"
  },
  "toolbar": {
    "undo": "撤销",
    "redo": "恢复",
    "bold": "加粗",
    "italic": "斜体",
    "underline": "下划线",
    "strike": "删除线",
    "numList": "有序列表",
    "bulletList": "无序列表",
    "checkList": "任务列表",
    "inlineCode": "内联代码",
    "quote": "块引用"
  },
  "contactsPage": {
    "title": "联系人",
    "whatsHappening": "这周发生了哪些事?",
    "addContact": "添加联系人",
    "editContact": "编辑联系人"
  },
  "button": {
    "OK": "确认",
    "Cancel": "取消",
    "signIn": "登录",
    "signOut": "登出",
    "complete": "完成",
    "save": "保存"
  },
  "label": {
    "welcome": "欢迎!",
    "firstName": "名",
    "middleName": "中间名",
    "lastName": "姓",
    "stepX": "第{X}步"
  },
  "oAuth": {
    "err": {
      "failedTitle": "无法连接到您的账户。",
      "failedMsg": "请确认您已在浏览器中完成登录。"
    },
    "google": {
      "title": "Google 账号登录",
      "instruction1": "为了导入您的 Google 联系人，您需要在浏览器中给予本程序授权。",
      "instruction2": "单击图标或选择文本复制到剪贴板：",
      "instruction3": "进入下面的链接，然后输入上面的代码：",
      "instruction4": "完成注册后，点击下面的按钮："
    }
  }
};
static const Map<String, Map<String,dynamic>> mapLocales = {"en": en, "zh_CN": zh_CN};
}
