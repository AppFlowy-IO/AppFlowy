import { useEffect, useRef, useState } from 'react';
import {
  DocumentEventGetDocument,
  DocumentVersionPB,
  OpenDocumentPayloadPB,
} from '../../services/backend/events/flowy-document';
import { BlockInterface, BlockType } from '../interfaces';
import { useParams } from 'react-router-dom';
import { BlockEditor } from '../block_editor';

const loadBlockData = async (id: string): Promise<Record<string, BlockInterface>> => {
  return {
    [id]: {
      id: id,
      type: BlockType.PageBlock,
      data: { content: [{ text: 'Document Title' }] },
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
    "L1-8": {
      id: "L1-8",
      type: BlockType.HeadingBlock,
      data: { level: 1, content: [{ text: 'Heading 1' }] },
      next: "L1-9",
      firstChild: null,
    },
    "L1-9": {
      id: "L1-9",
      type: BlockType.HeadingBlock,
      data: { level: 2, content: [{ text: 'Heading 2' }] },
      next: "L1-10",
      firstChild: null,
    },
    "L1-10": {
      id: "L1-10",
      type: BlockType.HeadingBlock,
      data: { level: 3, content: [{ text: 'Heading 3' }] },
      next: "L1-11",
      firstChild: null,
    },
    "L1-11": {
      id: "L1-11",
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
      next: "L1-12",
      firstChild: null,
    },
    "L1-12": {
      id: "L1-12",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
        { text: 'select any piece of text and the menu will appear', bold: true },
        { text: '.' },
      ] },
      next: "L2-1",
      firstChild: "L1-12-1",
    },
    "L1-12-1": {
      id: "L1-12-1",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: "L1-12-2",
      firstChild: null,
    },
    "L1-12-2": {
      id: "L1-12-2",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: null,
      firstChild: null,
    },
    "L2-1": {
      id: "L2-1",
      type: BlockType.HeadingBlock,
      data: { level: 1, content: [{ text: 'Heading 1' }] },
      next: "L2-2",
      firstChild: null,
    },
    "L2-2": {
      id: "L2-2",
      type: BlockType.HeadingBlock,
      data: { level: 2, content: [{ text: 'Heading 2' }] },
      next: "L2-3",
      firstChild: null,
    },
    "L2-3": {
      id: "L2-3",
      type: BlockType.HeadingBlock,
      data: { level: 3, content: [{ text: 'Heading 3' }] },
      next: "L2-4",
      firstChild: null,
    },
    "L2-4": {
      id: "L2-4",
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
      next: "L2-5",
      firstChild: null,
    },
    "L2-5": {
      id: "L2-5",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
        { text: 'select any piece of text and the menu will appear', bold: true },
        { text: '.' },
      ] },
      next: "L2-6",
      firstChild: "L2-5-1",
    },
    "L2-5-1": {
      id: "L2-5-1",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: "L2-5-2",
      firstChild: null,
    },
    "L2-5-2": {
      id: "L2-5-2",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: null,
      firstChild: null,
    },
    "L2-6": {
      id: "L2-6",
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
      next: "L2-7",
      firstChild: "L2-6-1",
    },
    "L2-6-1": {
      id: "L2-6-1",
      type: BlockType.ListBlock,
      data: { type: 'numbered', content: [
        {
          text:
            "Since it's rich text, you can do things like turn a selection of text ",
        },
        
      ] },
      
      next: "L2-6-2",
      firstChild: null,
    },
    "L2-6-2": {
      id: "L2-6-2",
      type: BlockType.ListBlock,
      data: { type: 'numbered', content: [
        {
          text:
            "Since it's rich text, you can do things like turn a selection of text ",
        },
        
      ] },
      
      next: "L2-6-3",
      firstChild: null,
    },

    "L2-6-3": {
      id: "L2-6-3",
      type: BlockType.TextBlock,
      data: { content: [{ text: 'A wise quote.' }] },
      next: null,
      firstChild: null,
    },
    
    "L2-7": {
      id: "L2-7",
      type: BlockType.ListBlock,
      data: { type: 'column' },
      
      next: "L2-8",
      firstChild: "L2-7-1",
    },
    "L2-7-1": {
      id: "L2-7-1",
      type: BlockType.ColumnBlock,
      data: { ratio: '0.33' },
      next: "L2-7-2",
      firstChild: "L2-7-1-1",
    },
    "L2-7-1-1": {
      id: "L2-7-1-1",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: null,
      firstChild: null,
    },
    "L2-7-2": {
      id: "L2-7-2",
      type: BlockType.ColumnBlock,
      data: { ratio: '0.33' },
      next: "L2-7-3",
      firstChild: "L2-7-2-1",
    },
    "L2-7-2-1": {
      id: "L2-7-2-1",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: "L2-7-2-2",
      firstChild: null,
    },
    "L2-7-2-2": {
      id: "L2-7-2-2",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: null,
      firstChild: null,
    },
    "L2-7-3": {
      id: "L2-7-3",
      type: BlockType.ColumnBlock,
      data: { ratio: '0.33' },
      next: null,
      firstChild: "L2-7-3-1",
    },
    "L2-7-3-1": {
      id: "L2-7-3-1",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: null,
      firstChild: null,
    },
    "L2-8": {
      id: "L2-8",
      type: BlockType.HeadingBlock,
      data: { level: 1, content: [{ text: 'Heading 1' }] },
      next: "L2-9",
      firstChild: null,
    },
    "L2-9": {
      id: "L2-9",
      type: BlockType.HeadingBlock,
      data: { level: 2, content: [{ text: 'Heading 2' }] },
      next: "L2-10",
      firstChild: null,
    },
    "L2-10": {
      id: "L2-10",
      type: BlockType.HeadingBlock,
      data: { level: 3, content: [{ text: 'Heading 3' }] },
      next: "L2-11",
      firstChild: null,
    },
    "L2-11": {
      id: "L2-11",
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
      next: "L2-12",
      firstChild: null,
    },
    "L2-12": {
      id: "L2-12",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
        { text: 'select any piece of text and the menu will appear', bold: true },
        { text: '.' },
      ] },
      next: "L3-1",
      firstChild: "L2-12-1",
    },
    "L2-12-1": {
      id: "L2-12-1",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: "L2-12-2",
      firstChild: null,
    },
    "L2-12-2": {
      id: "L2-12-2",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: null,
      firstChild: null,
    },"L3-1": {
      id: "L3-1",
      type: BlockType.HeadingBlock,
      data: { level: 1, content: [{ text: 'Heading 1' }] },
      next: "L3-2",
      firstChild: null,
    },
    "L3-2": {
      id: "L3-2",
      type: BlockType.HeadingBlock,
      data: { level: 2, content: [{ text: 'Heading 2' }] },
      next: "L3-3",
      firstChild: null,
    },
    "L3-3": {
      id: "L3-3",
      type: BlockType.HeadingBlock,
      data: { level: 3, content: [{ text: 'Heading 3' }] },
      next: "L3-4",
      firstChild: null,
    },
    "L3-4": {
      id: "L3-4",
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
      next: "L3-5",
      firstChild: null,
    },
    "L3-5": {
      id: "L3-5",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
        { text: 'select any piece of text and the menu will appear', bold: true },
        { text: '.' },
      ] },
      next: "L3-6",
      firstChild: "L3-5-1",
    },
    "L3-5-1": {
      id: "L3-5-1",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: "L3-5-2",
      firstChild: null,
    },
    "L3-5-2": {
      id: "L3-5-2",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: null,
      firstChild: null,
    },
    "L3-6": {
      id: "L3-6",
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
      next: "L3-7",
      firstChild: "L3-6-1",
    },
    "L3-6-1": {
      id: "L3-6-1",
      type: BlockType.ListBlock,
      data: { type: 'numbered', content: [
        {
          text:
            "Since it's rich text, you can do things like turn a selection of text ",
        },
        
      ] },
      
      next: "L3-6-2",
      firstChild: null,
    },
    "L3-6-2": {
      id: "L3-6-2",
      type: BlockType.ListBlock,
      data: { type: 'numbered', content: [
        {
          text:
            "Since it's rich text, you can do things like turn a selection of text ",
        },
        
      ] },
      
      next: "L3-6-3",
      firstChild: null,
    },
    
    "L3-6-3": {
      id: "L3-6-3",
      type: BlockType.TextBlock,
      data: { content: [{ text: 'A wise quote.' }] },
      next: null,
      firstChild: null,
    },
    
    "L3-7": {
      id: "L3-7",
      type: BlockType.ListBlock,
      data: { type: 'column' },
      
      next: "L3-8",
      firstChild: "L3-7-1",
    },
    "L3-7-1": {
      id: "L3-7-1",
      type: BlockType.ColumnBlock,
      data: { ratio: '0.33' },
      next: "L3-7-2",
      firstChild: "L3-7-1-1",
    },
    "L3-7-1-1": {
      id: "L3-7-1-1",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: null,
      firstChild: null,
    },
    "L3-7-2": {
      id: "L3-7-2",
      type: BlockType.ColumnBlock,
      data: { ratio: '0.33' },
      next: "L3-7-3",
      firstChild: "L3-7-2-1",
    },
    "L3-7-2-1": {
      id: "L3-7-2-1",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: "L3-7-2-2",
      firstChild: null,
    },
    "L3-7-2-2": {
      id: "L3-7-2-2",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: null,
      firstChild: null,
    },
    "L3-7-3": {
      id: "L3-7-3",
      type: BlockType.ColumnBlock,
      data: { ratio: '0.33' },
      next: null,
      firstChild: "L3-7-3-1",
    },
    "L3-7-3-1": {
      id: "L3-7-3-1",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: null,
      firstChild: null,
    },
    "L3-8": {
      id: "L3-8",
      type: BlockType.HeadingBlock,
      data: { level: 1, content: [{ text: 'Heading 1' }] },
      next: "L3-9",
      firstChild: null,
    },
    "L3-9": {
      id: "L3-9",
      type: BlockType.HeadingBlock,
      data: { level: 2, content: [{ text: 'Heading 2' }] },
      next: "L3-10",
      firstChild: null,
    },
    "L3-10": {
      id: "L3-10",
      type: BlockType.HeadingBlock,
      data: { level: 3, content: [{ text: 'Heading 3' }] },
      next: "L3-11",
      firstChild: null,
    },
    "L3-11": {
      id: "L3-11",
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
      next: "L3-12",
      firstChild: null,
    },
    "L3-12": {
      id: "L3-12",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
        { text: 'select any piece of text and the menu will appear', bold: true },
        { text: '.' },
      ] },
      next: null,
      firstChild: "L3-12-1",
    },
    "L3-12-1": {
      id: "L3-12-1",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: "L3-12-2",
      firstChild: null,
    },
    "L3-12-2": {
      id: "L3-12-2",
      type: BlockType.TextBlock,
      data: { content: [
        { text: 'Try it out yourself! Just ' },
      ] },
      next: null,
      firstChild: null,
    },
  }
}
export const useDocument = () => {
  const params = useParams();
  const [blockId, setBlockId] = useState<string>();
  const blockEditorRef = useRef<BlockEditor | null>(null)


  useEffect(() => {
    void (async () => {
      if (!params?.id) return;
      const data = await loadBlockData(params.id);
      console.log('==== enter ====', params?.id, data);
  
      if (!blockEditorRef.current) {
        blockEditorRef.current = new BlockEditor(params?.id, data);
      } else {
        blockEditorRef.current.changeDoc(params?.id, data);
      }

      setBlockId(params.id)
    })();
    return () => {
      console.log('==== leave ====', params?.id)
    }
  }, [params.id]);
  return { blockId, blockEditor: blockEditorRef.current };
};
