import Prism from 'prismjs';
import 'prismjs/themes/prism.css';
import 'prismjs/components/prism-javascript';
import 'prismjs/components/prism-json';
import 'prismjs/components/prism-typescript';
import 'prismjs/components/prism-rust';

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

export const decorateCode = ([node, path]: NodeEntry, language: string) => {
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
