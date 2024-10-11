import { deserializeHTML } from '../fragment';
import { BlockType, ImageType, AlignType } from '@/application/types';
import { expect } from '@jest/globals';
import { Element, Node } from 'slate';

jest.mock('nanoid');
describe('deserializeHTML', () => {
  // Test basic HTML elements
  it('should correctly deserialize basic HTML content', () => {
    const testHTML = `
      <p>Hello, world!</p>
      <h1>Title 1</h1>
      <h2>Title 2</h2>
      <h3>Title 3</h3>
      <img src="https://example.com/image.jpg" />
      <input type="checkbox" checked />Task
    `;

    const result = deserializeHTML(testHTML) as Node[];

    expect(result).toBeDefined();
    expect(Array.isArray(result)).toBe(true);
    expect(result.length).toBe(6);

    // Check paragraph
    let blockId = (result[0] as Element).blockId as string;
    expect(result[0]).toEqual(expect.objectContaining({
      blockId,
      type: BlockType.Paragraph,
      data: {},
      children: [{ type: 'text', children: [{ text: 'Hello, world!' }], textId: blockId }],
    }));

    // Check headings
    for (let i = 1; i <= 3; i++) {
      const blockId = (result[i] as Element).blockId as string;
      expect(result[i]).toEqual(expect.objectContaining({
        type: BlockType.HeadingBlock,
        children: [{
          type: 'text',
          textId: blockId,
          children: [{ text: `Title ${i}` }],
        }],
        data: { level: i },
        blockId,
      }));
    }

    // Check image
    blockId = (result[4] as Element).blockId as string;
    expect(result[4]).toEqual(expect.objectContaining({
      blockId,
      type: BlockType.ImageBlock,
      children: [{
        type: 'text',
        textId: blockId,
        children: [{ text: '' }],
      }],
      data: { url: 'https://example.com/image.jpg', image_type: ImageType.External },
    }));

    // Check todo list
    blockId = (result[5] as Element).blockId as string;
    expect(result[5]).toEqual(expect.objectContaining({
      type: BlockType.TodoListBlock,
      blockId,
      children: [{
        type: 'text',
        textId: blockId,
        children: [{ text: 'Task' }],
      }],
      data: { checked: true },
    }));
  });

  // Test list elements
  it('should correctly deserialize list elements', () => {
    const testHTML = `
      <ul>
        <li>Bullet 1</li>
        <li>Bullet 2</li>
      </ul>
      <ol>
        <li>Number 1</li>
        <li>Number 2</li>
      </ol>
    `;

    const result = deserializeHTML(testHTML) as Node[];

    expect(result.length).toBe(4);

    // Check unordered list
    let blockId = (result[0] as Element).blockId as string;
    expect(result[0]).toEqual(expect.objectContaining({
      blockId,
      type: BlockType.BulletedListBlock,
      children: [
        { type: 'text', textId: blockId, children: [{ text: 'Bullet 1' }] },
      ],
    }));
    blockId = (result[1] as Element).blockId as string;
    expect(result[1]).toEqual(expect.objectContaining({
      blockId,
      type: BlockType.BulletedListBlock,
      children: [{ type: 'text', textId: blockId, children: [{ text: 'Bullet 2' }] }],
    }));

    // Check ordered list
    blockId = (result[2] as Element).blockId as string;
    expect(result[2]).toEqual(expect.objectContaining({
      blockId,
      type: BlockType.NumberedListBlock,
      children: [{ type: 'text', textId: blockId, children: [{ text: 'Number 1' }] }],
    }));

    blockId = (result[3] as Element).blockId as string;
    expect(result[3]).toEqual(expect.objectContaining({
      type: BlockType.NumberedListBlock,
      children: [{ type: 'text', textId: blockId, children: [{ text: 'Number 2' }] }],
      blockId,
    }));
  });

  // Test blockquote and code block
  it('should correctly deserialize blockquote and code block', () => {
    const testHTML = `
      <blockquote>This is a quote</blockquote>
      <pre><code>const x = 5;</code></pre>
    `;

    const result = deserializeHTML(testHTML) as Node[];

    expect(result.length).toBe(2);

    // Check blockquote
    let blockId = (result[0] as Element).blockId as string;
    expect(result[0]).toEqual(expect.objectContaining({
      type: BlockType.QuoteBlock,
      children: [{ type: 'text', textId: blockId, children: [{ text: 'This is a quote' }] }],
      blockId,
    }));

    // Check code block
    blockId = (result[1] as Element).blockId as string;
    expect(result[1]).toEqual(expect.objectContaining({
      type: BlockType.CodeBlock,
      children: [{ type: 'text', textId: blockId, children: [{ text: 'const x = 5;' }] }],
      blockId,
    }));
  });

  // Test inline styles
  it('should correctly deserialize inline styles', () => {
    const testHTML = `
      <p><strong>Bold</strong> <em>Italic</em> <u>Underline</u> <strike>Strikethrough</strike> <code>Inline Code</code></p>
    `;

    const result = deserializeHTML(testHTML) as Node[];

    expect(result.length).toBe(1);
    expect(((result[0] as Element).children[0] as Element).children).toEqual([
      { text: 'Bold', bold: true },
      { text: 'Italic', italic: true },
      { text: 'Underline', underline: true },
      { text: 'Strikethrough', strikethrough: true },
      { text: 'Inline Code', code: true },
    ]);
  });

  // Test alignment and colors
  it('should correctly deserialize alignment and colors', () => {
    const testHTML = `
      <p style="text-align: center; background-color: #f0f0f0; color: #333;">Centered text with background and color</p>
    `;

    const result = deserializeHTML(testHTML) as Node[];

    expect(result.length).toBe(1);
    let blockId = (result[0] as Element).blockId as string;
    expect(result[0]).toEqual(expect.objectContaining({
      blockId,
      type: BlockType.Paragraph,
      children: [{ type: 'text', textId: blockId, children: [{ text: 'Centered text with background and color' }] }],

      data: {
        align: AlignType.Center,
        bgColor: '#f0f0f0',
        font_color: '#333',
      },
    }));
  });

  // Test empty HTML
  it('should handle empty HTML', () => {
    const result = deserializeHTML('') as Node[];

    expect(result).toBeDefined();
    expect(Array.isArray(result)).toBe(true);
    expect(result.length).toBe(0);
  });

  // Test nested structures
  it('should correctly deserialize nested structures', () => {
    const testHTML = `
      <ul>
        <li>
          <h3>Nested Heading</h3>
          <p>Nested paragraph</p>
        </li>
      </ul>
    `;

    const result = deserializeHTML(testHTML) as Node[];

    expect(result.length).toBe(1);
    const block = result[0] as Element;
    console.log('===', result);
    expect(block.type).toEqual(BlockType.BulletedListBlock);
    const blockChildren = block.children;
    expect(blockChildren.length).toEqual(3);
    expect(blockChildren[1]).toEqual({
      blockId: (blockChildren[1] as Element).blockId,
      type: BlockType.HeadingBlock,
      relationId: (blockChildren[1] as Element).blockId,
      children: [{
        type: 'text',
        textId: (blockChildren[1] as Element).blockId,
        children: [{ text: 'Nested Heading' }],
      }],
      data: { level: 3 },
    });
    expect(blockChildren[2]).toEqual({
      blockId: (blockChildren[2] as Element).blockId,
      type: BlockType.Paragraph,
      relationId: (blockChildren[2] as Element).blockId,
      data: {},
      children: [{
        type: 'text',
        textId: (blockChildren[2] as Element).blockId,
        children: [{ text: 'Nested paragraph' }],
      }],
    });

  });
});