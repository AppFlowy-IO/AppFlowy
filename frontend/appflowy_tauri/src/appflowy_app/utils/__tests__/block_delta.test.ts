import { BlockDeltaOperator } from '$app/utils/document/block_delta';
import { mockDocument } from './document_state';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { generateId } from '$app/utils/document/block';

jest.mock('nanoid', () => ({ nanoid: jest.fn().mockReturnValue(String(Math.random())) }));

jest.mock('$app/utils/document/emoji', () => ({
  randomEmoji: jest.fn().mockReturnValue('👍'),
}));

jest.mock('$app/stores/effects/document/document_observer', () => ({
  DocumentObserver: jest.fn().mockImplementation(() => ({
    subscribe: jest.fn().mockReturnValue(Promise.resolve()),
  })),
}));

jest.mock('$app/stores/effects/document/document_bd_svc', () => ({
  DocumentBackendService: jest.fn().mockImplementation(() => ({
    open: jest.fn().mockReturnValue(Promise.resolve({ ok: true, val: mockDocument })),
    applyActions: jest.fn().mockReturnValue(Promise.resolve({ ok: true })),
    createText: jest.fn().mockReturnValue(Promise.resolve({ ok: true })),
    applyTextDelta: jest.fn().mockReturnValue(Promise.resolve({ ok: true })),
    close: jest.fn().mockReturnValue(Promise.resolve({ ok: true })),
    canUndoRedo: jest.fn().mockReturnValue(Promise.resolve({ ok: true })),
    undo: jest.fn().mockReturnValue(Promise.resolve({ ok: true })),
  })),
}));

