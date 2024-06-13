import { CollabType } from '@/application/collab.type';
import * as Y from 'yjs';
import { withTestingYDoc } from '@/application/slate-yjs/__tests__/withTestingYjsEditor';
import { expect } from '@jest/globals';
import { getCollab, batchCollab, collabTypeToDBType } from '../cache';
import { applyYDoc } from '@/application/ydoc/apply';
import { getCollabDBName, openCollabDB } from '../cache/db';
import { StrategyType } from '../cache/types';

jest.mock('@/application/ydoc/apply', () => ({
  applyYDoc: jest.fn(),
}));
jest.mock('../cache/db', () => ({
  openCollabDB: jest.fn(),
  getCollabDBName: jest.fn(),
}));

const emptyDoc = new Y.Doc();
const normalDoc = withTestingYDoc('1');
const mockFetcher = jest.fn();
const mockBatchFetcher = jest.fn();

describe('Cache functions', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('getCollab', () => {
    describe('with CACHE_ONLY strategy', () => {
      it('should throw error when no cache', async () => {
        (openCollabDB as jest.Mock).mockResolvedValue(emptyDoc);
        (getCollabDBName as jest.Mock).mockReturnValue('testDB');

        await expect(
          getCollab(
            mockFetcher,
            {
              collabId: 'id1',
              collabType: CollabType.Document,
            },
            StrategyType.CACHE_ONLY
          )
        ).rejects.toThrow('No cache found');
      });
      it('should fetch collab with CACHE_ONLY strategy and existing cache', async () => {
        (openCollabDB as jest.Mock).mockResolvedValue(normalDoc);
        (getCollabDBName as jest.Mock).mockReturnValue('testDB');

        const result = await getCollab(
          mockFetcher,
          {
            collabId: 'id1',
            collabType: CollabType.Document,
          },
          StrategyType.CACHE_ONLY
        );

        expect(result).toBe(normalDoc);
        expect(mockFetcher).not.toHaveBeenCalled();
        expect(applyYDoc).not.toHaveBeenCalled();
      });
    });

    describe('with CACHE_FIRST strategy', () => {
      it('should fetch collab with CACHE_FIRST strategy and existing cache', async () => {
        (openCollabDB as jest.Mock).mockResolvedValue(normalDoc);
        (getCollabDBName as jest.Mock).mockReturnValue('testDB');

        mockFetcher.mockResolvedValue({ state: new Uint8Array() });

        const result = await getCollab(
          mockFetcher,
          {
            collabId: 'id1',
            collabType: CollabType.Document,
          },
          StrategyType.CACHE_FIRST
        );

        expect(result).toBe(normalDoc);
        expect(mockFetcher).not.toHaveBeenCalled();
        expect(applyYDoc).not.toHaveBeenCalled();
      });

      it('should fetch collab with CACHE_FIRST strategy and no cache', async () => {
        (openCollabDB as jest.Mock).mockResolvedValue(emptyDoc);
        (getCollabDBName as jest.Mock).mockReturnValue('testDB');

        mockFetcher.mockResolvedValue({ state: new Uint8Array() });

        const result = await getCollab(
          mockFetcher,
          {
            collabId: 'id1',
            collabType: CollabType.Document,
          },
          StrategyType.CACHE_FIRST
        );

        expect(result).toBe(emptyDoc);
        expect(mockFetcher).toHaveBeenCalled();
        expect(applyYDoc).toHaveBeenCalled();
      });
    });

    describe('with CACHE_AND_NETWORK strategy', () => {
      it('should fetch collab with CACHE_AND_NETWORK strategy and existing cache', async () => {
        (openCollabDB as jest.Mock).mockResolvedValue(normalDoc);
        (getCollabDBName as jest.Mock).mockReturnValue('testDB');

        mockFetcher.mockResolvedValue({ state: new Uint8Array() });

        const result = await getCollab(
          mockFetcher,
          {
            collabId: 'id1',
            collabType: CollabType.Document,
          },
          StrategyType.CACHE_AND_NETWORK
        );

        expect(result).toBe(normalDoc);
        expect(mockFetcher).toHaveBeenCalled();
        expect(applyYDoc).toHaveBeenCalled();
      });

      it('should fetch collab with CACHE_AND_NETWORK strategy and no cache', async () => {
        (openCollabDB as jest.Mock).mockResolvedValue(emptyDoc);
        (getCollabDBName as jest.Mock).mockReturnValue('testDB');

        mockFetcher.mockResolvedValue({ state: new Uint8Array() });

        const result = await getCollab(
          mockFetcher,
          {
            collabId: 'id1',
            collabType: CollabType.Document,
          },
          StrategyType.CACHE_AND_NETWORK
        );

        expect(result).toBe(emptyDoc);
        expect(mockFetcher).toHaveBeenCalled();
        expect(applyYDoc).toHaveBeenCalled();
      });
    });

    describe('with default strategy', () => {
      it('should fetch collab with default strategy', async () => {
        (openCollabDB as jest.Mock).mockResolvedValue(normalDoc);
        (getCollabDBName as jest.Mock).mockReturnValue('testDB');

        mockFetcher.mockResolvedValue({ state: new Uint8Array() });

        const result = await getCollab(
          mockFetcher,
          {
            collabId: 'id1',
            collabType: CollabType.Document,
          },
          StrategyType.NETWORK_ONLY
        );

        expect(result).toBe(normalDoc);
        expect(mockFetcher).toHaveBeenCalled();
        expect(applyYDoc).toHaveBeenCalled();
      });
    });
  });

  describe('batchCollab', () => {
    describe('with CACHE_ONLY strategy', () => {
      it('should batch fetch collabs with CACHE_ONLY strategy and no cache', async () => {
        (openCollabDB as jest.Mock).mockResolvedValue(emptyDoc);

        (getCollabDBName as jest.Mock).mockReturnValue('testDB');

        await expect(
          batchCollab(
            mockBatchFetcher,
            [
              {
                collabId: 'id1',
                collabType: CollabType.Document,
              },
            ],
            StrategyType.CACHE_ONLY
          )
        ).rejects.toThrow('No cache found');
      });

      it('should batch fetch collabs with CACHE_ONLY strategy and existing cache', async () => {
        (openCollabDB as jest.Mock).mockResolvedValue(normalDoc);

        (getCollabDBName as jest.Mock).mockReturnValue('testDB');

        await batchCollab(
          mockBatchFetcher,
          [
            {
              collabId: 'id1',
              collabType: CollabType.Document,
            },
          ],
          StrategyType.CACHE_ONLY
        );

        expect(mockBatchFetcher).not.toHaveBeenCalled();
      });
    });

    describe('with CACHE_FIRST strategy', () => {
      it('should batch fetch collabs with CACHE_FIRST strategy and existing cache', async () => {
        (openCollabDB as jest.Mock).mockResolvedValue(normalDoc);

        (getCollabDBName as jest.Mock).mockReturnValue('testDB');

        await batchCollab(
          mockBatchFetcher,
          [
            {
              collabId: 'id1',
              collabType: CollabType.Document,
            },
          ],
          StrategyType.CACHE_FIRST
        );

        expect(mockBatchFetcher).not.toHaveBeenCalled();
      });

      it('should batch fetch collabs with CACHE_FIRST strategy and no cache', async () => {
        (openCollabDB as jest.Mock).mockResolvedValue(emptyDoc);

        (getCollabDBName as jest.Mock).mockReturnValue('testDB');
        mockBatchFetcher.mockResolvedValue({ id1: [1, 2, 3] });

        await batchCollab(
          mockBatchFetcher,
          [
            {
              collabId: 'id1',
              collabType: CollabType.Document,
            },
          ],
          StrategyType.CACHE_FIRST
        );

        expect(mockBatchFetcher).toHaveBeenCalled();
        expect(applyYDoc).toHaveBeenCalled();
      });
    });

    describe('with CACHE_AND_NETWORK strategy', () => {
      it('should batch fetch collabs with CACHE_AND_NETWORK strategy', async () => {
        (openCollabDB as jest.Mock).mockResolvedValue(normalDoc);

        (getCollabDBName as jest.Mock).mockReturnValue('testDB');
        mockBatchFetcher.mockResolvedValue({ id1: [1, 2, 3] });

        await batchCollab(
          mockBatchFetcher,
          [
            {
              collabId: 'id1',
              collabType: CollabType.Document,
            },
          ],
          StrategyType.CACHE_AND_NETWORK
        );

        expect(mockBatchFetcher).toHaveBeenCalled();
        expect(applyYDoc).toHaveBeenCalled();
      });

      it('should batch fetch collabs with CACHE_AND_NETWORK strategy and no cache', async () => {
        (openCollabDB as jest.Mock).mockResolvedValue(emptyDoc);

        (getCollabDBName as jest.Mock).mockReturnValue('testDB');
        mockBatchFetcher.mockResolvedValue({ id1: [1, 2, 3] });

        await batchCollab(
          mockBatchFetcher,
          [
            {
              collabId: 'id1',
              collabType: CollabType.Document,
            },
          ],
          StrategyType.CACHE_AND_NETWORK
        );

        expect(mockBatchFetcher).toHaveBeenCalled();
        expect(applyYDoc).toHaveBeenCalled();
      });
    });
  });
});

describe('collabTypeToDBType', () => {
  it('should return correct DB type', () => {
    expect(collabTypeToDBType(CollabType.Document)).toBe('document');
    expect(collabTypeToDBType(CollabType.Folder)).toBe('folder');
    expect(collabTypeToDBType(CollabType.Database)).toBe('database');
    expect(collabTypeToDBType(CollabType.WorkspaceDatabase)).toBe('databases');
    expect(collabTypeToDBType(CollabType.DatabaseRow)).toBe('database_row');
    expect(collabTypeToDBType(CollabType.UserAwareness)).toBe('user_awareness');
    expect(collabTypeToDBType(CollabType.Empty)).toBe('');
  });
});
