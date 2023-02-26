import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  group('delta_document_encoder.dart', () {
    test('', () {
      final json = jsonDecode(quillDeltaSample.replaceAll('\\\\\n', '\\n'));
      final document = DeltaDocumentConvert().convertFromJSON(json);
      expect(jsonEncode(document.toJson()), documentSample);
    });
  });
}

const documentSample =
    r'''{"document":{"type":"editor","children":[{"type":"text","attributes":{"subtype":"heading","heading":"h1"},"delta":[{"insert":"Flutter Quill"}]},{"type":"text","delta":[]},{"type":"text","attributes":{"subtype":"heading","heading":"h2"},"delta":[{"insert":"Rich text editor for Flutter"}]},{"type":"text","attributes":{"subtype":"heading","heading":"h3"},"delta":[{"insert":"Quill component for Flutter"}]},{"type":"text","delta":[{"insert":"This "},{"insert":"library","attributes":{"italic":true}},{"insert":" supports "},{"insert":"mobile","attributes":{"bold":true,"backgroundColor":"0xFFebd6ff"}},{"insert":" platform "},{"insert":"only","attributes":{"underline":true,"bold":true,"color":"0xFFe60000"}},{"insert":" and ","attributes":{"color":"0xd7000000"}},{"insert":"web","attributes":{"strikethrough":true}},{"insert":" is not supported."}]},{"type":"text","delta":[{"insert":"You are welcome to use "},{"insert":"Bullet Journal","attributes":{"href":"https://bulletjournal.us/home/index.html"}},{"insert":":"}]},{"type":"text","attributes":{"subtype":"number-list","number":1},"delta":[{"insert":"Track personal and group journals (ToDo, Note, Ledger) from multiple views with timely reminders"}]},{"type":"text","attributes":{"subtype":"number-list","number":2},"delta":[{"insert":"Share your tasks and notes with teammates, and see changes as they happen in real-time, across all devices"}]},{"type":"text","attributes":{"subtype":"number-list","number":3},"delta":[{"insert":"Check out what you and your teammates are working on each day"}]},{"type":"text","delta":[]},{"type":"text","attributes":{"subtype":"bulleted-list"},"delta":[{"insert":"Splitting bills with friends can never be easier."}]},{"type":"text","attributes":{"subtype":"bulleted-list"},"delta":[{"insert":"Start creating a group and invite your friends to join."}]},{"type":"text","attributes":{"subtype":"bulleted-list"},"delta":[{"insert":"Create a BuJo of Ledger type to see expense or balance summary."}]},{"type":"text","delta":[]},{"type":"text","attributes":{"subtype":"quote"},"delta":[{"insert":"Attach one or multiple labels to tasks, notes or transactions. Later you can track them just using the label(s)."}]},{"type":"text","delta":[]},{"type":"text","delta":[{"insert":"var BuJo = 'Bullet' + 'Journal'"}]},{"type":"text","delta":[]},{"type":"text","delta":[{"insert":"  Start tracking in your browser"}]},{"type":"text","delta":[{"insert":"  Stop the timer on your phone"}]},{"type":"text","delta":[{"insert":"    All your time entries are synced"}]},{"type":"text","delta":[{"insert":"    between the phone apps"}]},{"type":"text","delta":[{"insert":"      and the website."}]},{"type":"text","delta":[]},{"type":"text","delta":[]},{"type":"text","delta":[{"insert":"Center Align"}]},{"type":"text","delta":[{"insert":"Right Align"}]},{"type":"text","delta":[{"insert":"Justify Align"}]},{"type":"text","attributes":{"subtype":"number-list","number":1},"delta":[{"insert":"Have trouble finding things? "}]},{"type":"text","attributes":{"subtype":"number-list","number":2},"delta":[{"insert":"Just type in the search bar"}]},{"type":"text","attributes":{"subtype":"number-list","number":3},"delta":[{"insert":"and easily find contents"}]},{"type":"text","attributes":{"subtype":"number-list","number":4},"delta":[{"insert":"across projects or folders."}]},{"type":"text","attributes":{"subtype":"number-list","number":5},"delta":[{"insert":"It matches text in your note or task."}]},{"type":"text","attributes":{"subtype":"number-list","number":6},"delta":[{"insert":"Enable reminders so that you will get notified by"}]},{"type":"text","attributes":{"subtype":"number-list","number":7},"delta":[{"insert":"email"}]},{"type":"text","attributes":{"subtype":"number-list","number":8},"delta":[{"insert":"message on your phone"}]},{"type":"text","attributes":{"subtype":"number-list","number":9},"delta":[{"insert":"popup on the web site"}]},{"type":"text","children":[{"type":"text","children":[{"type":"text","attributes":{"subtype":"bulleted-list"},"delta":[{"insert":"tasks"}]},{"type":"text","attributes":{"subtype":"bulleted-list"},"delta":[{"insert":"notes"}]},{"type":"text","children":[{"type":"text","attributes":{"subtype":"bulleted-list"},"delta":[{"insert":"under BuJo "}]}],"attributes":{"subtype":"bulleted-list"},"delta":[{"insert":"transactions"}]}],"attributes":{"subtype":"bulleted-list"},"delta":[{"insert":"Organize your"}]}],"attributes":{"subtype":"bulleted-list"},"delta":[{"insert":"Create a BuJo serving as project or folder"}]},{"type":"text","children":[{"type":"text","attributes":{"subtype":"bulleted-list"},"delta":[{"insert":"or hierarchical view"}]}],"attributes":{"subtype":"bulleted-list"},"delta":[{"insert":"See them in Calendar"}]},{"type":"text","attributes":{"subtype":"checkbox","checkbox":true},"delta":[{"insert":"this is a check list"}]},{"type":"text","attributes":{"subtype":"checkbox","checkbox":false},"delta":[{"insert":"this is a uncheck list"}]},{"type":"text","delta":[{"insert":"Font Sans Serif Serif Monospace Size Small Large Hugefont size 15 font size 35 font size 20 diff-match-patch"}]},{"type":"text","delta":[{"insert":""}]}]}}''';

