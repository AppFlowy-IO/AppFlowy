import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NodeAttributesExtensions::', () {
    test('heading', () {
      final Attributes attribute = {
        'subtype': 'heading',
        'heading': 'AppFlowy',
      };
      expect(attribute.heading, 'AppFlowy');
    });

    test('heading - text is not String return null', () {
      final Attributes attribute = {
        'subtype': 'heading',
        'heading': 123,
      };
      expect(attribute.heading, null);
    });

    test('heading - subtype is not "heading" return null', () {
      final Attributes attribute = {
        'subtype': 'code',
        'heading': 'Hello World!',
      };
      expect(attribute.heading, null);
    });

    test('quote', () {
      final Attributes attribute = {
        'quote': 'quote text',
      };
      expect(attribute.quote, true);
    });

    test('number - int', () {
      final Attributes attribute = {
        'number': 99,
      };
      expect(attribute.number, 99);
    });

    test('number - double', () {
      final Attributes attribute = {
        'number': 12.34,
      };
      expect(attribute.number, 12.34);
    });

    test('number - return null', () {
      final Attributes attribute = {
        'code': 12.34,
      };
      expect(attribute.number, null);
    });

    test('code', () {
      final Attributes attribute = {
        'code': true,
      };
      expect(attribute.code, true);
    });

    test('code - return false', () {
      final Attributes attribute = {
        'quote': true,
      };
      expect(attribute.code, false);
    });

    test('check', () {
      final Attributes attribute = {
        'checkbox': true,
      };
      expect(attribute.check, true);
    });

    test('check - return false', () {
      final Attributes attribute = {
        'quote': true,
      };
      expect(attribute.check, false);
    });
  });

  group('DeltaAttributesExtensions::', () {
    test('bold', () {
      final Attributes attribute = {
        'bold': true,
      };
      expect(attribute.bold, true);
    });

    test('bold - return false', () {
      final Attributes attribute = {
        'bold': 123,
      };
      expect(attribute.bold, false);
    });

    test('italic', () {
      final Attributes attribute = {
        'italic': true,
      };
      expect(attribute.italic, true);
    });

    test('italic - return false', () {
      final Attributes attribute = {
        'italic': 123,
      };
      expect(attribute.italic, false);
    });

    test('underline', () {
      final Attributes attribute = {
        'underline': true,
      };
      expect(attribute.underline, true);
    });

    test('underline - return false', () {
      final Attributes attribute = {
        'underline': 123,
      };
      expect(attribute.underline, false);
    });

    test('strikethrough', () {
      final Attributes attribute = {
        'strikethrough': true,
      };
      expect(attribute.strikethrough, true);
    });

    test('strikethrough - return false', () {
      final Attributes attribute = {
        'strikethrough': 123,
      };
      expect(attribute.strikethrough, false);
    });

    test('color', () {
      final Attributes attribute = {
        'color': '0xff212fff',
      };
      expect(attribute.color, const Color(0XFF212FFF));
    });

    test('color - return null', () {
      final Attributes attribute = {
        'color': 123,
      };
      expect(attribute.color, null);
    });

    test('color - parse failure return white', () {
      final Attributes attribute = {
        'color': 'hello123',
      };
      expect(attribute.color, const Color(0XFFFFFFFF));
    });

    test('backgroundColor', () {
      final Attributes attribute = {
        'backgroundColor': '0xff678fff',
      };
      expect(attribute.backgroundColor, const Color(0XFF678FFF));
    });

    test('backgroundColor - return null', () {
      final Attributes attribute = {
        'backgroundColor': 123,
      };
      expect(attribute.backgroundColor, null);
    });

    test('backgroundColor - parse failure return white', () {
      final Attributes attribute = {
        'backgroundColor': 'hello123',
      };
      expect(attribute.backgroundColor, const Color(0XFFFFFFFF));
    });

    test('href', () {
      final Attributes attribute = {
        'href': '/app/flowy',
      };
      expect(attribute.href, '/app/flowy');
    });

    test('href - return null', () {
      final Attributes attribute = {
        'href': 123,
      };
      expect(attribute.href, null);
    });
  });
}
