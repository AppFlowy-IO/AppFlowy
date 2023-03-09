import { useEffect, useState } from 'react';
import {
  DocumentEventGetDocument,
  DocumentVersionPB,
  OpenDocumentPayloadPB,
} from '../../services/backend/events/flowy-document';
import { Block, BlockType } from '../interfaces';
import { useParams } from 'react-router-dom';
import { setDocumentBlocksMap } from '../utils/block_context';

export const useDocument = () => {
  const params = useParams();
  const [blockId, setBlockId] = useState<string>();
  const loadDocument = async (id: string): Promise<any> => {
    const getDocumentResult = await DocumentEventGetDocument(
      OpenDocumentPayloadPB.fromObject({
        document_id: id,
        version: DocumentVersionPB.V1,
      })
    );

    if (getDocumentResult.ok) {
      const pb = getDocumentResult.val;
      return JSON.parse(pb.content);
    } else {
      throw new Error('get document error');
    }
  };

  const loadBlockData = async (id: string): Promise<Record<string, Block>> => {
    return {
      [id]: {
        id: id,
        type: BlockType.PageBlock,
        data: { title: 'Document Title' },
        parent: null,
        next: null,
        prev: null,
        firstChild: "A",
        lastChild: "E"
      },
      "A": {
        id: "A",
        type: BlockType.HeadingBlock,
        data: { level: 1, content: [{ text: 'Heading 1' }] },
        parent: id,
        prev: null,
        next: "B",
        firstChild: null,
        lastChild: null,
      },
      "B": {
        id: "B",
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
        parent: id,
        prev: "A",
        next: "C",
        firstChild: null,
        lastChild: null,
      },
      "C": {
        id: "C",
        type: BlockType.TextBlock,
        data: { content: [
          { text: 'Try it out yourself! Just ' },
          { text: 'select any piece of text and the menu will appear', bold: true },
          { text: '.' },
        ] },
        prev: null,
        parent: id,
        next: "D",
        firstChild: "F",
        lastChild: null,
      },
      "D": {
        id: "D",
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
        prev: "C",
        parent: id,
        next: null,
        firstChild: "D-1",
        lastChild: "H",
      },
      "D-1": {
        id: "D-1",
        type: BlockType.ListBlock,
        data: { type: 'numbered', content: [
          {
            text:
              "Since it's rich text, you can do things like turn a selection of text ",
          },
          
        ] },
        prev: null,
        parent: "D",
        next: "D-2",
        firstChild: null,
        lastChild: null,
      },
      "D-2": {
        id: "D-2",
        type: BlockType.ListBlock,
        data: { type: 'numbered', content: [
          {
            text:
              "Since it's rich text, you can do things like turn a selection of text ",
          },
          
        ] },
        prev: "D-1",
        parent: "D",
        next: "G",
        firstChild: null,
        lastChild: null,
      },

      "E": {
        id: "E",
        type: BlockType.TextBlock,
        data: { content: [{ text: 'A wise quote.' }] },
        prev: "D",
        parent: id,
        next: null,
        firstChild: null,
        lastChild: null,
      },
      "F": {
        id: "F",
        type: BlockType.TextBlock,
        data: { content: [{ text: 'Try it out for yourself!' }] },
        prev: null,
        parent: "C",
        next: null,
        firstChild: null,
        lastChild: null,
      },
      "G": {
        id: "G",
        type: BlockType.ListBlock,
        data: { type: 'bulleted', content: [{ text: 'Item 1' }] },
        prev: "D-2",
        parent: "D",
        next: "H",
        firstChild: null,
        lastChild: null,
      },
      "H": {
        id: "H",
        type: BlockType.TextBlock,
        data: { content: [{ text: 'Item 2' }] },
        prev: "G",
        parent: "D",
        next: "I",
        firstChild: null,
        lastChild: null,
      },
      "I": {
        id: "I",
        type: BlockType.HeadingBlock,
        data: { level: 2, content: [{ text: 'Heading 2' }] },
        parent: id,
        prev: "H",
        next: 'L',
        firstChild: null,
        lastChild: null,
      },
      "L": {
        id: "L",
        type: BlockType.TextBlock,
        data: { content: [{ text: 'Try it out for yourself!' }] },
        parent: id,
        prev: "I",
        next: 'J',
        firstChild: null,
        lastChild: null,
      },
      "J": {
        id: "J",
        type: BlockType.HeadingBlock,
        data: { level: 3, content: [{ text: 'Heading 3' }] },
        parent: id,
        prev: "L",
        next: "K",
        firstChild: null,
        lastChild: null,
      },
      "K": {
        id: "K",
        type: BlockType.TextBlock,
        data: { content: [{ text: 'Try it out for yourself!' }] },
        parent: id,
        prev: "J",
        next: "M",
        firstChild: null,
        lastChild: null,
      },
      "M": {
        id: "M",
        type: BlockType.ListBlock,
        data: { type: 'column' },
        parent: id,
        prev: "K",
        next: null,
        firstChild: "N",
        lastChild: "P"
      },
      "N": {
        id: "N",
        type: BlockType.ColumnBlock,
        data: { ratio: '0.33' },
        parent: "M",
        prev: null,
        next: "O",
        firstChild: "N-1",
        lastChild: "N-2",
      },
      "O": {
        id: "O",
        type: BlockType.ColumnBlock,
        data: { ratio: '0.33' },
        parent: "M",
        prev: "N",
        next: "P",
        firstChild: "O-1",
        lastChild: null,
      },
      "P": {
        id: "P",
        type: BlockType.ColumnBlock,
        data: { ratio: '0.33' },
        parent: "M",
        prev: "O",
        next: null,
        firstChild: "P-1",
        lastChild: "P-2",
      },
      "N-1": {
        id: "N-1",
        type: BlockType.TextBlock,
        data: { content: [{ text: 'Column-1-Row-1' }] },
        parent: "N",
        prev: null,
        next: "N-2",
        firstChild: null,
        lastChild: null
      },
      "N-2": {
        id: "N-2",
        type: BlockType.TextBlock,
        data: { content: [{ text: 'Column-1-Row-2' }] },
        parent: "N",
        prev: "N-1",
        next: null,
        firstChild: null,
        lastChild: null
      },
      "O-1": {
        id: "O-1",
        type: BlockType.TextBlock,
        data: { content: [{ text: 'Column-2-Row-1' }] },
        parent: "O",
        prev: null,
        next: null,
        firstChild: null,
        lastChild: null
      },
      "P-1": {
        id: "P-1",
        type: BlockType.TextBlock,
        data: { content: [{ text: 'Column-3-Row-1' }] },
        parent: "P",
        prev: null,
        next: "P-2",
        firstChild: null,
        lastChild: null
      },
      "P-2": {
        id: "P-2",
        type: BlockType.TextBlock,
        data: { content: [{ text: 'Column-3-Row-2' }] },
        parent: "P",
        prev: "P-1",
        next: null,
        firstChild: null,
        lastChild: null
      }
    }
  }

  useEffect(() => {
    void (async () => {
      if (!params?.id) return;
      const data = await loadBlockData(params.id);
      console.log(data);
      setDocumentBlocksMap(params.id, data);
      setBlockId(params.id)
    })();
  }, [params]);
  return { blockId };
};