const quillDeltaSample = r'''
[
  {
    "insert": "Flutter Quill"
  },
  {
    "attributes": {
      "header": 1
    },
    "insert": "\n"
  },
  {
    "insert": {
      "video": "https://www.youtube.com/watch?v=V4hgdKhIqtc&list=PLbhaS_83B97s78HsDTtplRTEhcFsqSqIK&index=1"
    }
  },
  {
    "insert": {
      "video": "https://user-images.githubusercontent.com/122956/126238875-22e42501-ad41-4266-b1d6-3f89b5e3b79b.mp4"
    }
  },
  {
    "insert": "\nRich text editor for Flutter"
  },
  {
    "attributes": {
      "header": 2
    },
    "insert": "\n"
  },
  {
    "insert": "Quill component for Flutter"
  },
  {
    "attributes": {
      "header": 3
    },
    "insert": "\n"
  },
  {
    "insert": "This "
  },
  {
    "attributes": {
      "italic": true,
      "background": "transparent"
    },
    "insert": "library"
  },
  {
    "insert": " supports "
  },
  {
    "attributes": {
      "bold": true,
      "background": "#ebd6ff"
    },
    "insert": "mobile"
  },
  {
    "insert": " platform "
  },
  {
    "attributes": {
      "underline": true,
      "bold": true,
      "color": "#e60000"
    },
    "insert": "only"
  },
  {
    "attributes": {
      "color": "rgba(0, 0, 0, 0.847)"
    },
    "insert": " and "
  },
  {
    "attributes": {
      "strike": true,
      "color": "black"
    },
    "insert": "web"
  },
  {
    "insert": " is not supported.\nYou are welcome to use "
  },
  {
    "attributes": {
      "link": "https://bulletjournal.us/home/index.html"
    },
    "insert": "Bullet Journal"
  },
  {
    "insert": ":\nTrack personal and group journals (ToDo, Note, Ledger) from multiple views with timely reminders"
  },
  {
    "attributes": {
      "list": "ordered"
    },
    "insert": "\n"
  },
  {
    "insert": "Share your tasks and notes with teammates, and see changes as they happen in real-time, across all devices"
  },
  {
    "attributes": {
      "list": "ordered"
    },
    "insert": "\n"
  },
  {
    "insert": "Check out what you and your teammates are working on each day"
  },
  {
    "attributes": {
      "list": "ordered"
    },
    "insert": "\n"
  },
  {
    "insert": "\nSplitting bills with friends can never be easier."
  },
  {
    "attributes": {
      "list": "bullet"
    },
    "insert": "\n"
  },
  {
    "insert": "Start creating a group and invite your friends to join."
  },
  {
    "attributes": {
      "list": "bullet"
    },
    "insert": "\n"
  },
  {
    "insert": "Create a BuJo of Ledger type to see expense or balance summary."
  },
  {
    "attributes": {
      "list": "bullet"
    },
    "insert": "\n"
  },
  {
    "insert": "\nAttach one or multiple labels to tasks, notes or transactions. Later you can track them just using the label(s)."
  },
  {
    "attributes": {
      "blockquote": true
    },
    "insert": "\n"
  },
  {
    "insert": "\nvar BuJo = 'Bullet' + 'Journal'"
  },
  {
    "attributes": {
      "code-block": true
    },
    "insert": "\n"
  },
  {
    "insert": "\nStart tracking in your browser"
  },
  {
    "attributes": {
      "indent": 1
    },
    "insert": "\n"
  },
  {
    "insert": "Stop the timer on your phone"
  },
  {
    "attributes": {
      "indent": 1
    },
    "insert": "\n"
  },
  {
    "insert": "All your time entries are synced"
  },
  {
    "attributes": {
      "indent": 2
    },
    "insert": "\n"
  },
  {
    "insert": "between the phone apps"
  },
  {
    "attributes": {
      "indent": 2
    },
    "insert": "\n"
  },
  {
    "insert": "and the website."
  },
  {
    "attributes": {
      "indent": 3
    },
    "insert": "\n"
  },
  {
    "insert": "\n"
  },
  {
    "insert": "\nCenter Align"
  },
  {
    "attributes": {
      "align": "center"
    },
    "insert": "\n"
  },
  {
    "insert": "Right Align"
  },
  {
    "attributes": {
      "align": "right"
    },
    "insert": "\n"
  },
  {
    "insert": "Justify Align"
  },
  {
    "attributes": {
      "align": "justify"
    },
    "insert": "\n"
  },
  {
    "insert": "Have trouble finding things? "
  },
  {
    "attributes": {
      "list": "ordered"
    },
    "insert": "\n"
  },
  {
    "insert": "Just type in the search bar"
  },
  {
    "attributes": {
      "indent": 1,
      "list": "ordered"
    },
    "insert": "\n"
  },
  {
    "insert": "and easily find contents"
  },
  {
    "attributes": {
      "indent": 2,
      "list": "ordered"
    },
    "insert": "\n"
  },
  {
    "insert": "across projects or folders."
  },
  {
    "attributes": {
      "indent": 2,
      "list": "ordered"
    },
    "insert": "\n"
  },
  {
    "insert": "It matches text in your note or task."
  },
  {
    "attributes": {
      "indent": 1,
      "list": "ordered"
    },
    "insert": "\n"
  },
  {
    "insert": "Enable reminders so that you will get notified by"
  },
  {
    "attributes": {
      "list": "ordered"
    },
    "insert": "\n"
  },
  {
    "insert": "email"
  },
  {
    "attributes": {
      "indent": 1,
      "list": "ordered"
    },
    "insert": "\n"
  },
  {
    "insert": "message on your phone"
  },
  {
    "attributes": {
      "indent": 1,
      "list": "ordered"
    },
    "insert": "\n"
  },
  {
    "insert": "popup on the web site"
  },
  {
    "attributes": {
      "indent": 1,
      "list": "ordered"
    },
    "insert": "\n"
  },
  {
    "insert": "Create a BuJo serving as project or folder"
  },
  {
    "attributes": {
      "list": "bullet"
    },
    "insert": "\n"
  },
  {
    "insert": "Organize your"
  },
  {
    "attributes": {
      "indent": 1,
      "list": "bullet"
    },
    "insert": "\n"
  },
  {
    "insert": "tasks"
  },
  {
    "attributes": {
      "indent": 2,
      "list": "bullet"
    },
    "insert": "\n"
  },
  {
    "insert": "notes"
  },
  {
    "attributes": {
      "indent": 2,
      "list": "bullet"
    },
    "insert": "\n"
  },
  {
    "insert": "transactions"
  },
  {
    "attributes": {
      "indent": 2,
      "list": "bullet"
    },
    "insert": "\n"
  },
  {
    "insert": "under BuJo "
  },
  {
    "attributes": {
      "indent": 3,
      "list": "bullet"
    },
    "insert": "\n"
  },
  {
    "insert": "See them in Calendar"
  },
  {
    "attributes": {
      "list": "bullet"
    },
    "insert": "\n"
  },
  {
    "insert": "or hierarchical view"
  },
  {
    "attributes": {
      "indent": 1,
      "list": "bullet"
    },
    "insert": "\n"
  },
  {
    "insert": "this is a check list"
  },
  {
    "attributes": {
      "list": "checked"
    },
    "insert": "\n"
  },
  {
    "insert": "this is a uncheck list"
  },
  {
    "attributes": {
      "list": "unchecked"
    },
    "insert": "\n"
  },
  {
    "insert": "Font "
  },
  {
    "attributes": {
      "font": "sans-serif"
    },
    "insert": "Sans Serif"
  },
  {
    "insert": " "
  },
  {
    "attributes": {
      "font": "serif"
    },
    "insert": "Serif"
  },
  {
    "insert": " "
  },
  {
    "attributes": {
      "font": "monospace"
    },
    "insert": "Monospace"
  },
  {
    "insert": " Size "
  },
  {
    "attributes": {
      "size": "small"
    },
    "insert": "Small"
  },
  {
    "insert": " "
  },
  {
    "attributes": {
      "size": "large"
    },
    "insert": "Large"
  },
  {
    "insert": " "
  },
  {
    "attributes": {
      "size": "huge"
    },
    "insert": "Huge"
  },
  {
    "attributes": {
      "size": "15.0"
    },
    "insert": "font size 15"
  },
  {
    "insert": " "
  },
  {
    "attributes": {
      "size": "35"
    },
    "insert": "font size 35"
  },
  {
    "insert": " "
  },
  {
    "attributes": {
      "size": "20"
    },
    "insert": "font size 20"
  },
  {
    "attributes": {
      "token": "built_in"
    },
    "insert": " diff"
  },
  {
    "attributes": {
      "token": "operator"
    },
    "insert": "-match"
  },
  {
    "attributes": {
      "token": "literal"
    },
    "insert": "-patch"
  },
  {
    "insert": {
      "image": "https://user-images.githubusercontent.com/122956/72955931-ccc07900-3d52-11ea-89b1-d468a6e2aa2b.png"
    },
    "attributes": {
      "width": "230",
      "style": "display: block; margin: auto;"
    }
  },
  {
    "insert": "\n"
  }
]
''';
