import { yDocToSlateContent } from '@/application/slate-yjs/utils/convert';
import {
  createBlock,
  createEmptyDocument,
  getBlock,
  getChildrenArray,
  getPageId,
  getText,
  updateBlockParent,
} from '@/application/slate-yjs/utils/yjsOperations';
import {
  AlignType,
  BlockData,
  BlockType,
  ImageBlockData,
  ImageType,
  YBlock,
  YjsEditorKey,
  YSharedRoot,
} from '@/application/types';
import { DeltaOperation } from 'quill';

export function deserialize (body: HTMLElement, sharedRoot: YSharedRoot) {
  const pageId = getPageId(sharedRoot);
  const rootBlock = getBlock(pageId, sharedRoot);

  if (rootBlock) {
    deserializeNode(body, rootBlock, sharedRoot);
  }
}

const BLOCK_TAGS = ['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'ul', 'ol', 'li', 'blockquote', 'pre', 'img', 'input'];

function deserializeNode (node: Node, parentBlock: YBlock, sharedRoot: YSharedRoot) {
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
      const blockType = mapTagToBlockType(tagName, element);
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

    Array.from(node.childNodes).forEach(childNode => {
      deserializeNode(childNode, currentBlock, sharedRoot);
    });
  } else if (node.nodeType === Node.TEXT_NODE) {
    const textContent = node.textContent || '';

    if (textContent.trim()) {
      console.log('===textContent', node, textContent);
      const attributes = getInlineAttributes(node.parentElement as HTMLElement);

      applyTextToDelta(currentBlock, sharedRoot, textContent, attributes);
    }
  }
}

function isImageUrl (url: string): boolean {
  if (url.startsWith('https://unsplash.com/') || url.startsWith('https://images.unsplash.com/')) {
    return true;
  }

  const imageExtensions = /\.(jpeg|jpg|gif|png|svg|webp)$/i;

  if (imageExtensions.test(url)) {
    return true;
  }

  return false;
}

function processTodoList (element: HTMLElement, sharedRoot: YSharedRoot, parentBlock: YBlock, blockData: BlockData) {

  const checkboxBlock = createBlock(sharedRoot, { ty: BlockType.TodoListBlock, data: blockData });

  updateBlockParent(sharedRoot, checkboxBlock, parentBlock, getChildrenArray(parentBlock.get(YjsEditorKey.block_children), sharedRoot)?.length || 0);

  const textContent = element.nextSibling?.textContent?.trim() || '';

  if (textContent) {
    applyTextToDelta(checkboxBlock, sharedRoot, textContent);
  }
}

function processImage (sharedRoot: YSharedRoot, parentBlock: YBlock, data: ImageBlockData) {

  const imageBlock = createBlock(sharedRoot, { ty: BlockType.ImageBlock, data });

  updateBlockParent(sharedRoot, imageBlock, parentBlock, getChildrenArray(parentBlock.get(YjsEditorKey.block_children), sharedRoot)?.length || 0);
}

function processList (parentEl: HTMLElement, sharedRoot: YSharedRoot, {
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

function getInlineAttributes (element: HTMLElement): Record<string, boolean | string | undefined> {
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

function applyTextToDelta (block: YBlock, sharedRoot: YSharedRoot, text: string, attributes: object = {}) {
  const textId = block.get(YjsEditorKey.block_external_id);
  const yText = getText(textId, sharedRoot);

  if (yText) {
    const oldOps = yText.toDelta();
    const delta: DeltaOperation[] = [{ insert: text, attributes }];

    yText.delete(0, yText.length);
    yText.applyDelta([
      ...oldOps,
      ...delta,
    ]);

  }
}

function mapToBlockData<T extends BlockData> (element: HTMLElement): T {
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

function mapTagToBlockType (tag: string, el: HTMLElement): BlockType {
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

export function deserializeHTML (html: string) {
  const parsed = new DOMParser().parseFromString(html, 'text/html');
  const doc = createEmptyDocument();
  const sharedRoot = doc.getMap(YjsEditorKey.data_section) as YSharedRoot;

  deserialize(parsed.body, sharedRoot);

  const slateContent = yDocToSlateContent(doc);

  return slateContent?.children;
}