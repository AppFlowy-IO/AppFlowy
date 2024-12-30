import { BlockType } from '@/application/types';
import { CustomEditor } from 'src/application/slate-yjs/command';
import { HeadingNode } from '@/components/editor/editor.type';
import { Element, Text } from 'slate';
import { ReactEditor } from 'slate-react';

export function extractHeadings (editor: ReactEditor, maxDepth: number): HeadingNode[] {
  const headings: HeadingNode[] = [];
  const blocks = editor.children;

  function traverse (children: (Element | Text)[]) {
    for (const block of children) {
      if (Text.isText(block)) continue;
      if (block.type === BlockType.HeadingBlock && (block as HeadingNode).data?.level <= maxDepth) {
        headings.push({
          ...block,
          data: {
            level: (block as HeadingNode).data.level,
            text: CustomEditor.getBlockTextContent(block),
          },
          children: [],
        } as HeadingNode);
      } else {
        traverse(block.children);
      }
    }

    return headings;
  }

  return traverse(blocks);
}

export function nestHeadings (headings: HeadingNode[]): HeadingNode[] {
  const root: HeadingNode[] = [];
  const stack: HeadingNode[] = [];

  headings.forEach((heading) => {
    const node = { ...heading, children: [] };

    while (stack.length > 0 && stack[stack.length - 1].data.level >= node.data.level) {
      stack.pop();
    }

    if (stack.length === 0) {
      root.push(node);
    } else {
      stack[stack.length - 1].children.push(node);
    }

    stack.push(node);
  });

  return root;
}
