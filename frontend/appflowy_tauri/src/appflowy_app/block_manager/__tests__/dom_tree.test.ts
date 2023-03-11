import { DOMTree } from '../dom_tree';
import { BlockType, Block } from '../../interfaces/index';

const loadBlockData = async (id: string): Promise<Record<string, Block>> => {
  return {
    [id]: {
      id: id,
      type: BlockType.PageBlock,
      data: { title: 'Document Title' },
      next: null,
      firstChild: "L1-1",
    },
    "L1-1": {
      id: "L1-1",
      type: BlockType.HeadingBlock,
      data: { level: 1, content: [{ text: 'Heading 1' }] },
      next: "L1-2",
      firstChild: null,
    },
    "L1-2": {
      id: "L1-2",
      type: BlockType.HeadingBlock,
      data: { level: 2, content: [{ text: 'Heading 2' }] },
      next: "L1-3",
      firstChild: null,
    },
    "L1-3": {
      id: "L1-3",
      type: BlockType.HeadingBlock,
      data: { level: 3, content: [{ text: 'Heading 3' }] },
      next: "L1-4",
      firstChild: null,
    },
    "L1-4": {
      id: "L1-4",
      type: BlockType.TextBlock,
      data: { content: [
        {
          text:
            'This example shows how you can make a hovering menu appear above your content, which you can use to make text ',
        },
        { text: 'bold', bold: true },
        { text: ', ' },
        { text: 'italic', italic: true },
        { text: ', or anything else you might want to do!' },
      ] },
      next: "L1-5",
      firstChild: null,
    },
    "L1-5": {
      id: "L1-5",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
        { text: 'select any piece of text and the menu will appear', bold: true },
        { text: '.' },
      ] },
      next: "L1-6",
      firstChild: "L1-5-1",
    },
    "L1-5-1": {
      id: "L1-5-1",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: "L1-5-2",
      firstChild: null,
    },
    "L1-5-2": {
      id: "L1-5-2",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: null,
      firstChild: null,
    },
    "L1-6": {
      id: "L1-6",
      type: BlockType.ListBlock,
      data: { type: 'bulleted', content: [
        {
          text:
            "Since it's rich text, you can do things like turn a selection of text ",
        },
        { text: 'bold', bold: true },
        {
          text:
            ', or add a semantically rendered block quote in the middle of the page, like this:',
        },
      ] },
      next: "L1-7",
      firstChild: "L1-6-1",
    },
    "L1-6-1": {
      id: "L1-6-1",
      type: BlockType.ListBlock,
      data: { type: 'numbered', content: [
        {
          text:
            "Since it's rich text, you can do things like turn a selection of text ",
        },
        
      ] },
      
      next: "L1-6-2",
      firstChild: null,
    },
    "L1-6-2": {
      id: "L1-6-2",
      type: BlockType.ListBlock,
      data: { type: 'numbered', content: [
        {
          text:
            "Since it's rich text, you can do things like turn a selection of text ",
        },
        
      ] },
      
      next: "L1-6-3",
      firstChild: null,
    },

    "L1-6-3": {
      id: "L1-6-3",
      type: BlockType.TextBlock,
      data: { content: [{ text: 'A wise quote.' }] },
      next: null,
      firstChild: null,
    },
    
    "L1-7": {
      id: "L1-7",
      type: BlockType.ListBlock,
      data: { type: 'column' },
      
      next: "L1-8",
      firstChild: "L1-7-1",
    },
    "L1-7-1": {
      id: "L1-7-1",
      type: BlockType.ColumnBlock,
      data: { ratio: '0.33' },
      next: "L1-7-2",
      firstChild: "L1-7-1-1",
    },
    "L1-7-1-1": {
      id: "L1-7-1-1",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: null,
      firstChild: null,
    },
    "L1-7-2": {
      id: "L1-7-2",
      type: BlockType.ColumnBlock,
      data: { ratio: '0.33' },
      next: "L1-7-3",
      firstChild: "L1-7-2-1",
    },
    "L1-7-2-1": {
      id: "L1-7-2-1",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: "L1-7-2-2",
      firstChild: null,
    },
    "L1-7-2-2": {
      id: "L1-7-2-2",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: null,
      firstChild: null,
    },
    "L1-7-3": {
      id: "L1-7-3",
      type: BlockType.ColumnBlock,
      data: { ratio: '0.33' },
      next: null,
      firstChild: "L1-7-3-1",
    },
    "L1-7-3-1": {
      id: "L1-7-3-1",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: null,
      firstChild: null,
    },
  }
}


describe("test tree", () => {
  test('blocks to tree', async () => {
    const id = "test-1";
    const blocksData = await loadBlockData(id);
    const getBlock = (blockId: string) => blocksData[blockId];
    const tree = new DOMTree(getBlock);
    const root = tree.blocksToTree(id);
    expect(root).not.toEqual(null);
    expect(root!.id).toEqual(id);
    expect(root!.children.length).toEqual(7);
  });
})
