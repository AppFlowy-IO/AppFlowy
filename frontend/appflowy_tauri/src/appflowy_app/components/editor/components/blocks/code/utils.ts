import Prism from 'prismjs';

import 'prismjs/components/prism-bash';
import 'prismjs/components/prism-basic';
import 'prismjs/components/prism-c';
import 'prismjs/components/prism-clojure';
import 'prismjs/components/prism-cpp';
import 'prismjs/components/prism-csp';
import 'prismjs/components/prism-css';
import 'prismjs/components/prism-dart';
import 'prismjs/components/prism-elixir';
import 'prismjs/components/prism-elm';
import 'prismjs/components/prism-erlang';
import 'prismjs/components/prism-fortran';
import 'prismjs/components/prism-go';
import 'prismjs/components/prism-graphql';
import 'prismjs/components/prism-haskell';
import 'prismjs/components/prism-java';
import 'prismjs/components/prism-javascript';
import 'prismjs/components/prism-json';
import 'prismjs/components/prism-kotlin';
import 'prismjs/components/prism-lisp';
import 'prismjs/components/prism-lua';
import 'prismjs/components/prism-markdown';
import 'prismjs/components/prism-matlab';
import 'prismjs/components/prism-ocaml';
import 'prismjs/components/prism-perl';
import 'prismjs/components/prism-php';
import 'prismjs/components/prism-powershell';
import 'prismjs/components/prism-python';
import 'prismjs/components/prism-r';
import 'prismjs/components/prism-ruby';
import 'prismjs/components/prism-rust';
import 'prismjs/components/prism-scala';
import 'prismjs/components/prism-shell-session';
import 'prismjs/components/prism-sql';
import 'prismjs/components/prism-swift';
import 'prismjs/components/prism-typescript';
import 'prismjs/components/prism-xml-doc';
import 'prismjs/components/prism-yaml';

import { BaseRange, NodeEntry, Text, Path } from 'slate';

const push_string = (
  token: string | Prism.Token,
  path: Path,
  start: number,
  ranges: BaseRange[],
  token_type = 'text'
) => {
  let newStart = start;

  ranges.push({
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    prism_token: token_type,
    anchor: { path, offset: newStart },
    focus: { path, offset: newStart + token.length },
  });
  newStart += token.length;
  return newStart;
};

// This recurses through the Prism.tokenizes result and creates stylized ranges based on the token type
const recurseTokenize = (
  token: string | Prism.Token,
  path: Path,
  ranges: BaseRange[],
  start: number,
  parent_tag?: string
) => {
  // Uses the parent's token type if a Token only has a string as its content
  if (typeof token === 'string') {
    return push_string(token, path, start, ranges, parent_tag);
  }

  if ('content' in token) {
    if (token.content instanceof Array) {
      // Calls recurseTokenize on nested Tokens in content
      let newStart = start;

      for (const subToken of token.content) {
        newStart = recurseTokenize(subToken, path, ranges, newStart, token.type) || 0;
      }

      return newStart;
    }

    return push_string(token.content, path, start, ranges, token.type);
  }
};

function switchCodeTheme(isDark: boolean) {
  const link = document.getElementById('prism-css');

  if (link) {
    document.head.removeChild(link);
  }

  const newLink = document.createElement('link');

  newLink.rel = 'stylesheet';
  newLink.href = isDark
    ? 'https://cdnjs.cloudflare.com/ajax/libs/prism/1.24.1/themes/prism-dark.min.css'
    : 'https://cdnjs.cloudflare.com/ajax/libs/prism/1.24.1/themes/prism.min.css';
  newLink.id = 'prism-css';
  document.head.appendChild(newLink);
}

export const decorateCode = ([node, path]: NodeEntry, language: string, isDark: boolean) => {
  switchCodeTheme(isDark);

  const ranges: BaseRange[] = [];

  if (!Text.isText(node)) {
    return ranges;
  }

  try {
    const tokens = Prism.tokenize(node.text, Prism.languages[language]);

    let start = 0;

    for (const token of tokens) {
      start = recurseTokenize(token, path, ranges, start) || 0;
    }

    return ranges;
  } catch {
    return ranges;
  }
};
