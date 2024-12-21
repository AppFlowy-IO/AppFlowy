import { TEXT_BLOCK_TYPES } from '@/application/slate-yjs/command/const';
import { yDocToSlateContent } from '@/application/slate-yjs/utils/convert';
import {
  AlignType,
  BlockData,
  BlockType, HeadingBlockData,
  ImageBlockData,
  ImageType, NumberedListBlockData, TodoListBlockData,
  YBlock,
  YjsEditorKey,
  YSharedRoot,
} from '@/application/types';
import { filter } from 'lodash-es';
import {
  createBlock, createEmptyDocument,
  getBlock,
  getChildrenArray,
  getPageId,
  getText,
  updateBlockParent,
} from '@/application/slate-yjs/utils/yjs';
import { Op } from 'quill-delta';

export function deserialize(body: HTMLElement, sharedRoot: YSharedRoot) {
  const pageId = getPageId(sharedRoot);
  const rootBlock = getBlock(pageId, sharedRoot);

  if (rootBlock) {
    deserializeNode(body, rootBlock, sharedRoot);
  }
}

const BLOCK_TAGS = ['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'ul', 'ol', 'li', 'blockquote', 'pre', 'img', 'input'];

function deserializeNode(node: Node, parentBlock: YBlock, sharedRoot: YSharedRoot) {
  let currentBlock = parentBlock;

  if (node.nodeType === Node.ELEMENT_NODE) {
    const element = node as HTMLElement;
    const tagName = element.tagName.toLowerCase();
    const href = tagName.toLowerCase() === 'a' ? element.getAttribute('href') : null;

    if (href && isImageUrl(href)) {
      processImage(sharedRoot, parentBlock, {
        url: href,
        image_type: ImageType.External,
      });
      return;
    }

    if (BLOCK_TAGS.includes(tagName)) {
      let blockType = mapTagToBlockType(tagName, element);

      const textContent = element.textContent || '';
      const blockData = mapToBlockData(element);

      if (blockType === BlockType.NumberedListBlock || blockType === BlockType.BulletedListBlock) {
        processList(element, sharedRoot, {
          ty: blockType,
          data: blockData,
          parent: parentBlock,
        });
        return;
      }

      if (blockType === BlockType.ImageBlock) {
        processImage(sharedRoot, parentBlock, blockData);
        return;
      }

      if (blockType === BlockType.TodoListBlock) {
        processTodoList(element, sharedRoot, parentBlock, blockData);
        return;
      }

      if (blockType === BlockType.Paragraph) {
        if (textContent === '---') {
          blockType = BlockType.DividerBlock;
          element.textContent = '';
        } else if (/^(-)?\[(x| )?\]\s/.test(textContent)) {
          blockType = BlockType.TodoListBlock;
          const match = textContent.match(/^(-)?\[(x| )?\]\s/);

          (blockData as TodoListBlockData).checked = match?.[2] === 'x';
          element.textContent = textContent.replace(/^(-)?\[(x| )?\]\s/, '');
        } else if (/^\d+\.\s/.test(textContent)) {
          blockType = BlockType.NumberedListBlock;
          (blockData as NumberedListBlockData).number = parseInt(textContent.split('.')[0]);
          element.textContent = textContent.replace(/^\d+\.\s/, '');
        } else if (/^- /.test(textContent)) {
          blockType = BlockType.BulletedListBlock;
          element.textContent = textContent.replace(/^- /, '');
        } else if (/^> /.test(textContent)) {
          blockType = BlockType.QuoteBlock;
          element.textContent = textContent.replace(/^> /, '');
        } else if (/^```/.test(textContent)) {
          blockType = BlockType.CodeBlock;
          element.textContent = textContent.replace(/^```/, '');
        } else if (/^#{1,6}\s/.test(textContent)) {
          blockType = BlockType.HeadingBlock;
          element.textContent = textContent.replace(/^#{1,6}\s/, '');
          (blockData as HeadingBlockData).level = textContent.split(' ')[0].length;
        }
      }

      currentBlock = createBlock(sharedRoot, { ty: blockType, data: blockData });
      updateBlockParent(sharedRoot, currentBlock, parentBlock, getChildrenArray(parentBlock.get(YjsEditorKey.block_children), sharedRoot)?.length || 0);
      if (tagName === 'pre') {
        const code = element.querySelector('code');

        if (code) {
          applyTextToDelta(currentBlock, sharedRoot, code.textContent || '');
        } else {
          applyTextToDelta(currentBlock, sharedRoot, element.textContent || '');
        }

        return;
      }

    }

    if (tagName === 'span') {
      const children = getChildrenArray(currentBlock.get(YjsEditorKey.block_children), sharedRoot);
      const lastChildId = children?.toArray()[children?.length - 1];
      const lastChild = getBlock(lastChildId, sharedRoot);
      const attributes = getInlineAttributes(element);

      if (lastChild && (filter(TEXT_BLOCK_TYPES, n => n !== BlockType.CodeBlock).includes(lastChild.get(YjsEditorKey.block_type)))) {
        applyTextToDelta(lastChild, sharedRoot, element.textContent || '', attributes);
        return;
      } else {
        const block = createBlock(sharedRoot, { ty: BlockType.Paragraph, data: {} });

        applyTextToDelta(block, sharedRoot, element.textContent || '', attributes);

        updateBlockParent(sharedRoot, block, currentBlock, children?.length);
        return;
      }
    }

    Array.from(node.childNodes).forEach(childNode => {
      deserializeNode(childNode, currentBlock, sharedRoot);
    });
  } else if (node.nodeType === Node.TEXT_NODE) {
    const textContent = node.textContent || '';

    if (textContent.trim()) {
      console.log('===textContent', node, textContent);
      const { ops } = textContentToDelta(textContent || '');

      if (TEXT_BLOCK_TYPES.includes(currentBlock.get(YjsEditorKey.block_type))) {
        const attributes = getInlineAttributes(node.parentElement as HTMLElement);

        ops.forEach(op => {
          applyTextToDelta(currentBlock, sharedRoot, op.insert as string, {
            ...op.attributes,
            ...attributes,
          });
        });
        // applyTextToDelta(currentBlock, sharedRoot, textContent, attributes);
      } else {
        const block = createBlock(sharedRoot, { ty: BlockType.Paragraph, data: {} });

        applyTextToDelta(block, sharedRoot, textContent);
        const index = getChildrenArray(currentBlock.get(YjsEditorKey.block_children), sharedRoot)?.length || 0;

        updateBlockParent(sharedRoot, block, currentBlock, index);
      }

    }
  }
}

function textContentToDelta(text: string) {
  const ops: Op[] = [];
  let currentIndex = 0;

  const patterns = [
    { regex: /\*\*(.*?)\*\*/g, format: 'bold' },     // **bold**
    { regex: /\*(.*?)\*/g, format: 'italic' },        // *italic*
    { regex: /__(.*?)__/g, format: 'underline' },     // __underline__
    { regex: /~~(.*?)~~/g, format: 'strike' },        // ~~strike~~
  ];

  type Mark = {
    start: number;
    end: number;
    text: string;
    format: string;
    length: number;
  }

  const findMarks = (): Mark[] => {
    const marks: Mark[] = [];

    patterns.forEach(({ regex, format }) => {
      let match;

      while ((match = regex.exec(text)) !== null) {
        marks.push({
          start: match.index,
          end: match.index + match[0].length,
          text: match[1],
          format,
          length: match[0].length,
        });
      }
    });

    return marks.sort((a, b) => a.start - b.start);
  };

  const marks = findMarks();

  const getFormatsAt = (index: number): Record<string, boolean> => {
    const formats: Record<string, boolean> = {};

    marks.forEach(mark => {
      if (index >= mark.start && index < mark.end) {
        formats[mark.format] = true;
      }
    });
    return formats;
  };

  const findNextBreakPoint = (currentIndex: number): number => {
    const points = new Set<number>();

    marks.forEach(mark => {
      if (mark.start > currentIndex) points.add(mark.start);
      if (mark.end > currentIndex) points.add(mark.end);
    });
    const nextPoints = Array.from(points).sort((a, b) => a - b);

    return nextPoints[0] || text.length;
  };

  while (currentIndex < text.length) {
    const nextBreak = findNextBreakPoint(currentIndex);
    const currentFormats = getFormatsAt(currentIndex);

    let segment = text.slice(currentIndex, nextBreak);

    patterns.forEach(({ regex }) => {
      segment = segment.replace(regex, '$1');
    });

    if (segment) {
      ops.push({
        insert: segment,
        ...(Object.keys(currentFormats).length > 0 ? { attributes: currentFormats } : {}),
      });
    }

    currentIndex = nextBreak;
  }

  return { ops };
}

function isImageUrl(url: string): boolean {
  if (url.startsWith('https://unsplash.com/') || url.startsWith('https://images.unsplash.com/')) {
    return true;
  }

  const imageExtensions = /\.(jpeg|jpg|gif|png|svg|webp)$/i;

  if (imageExtensions.test(url)) {
    return true;
  }

  return false;
}

function processTodoList(element: HTMLElement, sharedRoot: YSharedRoot, parentBlock: YBlock, blockData: BlockData) {

  const checkboxBlock = createBlock(sharedRoot, { ty: BlockType.TodoListBlock, data: blockData });

  updateBlockParent(sharedRoot, checkboxBlock, parentBlock, getChildrenArray(parentBlock.get(YjsEditorKey.block_children), sharedRoot)?.length || 0);

  const textContent = element.nextSibling?.textContent?.trim() || '';

  if (textContent) {
    applyTextToDelta(checkboxBlock, sharedRoot, textContent);
  }
}

function processImage(sharedRoot: YSharedRoot, parentBlock: YBlock, data: ImageBlockData) {

  const imageBlock = createBlock(sharedRoot, { ty: BlockType.ImageBlock, data });

  updateBlockParent(sharedRoot, imageBlock, parentBlock, getChildrenArray(parentBlock.get(YjsEditorKey.block_children), sharedRoot)?.length || 0);
}

function processList(parentEl: HTMLElement, sharedRoot: YSharedRoot, {
  ty,
  data,
  parent,
}: {
  ty: BlockType,
  data: BlockData,
  parent: YBlock
}) {
  Array.from(parentEl.childNodes).forEach(childNode => {
    const el = childNode as HTMLElement;

    if (!el || !el.tagName) return;
    const tagName = el.tagName.toLowerCase();
    const type = tagName === 'li' ? ty : BlockType.Paragraph;
    const block = createBlock(sharedRoot, { ty: type, data });

    updateBlockParent(sharedRoot, block, parent, getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot)?.length || 0);
    Array.from(el.childNodes).forEach(childNode => {
      deserializeNode(childNode, block, sharedRoot);
    });
  });
}

