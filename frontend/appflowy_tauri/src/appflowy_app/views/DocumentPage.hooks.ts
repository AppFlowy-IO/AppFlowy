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
      
      next: null,
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
