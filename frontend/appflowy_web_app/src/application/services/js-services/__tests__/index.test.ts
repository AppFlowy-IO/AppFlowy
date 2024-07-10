import { withTestingYDoc } from '@/application/slate-yjs/__tests__/withTestingYjsEditor';
import { AFClientService } from '../index';
import { fetchViewInfo } from '@/application/services/js-services/fetch';
import { expect, jest } from '@jest/globals';
import { getPublishView, getPublishViewMeta } from '@/application/services/js-services/cache';

jest.mock('@/application/services/js-services/wasm/client_api', () => {
  return {
    initAPIService: jest.fn(),
  };
});
jest.mock('nanoid', () => {
  return {
    nanoid: jest.fn().mockReturnValue('12345678'),
  };
});
jest.mock('@/application/services/js-services/fetch', () => {
  return {
    fetchPublishView: jest.fn(),
    fetchPublishViewMeta: jest.fn(),
    fetchViewInfo: jest.fn(),
  };
});

jest.mock('@/application/services/js-services/cache', () => {
  return {
    getPublishView: jest.fn(),
    getPublishViewMeta: jest.fn(),
    getBatchCollabs: jest.fn(),
  };
});
describe('AFClientService', () => {
  let service: AFClientService;
  beforeEach(() => {
    jest.clearAllMocks();
    service = new AFClientService({
      cloudConfig: {
        baseURL: 'http://localhost:3000',
        gotrueURL: 'http://localhost:3000',
        wsURL: 'ws://localhost:3000',
      },
    });
  });

  it('should get view meta', async () => {
    const namespace = 'namespace';
    const publishName = 'publishName';
    const mockResponse = {
      view_id: 'view_id',
      publish_name: publishName,
      metadata: {
        view: {
          name: 'viewName',
          view_id: 'view_id',
        },
        child_views: [],
        ancestor_views: [],
      },
    };

    // @ts-ignore
    (getPublishViewMeta as jest.Mock).mockResolvedValue(mockResponse);

    const result = await service.getPublishViewMeta(namespace, publishName);

    expect(result).toEqual(mockResponse);
  });

  it('should get view', async () => {
    const namespace = 'namespace';
    const publishName = 'publishName';
    const mockResponse = {
      data: [1, 2, 3],
      meta: {
        metadata: {
          view: {
            name: 'viewName',
            view_id: 'view_id',
          },
          child_views: [],
          ancestor_views: [],
        },
      },
    };

    // @ts-ignore
    (getPublishView as jest.Mock).mockResolvedValue(mockResponse);

    const result = await service.getPublishView(namespace, publishName);

    expect(result).toEqual(mockResponse);
  });

  it('should get view info', async () => {
    const viewId = 'viewId';
    const mockResponse = {
      namespace: 'namespace',
      publish_name: 'publishName',
    };

    // @ts-ignore
    (fetchViewInfo as jest.Mock).mockResolvedValue(mockResponse);

    const result = await service.getPublishInfo(viewId);

    expect(result).toEqual({
      namespace: 'namespace',
      publishName: 'publishName',
    });
  });

  it('getPublishDatabaseViewRows', async () => {
    const namespace = 'namespace';
    const publishName = 'publishName';
    const mockResponse = [withTestingYDoc('1'), withTestingYDoc('2'), withTestingYDoc('3')];

    // @ts-ignore
    (getBatchCollabs as jest.Mock).mockResolvedValue(mockResponse);

    const result = await service.getPublishDatabaseViewRows(namespace, publishName);

    expect(result).toEqual({
      rows: expect.any(Object),
      destroy: expect.any(Function),
    });
  });
});