describe('Test BlockDeltaOperator', () => {
  let operator: BlockDeltaOperator;
  let controller: DocumentController;
  beforeEach(() => {
    controller = new DocumentController(generateId());
    operator = new BlockDeltaOperator(mockDocument, controller);
  });
  test('get block', () => {
    const block = operator.getBlock('1');
    expect(block).toEqual(undefined);

    const blockId = Object.keys(mockDocument.nodes)[0];
    const block2 = operator.getBlock(blockId);
    expect(block2).toEqual(mockDocument.nodes[blockId]);
  });

  test('get delta with block id', () => {
    const blockId = 'gtYcSzwLYw';
    const delta = operator.getDeltaWithBlockId(blockId);
    expect(delta).toBeTruthy();
    const deltaStr = JSON.stringify(delta!.ops);
    const externalId = mockDocument.nodes[blockId].externalId;
    expect(externalId).toBeTruthy();
    expect(deltaStr).toEqual(mockDocument.deltaMap[externalId!]);
  });

  test('get delta text', () => {
    const blockId = 'gtYcSzwLYw';
    const delta = operator.getDeltaWithBlockId(blockId);
    expect(delta).toBeTruthy();
    const text = operator.getDeltaText(delta!);
    expect(text).toEqual('Welcome to AppFlowy!');
  });

  test('get split delta', () => {
    const blockId = 'gtYcSzwLYw';
    const splitDeltaResult = operator.getSplitDelta(blockId, 7, 4);
    expect(splitDeltaResult).toBeTruthy();
    const { updateDelta, diff, insertDelta } = splitDeltaResult!;
    expect(updateDelta).toBeTruthy();
    expect(diff).toBeTruthy();
    expect(insertDelta).toBeTruthy();
    expect(updateDelta.ops).toEqual([{ insert: 'Welcome' }]);
    expect(diff.ops).toEqual([{ retain: 7 }, { delete: 13 }]);
    expect(insertDelta.ops).toEqual([{ insert: 'AppFlowy!' }]);

    const blockId1 = 'wh475aelU_';
    const splitDeltaResult1 = operator.getSplitDelta(blockId1, 14, 0);
    expect(splitDeltaResult1).toBeTruthy();
    const { updateDelta: updateDelta1, diff: diff1, insertDelta: insertDelta1 } = splitDeltaResult1!;
    expect(updateDelta1).toBeTruthy();
    expect(diff1).toBeTruthy();
    expect(insertDelta1).toBeTruthy();
    expect(updateDelta1.ops).toEqual([
      { insert: 'Markdown ' },
      { insert: 'refer', attributes: { href: 'https://appflowy.gitbook.io/docs/essential-documentation/markdown' } },
    ]);
    expect(diff1.ops).toEqual([{ retain: 14 }, { delete: 4 }]);
    expect(insertDelta1.ops).toEqual([
      { insert: 'ence', attributes: { href: 'https://appflowy.gitbook.io/docs/essential-documentation/markdown' } },
    ]);
  });

  test('split a line text', async () => {
    const startId = 'gtYcSzwLYw';
    const endId = 'gtYcSzwLYw';
    const index = 7;
    await operator.splitText(
      {
        id: startId,
        index,
      },
      {
        id: endId,
        index,
      }
    );
    const backendService = controller.backend;
    expect(backendService.applyActions).toBeCalledTimes(1);
    // @ts-ignore
    const actions = backendService.applyActions.mock.calls[0][0];
    expect(actions).toBeTruthy();
    expect(actions.length).toEqual(3);
    expect(actions[0].action).toEqual(5);
    expect(actions[0].payload).toEqual({
      block: {
        id: 'gtYcSzwLYw',
        ty: 'heading',
        children_id: 'WhIA288H8O',
        data: '{"level":1}',
        external_id: 'KbkL-wXQrN',
        external_type: 'text',
        parent_id: 'ifF_PvQeOu',
      },
      delta: '[{"retain":7},{"delete":13}]',
      parent_id: 'ifF_PvQeOu',
      prev_id: '',
      text_id: 'KbkL-wXQrN',
    });
    expect(actions[1].action).toEqual(4);
    expect(actions[1].payload).toHaveProperty('block');
    expect(actions[1].payload.block.parent_id).toEqual('ifF_PvQeOu');
    expect(actions[1].payload.block.ty).toEqual('paragraph');
    expect(actions[1].payload.block).toHaveProperty('external_id');
    expect(actions[1].payload.block.external_id).toBeTruthy();
    expect(actions[1].payload.delta).toEqual('[{"insert":" to AppFlowy!"}]');
    expect(actions[1].payload.parent_id).toEqual('ifF_PvQeOu');
    expect(actions[1].payload.prev_id).toEqual('gtYcSzwLYw');
    expect(actions[1].payload.text_id).toEqual(actions[1].payload.block.external_id);
    expect(actions[2].action).toEqual(0);
    expect(actions[2].payload).toHaveProperty('block');
    expect(actions[2].payload.block.parent_id).toEqual('ifF_PvQeOu');
    expect(actions[2].payload.block.ty).toEqual('paragraph');
    expect(actions[2].payload.block).toHaveProperty('external_id');
    expect(actions[2].payload.block.external_id).toBeTruthy();
    expect(actions[2].payload.parent_id).toEqual('ifF_PvQeOu');
    expect(actions[2].payload.prev_id).toEqual('gtYcSzwLYw');
  });

  test('split multi line text', async () => {
    const startId = 'pYV_AGVqEE';
    const endId = 'eqf0luv-Fy';
    const startIndex = 8;
    const endIndex = 5;
    await operator.splitText(
      {
        id: startId,
        index: startIndex,
      },
      {
        id: endId,
        index: endIndex,
      }
    );
    const backendService = controller.backend;
    expect(backendService.applyActions).toBeCalledTimes(1);
    // @ts-ignore
    const actions = backendService.applyActions.mock.calls[0][0];
    expect(actions).toBeTruthy();
    expect(actions.length).toEqual(6);
    expect(actions[0].action).toEqual(5);
    expect(actions[0].payload.parent_id).toEqual('ifF_PvQeOu');
    expect(actions[0].payload.prev_id).toEqual('');
    expect(actions[0].payload.text_id).toEqual('F3zvDsXHha');
    expect(actions[0].payload.delta).toEqual('[{"retain":8},{"delete":87}]');
    expect(actions[1].action).toEqual(2);
    expect(actions[1].payload.parent_id).toEqual('ifF_PvQeOu');
    expect(actions[1].payload.prev_id).toEqual('');
    expect(actions[2].action).toEqual(2);
    expect(actions[2].payload.parent_id).toEqual('ifF_PvQeOu');
    expect(actions[2].payload.prev_id).toEqual('');
    expect(actions[3].action).toEqual(4);
    expect(actions[3].payload.parent_id).toEqual('ifF_PvQeOu');
    expect(actions[3].payload.prev_id).toEqual('pYV_AGVqEE');
    expect(actions[3].payload.delta).toEqual(
      '[{"insert":" "},{"attributes":{"code":true},"insert":"+"},{"insert":" next to any page title in the sidebar to "},{"attributes":{"font_color":"0xff8427e0"},"insert":"quickly"},{"insert":" add a new subpage, "},{"attributes":{"code":true},"insert":"Document"},{"attributes":{"code":false},"insert":", "},{"attributes":{"code":true},"insert":"Grid"},{"attributes":{"code":false},"insert":", or "},{"attributes":{"code":true},"insert":"Kanban Board"},{"attributes":{"code":false},"insert":"."}]'
    );
    expect(actions[4].action).toEqual(0);
    expect(actions[4].payload.parent_id).toEqual('ifF_PvQeOu');
    expect(actions[4].payload.prev_id).toEqual('pYV_AGVqEE');
    expect(actions[5].action).toEqual(2);
    expect(actions[5].payload.parent_id).toEqual('ifF_PvQeOu');
    expect(actions[5].payload.prev_id).toEqual('');
  });

  test('delete a line text', async () => {
    const startId = 'gtYcSzwLYw';
    const endId = 'gtYcSzwLYw';
    await operator.deleteText(
      {
        id: startId,
        index: 7,
      },
      {
        id: endId,
        index: 8,
      }
    );
    const backendService = controller.backend;
    expect(backendService.applyActions).toBeCalledTimes(1);
    // @ts-ignore
    const actions = backendService.applyActions.mock.calls[0][0];
    expect(actions).toBeTruthy();
    expect(actions.length).toEqual(1);
    expect(actions[0].action).toEqual(5);
    expect(actions[0].payload).toEqual({
      block: {
        id: 'gtYcSzwLYw',
        ty: 'heading',
        children_id: 'WhIA288H8O',
        data: '{"level":1}',
        external_id: 'KbkL-wXQrN',
        external_type: 'text',
        parent_id: 'ifF_PvQeOu',
      },
      delta: '[{"retain":7},{"delete":1}]',
      parent_id: 'ifF_PvQeOu',
      prev_id: '',
      text_id: 'KbkL-wXQrN',
    });
  });

  test('delete multi line text', async () => {
    const startId = 'pYV_AGVqEE';
    const endId = 'eqf0luv-Fy';
    const startIndex = 8;
    const endIndex = 5;
    await operator.splitText(
      {
        id: startId,
        index: startIndex,
      },
      {
        id: endId,
        index: endIndex,
      }
    );
    const backendService = controller.backend;
    expect(backendService.applyActions).toBeCalledTimes(1);
    // @ts-ignore
    const actions = backendService.applyActions.mock.calls[0][0];
    expect(actions).toBeTruthy();
    expect(actions.length).toEqual(6);
    expect(actions[0].action).toEqual(5);
    expect(actions[0].payload.parent_id).toEqual('ifF_PvQeOu');
    expect(actions[0].payload.prev_id).toEqual('');
    expect(actions[0].payload.text_id).toEqual('F3zvDsXHha');
    expect(actions[0].payload.delta).toEqual('[{"retain":8},{"delete":87}]');
    expect(actions[1].action).toEqual(2);
    expect(actions[1].payload.parent_id).toEqual('ifF_PvQeOu');
    expect(actions[1].payload.prev_id).toEqual('');
    expect(actions[2].action).toEqual(2);
    expect(actions[2].payload.parent_id).toEqual('ifF_PvQeOu');
    expect(actions[2].payload.prev_id).toEqual('');
    expect(actions[3].action).toEqual(4);
    expect(actions[3].payload.parent_id).toEqual('ifF_PvQeOu');
    expect(actions[3].payload.prev_id).toEqual('pYV_AGVqEE');
    expect(actions[3].payload.delta).toEqual(
      '[{"insert":" "},{"attributes":{"code":true},"insert":"+"},{"insert":" next to any page title in the sidebar to "},{"attributes":{"font_color":"0xff8427e0"},"insert":"quickly"},{"insert":" add a new subpage, "},{"attributes":{"code":true},"insert":"Document"},{"attributes":{"code":false},"insert":", "},{"attributes":{"code":true},"insert":"Grid"},{"attributes":{"code":false},"insert":", or "},{"attributes":{"code":true},"insert":"Kanban Board"},{"attributes":{"code":false},"insert":"."}]'
    );
    expect(actions[4].action).toEqual(0);
    expect(actions[4].payload.parent_id).toEqual('ifF_PvQeOu');
    expect(actions[4].payload.prev_id).toEqual('pYV_AGVqEE');
    expect(actions[5].action).toEqual(2);
    expect(actions[5].payload.parent_id).toEqual('ifF_PvQeOu');
    expect(actions[5].payload.prev_id).toEqual('');
  });

  test('merge two line text', async () => {
    const startId = 'gtYcSzwLYw';
    const endId = 'YsJ-DVO-sC';
    await operator.mergeText(startId, endId);
    const backendService = controller.backend;
    expect(backendService.applyActions).toBeCalledTimes(1);
    // @ts-ignore
    const actions = backendService.applyActions.mock.calls[0][0];
    expect(actions).toBeTruthy();
    expect(actions.length).toEqual(2);
    expect(actions[0].action).toEqual(5);
    expect(actions[0].payload).toEqual({
      block: {
        id: 'gtYcSzwLYw',
        ty: 'heading',
        children_id: 'WhIA288H8O',
        data: '{"level":1}',
        external_id: 'KbkL-wXQrN',
        external_type: 'text',
        parent_id: 'ifF_PvQeOu',
      },
      delta: '[{"retain":20},{"insert":"Here are the basics"}]',
      parent_id: 'ifF_PvQeOu',
      prev_id: '',
      text_id: 'KbkL-wXQrN',
    });
    expect(actions[1].action).toEqual(2);
    expect(actions[1].payload).toEqual({
      block: {
        id: 'YsJ-DVO-sC',
        ty: 'heading',
        parent_id: 'ifF_PvQeOu',
        children_id: 'PM5MctaruD',
        data: '{"level":2}',
        external_id: 'QHPzz4O1mV',
        external_type: 'text',
      },
      parent_id: 'ifF_PvQeOu',
      prev_id: '',
    });
  });
});

export {};
