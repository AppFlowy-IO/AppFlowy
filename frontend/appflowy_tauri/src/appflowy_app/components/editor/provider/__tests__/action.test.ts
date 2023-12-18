import { applyActions } from './utils/mockBackendService';
import { generateId } from '$app/components/editor/provider/utils/convert';
import { Provider } from '$app/components/editor/provider';
import * as Y from 'yjs';
import { BlockActionTypePB } from '@/services/backend';
import {
  generateFormulaInsertTextOp,
  generateInsertTextOp,
  genersteMentionInsertTextOp,
} from '$app/components/editor/provider/__tests__/utils/convert';

describe('Transform events to actions', () => {
  let provider: Provider;
  beforeEach(() => {
    provider = new Provider(generateId());
    provider.connect();
    applyActions.mockClear();
  });

  afterEach(() => {
    provider.disconnect();
  });

  test('should transform insert event to insert action', () => {
    const sharedType = provider.sharedType;

    const parentId = sharedType?.getAttribute('blockId') as string;
    const insertTextOp = generateInsertTextOp('insert text', parentId, 1);

    sharedType?.applyDelta([{ retain: 1 }, insertTextOp]);

    const actions = applyActions.mock.calls[0][1];
    expect(actions).toHaveLength(2);
    const textId = actions[0].payload.text_id;
    expect(actions[0].action).toBe(BlockActionTypePB.InsertText);
    expect(actions[0].payload.delta).toBe('[{"insert":"insert text"}]');
    expect(actions[1].action).toBe(BlockActionTypePB.Insert);
    expect(actions[1].payload.block.ty).toBe('paragraph');
    expect(actions[1].payload.block.parent_id).toBe('3EzeCrtxlh');
    expect(actions[1].payload.block.children_id).not.toBeNull();
    expect(actions[1].payload.block.external_id).toBe(textId);
    expect(actions[1].payload.parent_id).toBe('3EzeCrtxlh');
    expect(actions[1].payload.prev_id).toBe('2qonPRrNTO');
  });

  test('should transform move event to move action', () => {
    const sharedType = provider.sharedType;

    const parentId = 'CxPil0324P';
    const yText = sharedType?.toDelta()[3].insert as Y.XmlText;
    sharedType?.doc?.transact(() => {
      yText.setAttribute('level', 2);
      yText.setAttribute('parentId', parentId);
    });

    const actions = applyActions.mock.calls[0][1];
    expect(actions).toHaveLength(1);
    expect(actions[0].action).toBe(BlockActionTypePB.Move);
    expect(actions[0].payload.block.id).toBe('Fn4KACkt1i');
    expect(actions[0].payload.parent_id).toBe('CxPil0324P');
    expect(actions[0].payload.prev_id).toBe('');
  });

  test('should transform delete event to delete action', () => {
    const sharedType = provider.sharedType;

    sharedType?.doc?.transact(() => {
      sharedType?.applyDelta([{ retain: 3 }, { delete: 1 }]);
    });

    const actions = applyActions.mock.calls[0][1];
    expect(actions).toHaveLength(1);
    expect(actions[0].action).toBe(BlockActionTypePB.Delete);
    expect(actions[0].payload.block.id).toBe('Fn4KACkt1i');
    expect(actions[0].payload.parent_id).toBe('3EzeCrtxlh');
  });

  test('should transform update event to update action', () => {
    const sharedType = provider.sharedType;

    const yText = sharedType?.toDelta()[3].insert as Y.XmlText;
    sharedType?.doc?.transact(() => {
      yText.setAttribute('data', {
        checked: true,
      });
    });

    const actions = applyActions.mock.calls[0][1];
    expect(actions).toHaveLength(1);
    expect(actions[0].action).toBe(BlockActionTypePB.Update);
    expect(actions[0].payload.block.id).toBe('Fn4KACkt1i');
    expect(actions[0].payload.block.data).toBe('{"checked":true}');
    expect(actions[0].payload.parent_id).toBe('3EzeCrtxlh');
  });

  test('should transform apply delta event to apply delta action (insert text)', () => {
    const sharedType = provider.sharedType;

    const yText = sharedType?.toDelta()[3].insert as Y.XmlText;
    sharedType?.doc?.transact(() => {
      yText.applyDelta([{ retain: 1 }, { insert: 'apply delta' }]);
    });
    const textId = yText.getAttribute('textId');

    const actions = applyActions.mock.calls[0][1];
    expect(actions).toHaveLength(1);
    expect(actions[0].action).toBe(BlockActionTypePB.ApplyTextDelta);
    expect(actions[0].payload.text_id).toBe(textId);
    expect(actions[0].payload.delta).toBe('[{"retain":1},{"insert":"apply delta"}]');
  });

  test('should transform apply delta event to apply delta action: insert mention', () => {
    const sharedType = provider.sharedType;

    const yText = sharedType?.toDelta()[3].insert as Y.XmlText;
    sharedType?.doc?.transact(() => {
      yText.applyDelta([{ retain: 1 }, genersteMentionInsertTextOp()]);
    });

    const actions = applyActions.mock.calls[0][1];
    expect(actions).toHaveLength(1);
    expect(actions[0].action).toBe(BlockActionTypePB.ApplyTextDelta);
    expect(actions[0].payload.delta).toBe('[{"retain":1},{"insert":"@","attributes":{"mention":{"page":"page_id"}}}]');
  });

  test('should transform apply delta event to apply delta action: insert formula', () => {
    const sharedType = provider.sharedType;

    const yText = sharedType?.toDelta()[3].insert as Y.XmlText;
    sharedType?.doc?.transact(() => {
      yText.applyDelta([{ retain: 1 }, generateFormulaInsertTextOp()]);
    });

    const actions = applyActions.mock.calls[0][1];
    expect(actions).toHaveLength(1);
    expect(actions[0].action).toBe(BlockActionTypePB.ApplyTextDelta);
    expect(actions[0].payload.delta).toBe('[{"retain":1},{"insert":"= 1 + 1","attributes":{"formula":true}}]');
  });
});

export {};
