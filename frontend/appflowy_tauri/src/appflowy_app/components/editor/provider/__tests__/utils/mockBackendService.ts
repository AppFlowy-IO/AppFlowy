import read_me from '$app/components/editor/provider/__tests__/read_me';

const applyActions = jest.fn().mockReturnValue(Promise.resolve());

jest.mock('$app/application/notification', () => {
  return {
    subscribeNotification: jest.fn().mockReturnValue(Promise.resolve(() => ({}))),
  };
});

jest.mock('nanoid', () => ({ nanoid: jest.fn().mockReturnValue(String(Math.random())) }));

jest.mock('$app/application/document/document_service', () => {
  return {
    openDocument: jest.fn().mockReturnValue(Promise.resolve(read_me)),
    applyActions,
  };
});

export { applyActions };