function getInlineAttributes(element: HTMLElement): Record<string, boolean | string | undefined> {
  const attributes: Record<string, boolean | string | undefined> = {};

  if (element.style.fontWeight === 'bold' || element.tagName.toLowerCase() === 'strong') {
    attributes.bold = true;
  }

  if (element.style.fontStyle === 'italic' || element.tagName.toLowerCase() === 'em') {
    attributes.italic = true;
  }

  if (element.style.textDecoration === 'underline' || element.tagName.toLowerCase() === 'u') {
    attributes.underline = true;
  }

  if (element.style.textDecoration === 'line-through' || element.tagName.toLowerCase() === 'strike') {
    attributes.strikethrough = true;
  }

  if (element.tagName.toLowerCase() === 'a') {
    attributes.href = element.getAttribute('href') || '';
  }

  if (element.tagName.toLowerCase() === 'code') {
    attributes.code = true;
  }

  return attributes;
}

function applyTextToDelta(block: YBlock, sharedRoot: YSharedRoot, text: string, attributes: object = {}) {
  const textId = block.get(YjsEditorKey.block_external_id);
  const yText = getText(textId, sharedRoot);

  if (yText) {
    yText.insert(yText.length, text, attributes);
  }
}

function mapToBlockData<T extends BlockData>(element: HTMLElement): T {
  const data = {} as T;

  const tag = element.tagName.toLowerCase();

  const styleString = element.getAttribute('style');

  if (styleString) {
    const styles = styleString.split(';').reduce((acc, style) => {
      const [key, value] = style.split(':').map(s => s.trim());

      if (key && value) {
        acc[key] = value;
      }

      return acc;
    }, {} as Record<string, string>);

    if (styles['text-align']) {
      const align = styles['text-align'];

      if (align === 'end' || align === 'right') {
        data.align = AlignType.Left;
      } else if (align === 'center') {
        data.align = AlignType.Center;
      } else {
        data.align = AlignType.Left;
      }
    }

    if (styles['background-color']) {
      data.bgColor = styles['background-color'];
    }

    if (styles['color']) {
      data.font_color = styles['color'];
    }
  }

  switch (tag) {
    case 'h1':
      Object.assign(data, { level: 1 });
      break;
    case 'h2':
      Object.assign(data, { level: 2 });
      break;
    case 'h3':
      Object.assign(data, { level: 3 });
      break;
    case 'h4':
      Object.assign(data, { level: 4 });
      break;
    case 'h5':
      Object.assign(data, { level: 5 });
      break;
    case 'h6':
      Object.assign(data, { level: 6 });
      break;
    case 'img': {
      const url = element.getAttribute('src');

      Object.assign(data, {
        url,
        image_type: ImageType.External,
      });
      break;
    }

    case 'input': {
      if (element.getAttribute('type') === 'checkbox') {
        const isChecked = element.hasAttribute('checked');

        Object.assign(data, {
          checked: isChecked,
        });
      }

      break;
    }
  }

  return data;
}

function mapTagToBlockType(tag: string, el: HTMLElement): BlockType {
  switch (tag) {
    case 'p':
      return BlockType.Paragraph;
    case 'h1':
    case 'h2':
    case 'h3':
    case 'h4':
    case 'h5':
    case 'h6':
      return BlockType.HeadingBlock;

    case 'ul':
      return BlockType.BulletedListBlock;
    case 'ol':
      return BlockType.NumberedListBlock;
    case 'blockquote':
      return BlockType.QuoteBlock;
    case 'pre':
      return BlockType.CodeBlock;
    case 'img':
      return BlockType.ImageBlock;
    case 'input':
      if (el.getAttribute('type') === 'checkbox') {
        return BlockType.TodoListBlock;
      }

      return BlockType.Paragraph;
    default:
      return BlockType.Paragraph;
  }
}

export function deserializeHTML(html: string) {
  const parsed = new DOMParser().parseFromString(html, 'text/html');
  const doc = createEmptyDocument();
  const sharedRoot = doc.getMap(YjsEditorKey.data_section) as YSharedRoot;

  deserialize(parsed.body, sharedRoot);

  const slateContent = yDocToSlateContent(doc);

  return slateContent?.children;
}