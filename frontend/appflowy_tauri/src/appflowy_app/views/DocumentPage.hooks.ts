import { useEffect, useState } from 'react';
import {
  DocumentEventGetDocument,
  DocumentVersionPB,
  OpenDocumentPayloadPB,
} from '../../services/backend/events/flowy-document';
import { Block, BlockType } from '../interfaces';
import { useParams } from 'react-router-dom';

export const useDocument = () => {
  const params = useParams();
  const [blocksMap, setBlocksMap] = useState<Record<string, Block>>();
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

  const loadBlockData = async (blockId: string): Promise<Record<string, Block>> => {
    return {
      [blockId]: {
        id: blockId,
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
        data: { level: 1, text: 'A Heading-1' },
        parent: blockId,
        prev: null,
        next: "B",
        firstChild: null,
        lastChild: null,
      },
      "B": {
        id: "B",
        type: BlockType.TextBlock,
        data: { text: 'Hello', attr: '' },
        parent: blockId,
        prev: "A",
        next: "C",
        firstChild: null,
        lastChild: null,
      },
      "C": {
        id: "C",
        type: BlockType.TextBlock,
        data: { text: 'block c' },
        prev: null,
        parent: blockId,
        next: "D",
        firstChild: "F",
        lastChild: null,
      },
      "D": {
        id: "D",
        type: BlockType.ListBlock,
        data: { type: 'number_list', text: 'D List' },
        prev: "C",
        parent: blockId,
        next: null,
        firstChild: "G",
        lastChild: "H",
      },
      "E": {
        id: "E",
        type: BlockType.TextBlock,
        data: { text: 'World', attr: '' },
        prev: "D",
        parent: blockId,
        next: null,
        firstChild: null,
        lastChild: null,
      },
      "F": {
        id: "F",
        type: BlockType.TextBlock,
        data: { text: 'Heading', attr: '' },
        prev: null,
        parent: "C",
        next: null,
        firstChild: null,
        lastChild: null,
      },
      "G": {
        id: "G",
        type: BlockType.TextBlock,
        data: { text: 'Item 1', attr: '' },
        prev: null,
        parent: "D",
        next: "H",
        firstChild: null,
        lastChild: null,
      },
      "H": {
        id: "H",
        type: BlockType.TextBlock,
        data: { text: 'Item 2', attr: '' },
        prev: "G",
        parent: "D",
        next: "I",
        firstChild: null,
        lastChild: null,
      },
      "I": {
        id: "I",
        type: BlockType.HeadingBlock,
        data: { level: 2, text: 'B Heading-1' },
        parent: blockId,
        prev: "H",
        next: 'L',
        firstChild: null,
        lastChild: null,
      },
      "L": {
        id: "L",
        type: BlockType.TextBlock,
        data: { text: '456' },
        parent: blockId,
        prev: "I",
        next: 'J',
        firstChild: null,
        lastChild: null,
      },
      "J": {
        id: "J",
        type: BlockType.HeadingBlock,
        data: { level: 3, text: 'C Heading-1' },
        parent: blockId,
        prev: "L",
        next: "K",
        firstChild: null,
        lastChild: null,
      },
      "K": {
        id: "K",
        type: BlockType.TextBlock,
        data: { text: '123' },
        parent: blockId,
        prev: "J",
        next: null,
        firstChild: null,
        lastChild: null,
      },
    }
  }

  useEffect(() => {
    void (async () => {
      if (!params?.id) return;
      const data = await loadBlockData(params.id);
      console.log(data);
      setBlocksMap(data);
    })();
  }, [params]);
  return { blocksMap, blockId: params.id };
};
