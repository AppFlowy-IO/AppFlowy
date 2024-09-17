import { Types } from '@/application/types';
import { withTestingYDoc } from '@/application/slate-yjs/__tests__/withTestingYjsEditor';
import { expect } from '@jest/globals';
import { collabTypeToDBType, getPublishView, getPublishViewMeta } from '@/application/services/js-services/cache';
import { openCollabDB, db } from '@/application/db';
import { StrategyType } from '@/application/services/js-services/cache/types';

jest.mock('@/application/ydoc/apply', () => ({
  applyYDoc: jest.fn(),
}));

jest.mock('@/application/db', () => ({
  openCollabDB: jest.fn(),
  db: {
    view_metas: {
      get: jest.fn(),
      put: jest.fn(),
    },
  },
}));

const normalDoc = withTestingYDoc('1');
const mockFetcher = jest.fn();

async function runTestWithStrategy (strategy: StrategyType) {
  return getPublishView(
    mockFetcher,
    {
      namespace: 'appflowy',
      publishName: 'test',
    },
    strategy,
  );
}

async function runGetPublishViewMetaWithStrategy (strategy: StrategyType) {
  return getPublishViewMeta(
    mockFetcher,
    {
      namespace: 'appflowy',
      publishName: 'test',
    },
    strategy,
  );
}

describe('Cache functions', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockFetcher.mockClear();
    (openCollabDB as jest.Mock).mockClear();
  });

  describe('getPublishView', () => {
    it('should call fetcher when no cache found', async () => {
      (openCollabDB as jest.Mock).mockResolvedValue(normalDoc);
      mockFetcher.mockResolvedValue({ data: [1, 2, 3], meta: { metadata: { view: { id: '1' } } } });
      (db.view_metas.get as jest.Mock).mockResolvedValue(undefined);
      await runTestWithStrategy(StrategyType.CACHE_FIRST);
      expect(mockFetcher).toBeCalledTimes(1);

      await runTestWithStrategy(StrategyType.CACHE_AND_NETWORK);
      expect(mockFetcher).toBeCalledTimes(2);
      await expect(runTestWithStrategy(StrategyType.CACHE_ONLY)).rejects.toThrow('No cache found');
    });
    it('should call fetcher when cache is invalid or strategy is CACHE_AND_NETWORK', async () => {
      (openCollabDB as jest.Mock).mockResolvedValue(normalDoc);
      (db.view_metas.get as jest.Mock).mockResolvedValue({ view_id: '1' });
      mockFetcher.mockResolvedValue({ data: [1, 2, 3], meta: { metadata: { view: { id: '1' } } } });
      await runTestWithStrategy(StrategyType.CACHE_ONLY);
      expect(openCollabDB).toBeCalledTimes(1);

      await runTestWithStrategy(StrategyType.CACHE_FIRST);
      expect(openCollabDB).toBeCalledTimes(2);
      expect(mockFetcher).toBeCalledTimes(0);

      await runTestWithStrategy(StrategyType.CACHE_AND_NETWORK);
      expect(openCollabDB).toBeCalledTimes(3);
      expect(mockFetcher).toBeCalledTimes(1);
    });
  });

  describe('getPublishViewMeta', () => {
    it('should call fetcher when no cache found', async () => {
      mockFetcher.mockResolvedValue({ metadata: { view: { id: '1' }, child_views: [], ancestor_views: [] } });
      (db.view_metas.get as jest.Mock).mockResolvedValue(undefined);
      await runGetPublishViewMetaWithStrategy(StrategyType.CACHE_FIRST);
      expect(mockFetcher).toBeCalledTimes(1);

      await runGetPublishViewMetaWithStrategy(StrategyType.CACHE_AND_NETWORK);
      expect(mockFetcher).toBeCalledTimes(2);

      await expect(runGetPublishViewMetaWithStrategy(StrategyType.CACHE_ONLY)).rejects.toThrow('No cache found');
    });

    it('should call fetcher when cache is invalid or strategy is CACHE_AND_NETWORK', async () => {
      (openCollabDB as jest.Mock).mockResolvedValue(normalDoc);
      (db.view_metas.get as jest.Mock).mockResolvedValue({ view_id: '1' });

      mockFetcher.mockResolvedValue({ metadata: { view: { id: '1' }, child_views: [], ancestor_views: [] } });
      const meta = await runGetPublishViewMetaWithStrategy(StrategyType.CACHE_ONLY);
      expect(openCollabDB).toBeCalledTimes(0);
      expect(meta).toBeDefined();

      await runGetPublishViewMetaWithStrategy(StrategyType.CACHE_FIRST);
      expect(openCollabDB).toBeCalledTimes(0);
      expect(mockFetcher).toBeCalledTimes(0);

      await runGetPublishViewMetaWithStrategy(StrategyType.CACHE_AND_NETWORK);
      expect(openCollabDB).toBeCalledTimes(0);
      expect(mockFetcher).toBeCalledTimes(1);
    });
  });
});

describe('collabTypeToDBType', () => {
  it('should return correct DB type', () => {
    expect(collabTypeToDBType(Types.Document)).toBe('document');
    expect(collabTypeToDBType(Types.Folder)).toBe('folder');
    expect(collabTypeToDBType(Types.Database)).toBe('database');
    expect(collabTypeToDBType(Types.WorkspaceDatabase)).toBe('databases');
    expect(collabTypeToDBType(Types.DatabaseRow)).toBe('database_row');
    expect(collabTypeToDBType(Types.UserAwareness)).toBe('user_awareness');
    expect(collabTypeToDBType(Types.Empty)).toBe('');
  });
});
