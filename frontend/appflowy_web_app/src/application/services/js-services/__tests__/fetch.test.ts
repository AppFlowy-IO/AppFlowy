import { expect } from '@jest/globals';
import { fetchPublishView, fetchPublishViewMeta, fetchViewInfo } from '../fetch';
import { APIService } from '@/application/services/js-services/wasm';

jest.mock('@/application/services/js-services/wasm', () => {
  return {
    APIService: {
      getPublishView: jest.fn(),
      getPublishViewMeta: jest.fn(),
      getPublishInfoWithViewId: jest.fn(),
    },
  };
});

describe('Collab fetch functions with deduplication', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('fetchPublishView', () => {
    it('should fetch publish view without duplicating requests', async () => {
      const namespace = 'namespace1';
      const publishName = 'publish1';
      const mockResponse = { data: 'mockData' };

      (APIService.getPublishView as jest.Mock).mockResolvedValue(mockResponse);

      const result1 = fetchPublishView(namespace, publishName);
      const result2 = fetchPublishView(namespace, publishName);

      expect(result1).toBe(result2);
      await expect(result1).resolves.toEqual(mockResponse);
      expect(APIService.getPublishView).toHaveBeenCalledTimes(1);
    });

    it('should fetch publish view with different params', async () => {
      const namespace = 'namespace1';
      const publishName = 'publish1';
      const mockResponse = { data: 'mockData' };

      (APIService.getPublishView as jest.Mock).mockResolvedValue(mockResponse);

      const result1 = fetchPublishView(namespace, publishName);
      const result2 = fetchPublishView(namespace, 'publish2');

      expect(result1).not.toBe(result2);
      await expect(result1).resolves.toEqual(mockResponse);
      await expect(result2).resolves.toEqual(mockResponse);
      expect(APIService.getPublishView).toHaveBeenCalledTimes(2);
    });
  });

  describe('fetchViewInfo', () => {
    it('should fetch view info without duplicating requests', async () => {
      const viewId = 'view1';
      const mockResponse = { data: 'mockData' };

      (APIService.getPublishInfoWithViewId as jest.Mock).mockResolvedValue(mockResponse);

      const result1 = fetchViewInfo(viewId);
      const result2 = fetchViewInfo(viewId);

      expect(result1).toBe(result2);
      await expect(result1).resolves.toEqual(mockResponse);
      expect(APIService.getPublishInfoWithViewId).toHaveBeenCalledTimes(1);
    });

    it('should fetch view info with different params', async () => {
      const viewId = 'view1';
      const mockResponse = { data: 'mockData' };

      (APIService.getPublishInfoWithViewId as jest.Mock).mockResolvedValue(mockResponse);

      const result1 = fetchViewInfo(viewId);
      const result2 = fetchViewInfo('view2');

      expect(result1).not.toBe(result2);
      await expect(result1).resolves.toEqual(mockResponse);
      await expect(result2).resolves.toEqual(mockResponse);
      expect(APIService.getPublishInfoWithViewId).toHaveBeenCalledTimes(2);
    });
  });

  describe('fetchPublishViewMeta', () => {
    it('should fetch publish view meta without duplicating requests', async () => {
      const namespace = 'namespace1';
      const publishName = 'publish1';
      const mockResponse = { data: 'mockData' };

      (APIService.getPublishViewMeta as jest.Mock).mockResolvedValue(mockResponse);

      const result1 = fetchPublishViewMeta(namespace, publishName);
      const result2 = fetchPublishViewMeta(namespace, publishName);

      expect(result1).toBe(result2);
      await expect(result1).resolves.toEqual(mockResponse);
      expect(APIService.getPublishViewMeta).toHaveBeenCalledTimes(1);
    });

    it('should fetch publish view meta with different params', async () => {
      const namespace = 'namespace1';
      const publishName = 'publish1';
      const mockResponse = { data: 'mockData' };

      (APIService.getPublishViewMeta as jest.Mock).mockResolvedValue(mockResponse);

      const result1 = fetchPublishViewMeta(namespace, publishName);
      const result2 = fetchPublishViewMeta(namespace, 'publish2');

      expect(result1).not.toBe(result2);
      await expect(result1).resolves.toEqual(mockResponse);
      await expect(result2).resolves.toEqual(mockResponse);
      expect(APIService.getPublishViewMeta).toHaveBeenCalledTimes(2);
    });
  });
});
