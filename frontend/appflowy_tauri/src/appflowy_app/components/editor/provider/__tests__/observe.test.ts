import { applyActions } from './utils/mockBackendService';

import { Provider } from '$app/components/editor/provider';
import { generateId } from '$app/components/editor/provider/utils/convert';
import { generateInsertTextOp } from '$app/components/editor/provider/__tests__/utils/convert';

export {};

describe('Provider connected', () => {
  let provider: Provider;

  beforeEach(() => {
    provider = new Provider(generateId());
    provider.initialDocument(true);
    provider.connect();
    applyActions.mockClear();
  });

  afterEach(() => {
    provider.disconnect();
  });

  test('should initial document', () => {
    const sharedType = provider.sharedType;
    expect(sharedType).not.toBeNull();
    expect(sharedType?.length).toBe(25);
    expect(sharedType?.getAttribute('blockId')).toBe('3EzeCrtxlh');
  });

  test('should send actions when the local changed', () => {
    const sharedType = provider.sharedType;

    const parentId = sharedType?.getAttribute('blockId') as string;
    const insertTextOp = generateInsertTextOp('');

    sharedType?.applyDelta([{ retain: 2 }, insertTextOp]);

    expect(sharedType?.length).toBe(26);
    expect(applyActions).toBeCalledTimes(1);
  });
});

export {};
