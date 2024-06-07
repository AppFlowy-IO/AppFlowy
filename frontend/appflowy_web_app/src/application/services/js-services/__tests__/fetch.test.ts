import { expect } from '@jest/globals';
import { fetchCollab, batchFetchCollab } from '../fetch';
import { CollabType } from '@/application/collab.type';
import { APIService } from '@/application/services/js-services/wasm';

jest.mock('@/application/services/js-services/wasm', () => {
  return {
    APIService: {
      getCollab: jest.fn(),
      batchGetCollab: jest.fn(),
    },
  };
});

describe('Collab fetch functions with deduplication', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('fetchCollab', () => {
    it('should fetch collab without duplicating requests', async () => {
      const workspaceId = 'workspace1';
      const id = 'id1';
      const type = CollabType.Document;
      const mockResponse = { data: 'mockData' };

      (APIService.getCollab as jest.Mock).mockResolvedValue(mockResponse);

      const result1 = fetchCollab(workspaceId, id, type);
      const result2 = fetchCollab(workspaceId, id, type);

      expect(result1).toBe(result2);
      await expect(result1).resolves.toEqual(mockResponse);
      expect(APIService.getCollab).toHaveBeenCalledTimes(1);
    });
  });

  describe('batchFetchCollab', () => {
    it('should batch fetch collabs without duplicating requests', async () => {
      const workspaceId = 'workspace1';
      const params = [
        { collabId: 'id1', collabType: CollabType.Document },
        { collabId: 'id2', collabType: CollabType.Folder },
      ];
      const mockResponse = { data: 'mockData' };

      (APIService.batchGetCollab as jest.Mock).mockResolvedValue(mockResponse);

      const result1 = batchFetchCollab(workspaceId, params);
      const result2 = batchFetchCollab(workspaceId, params);

      expect(result1).toBe(result2);
      await expect(result1).resolves.toEqual(mockResponse);
      expect(APIService.batchGetCollab).toHaveBeenCalledTimes(1);
    });
  });
});
