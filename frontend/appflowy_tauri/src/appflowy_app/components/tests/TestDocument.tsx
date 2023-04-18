import React from 'react';
import { createTestDocument } from './DocumentTestHelper';
import { DocumentBackendService } from '../../stores/effects/document/document_bd_svc';

async function testCreateDocument() {
  const view = await createTestDocument();
  const svc = new DocumentBackendService(view.id);
  const document = await svc.open().then((result) => result.unwrap());

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  // const content = JSON.parse(document.content);
  // The initial document content:
  // {
  //   "document": {
  //   "type": "editor",
  //     "children": [
  //     {
  //       "type": "text"
  //     }
  //   ]
  // }
  // }
  await svc.close();
}

export const TestCreateDocument = () => {
  return TestButton('Test create document', testCreateDocument);
};

const TestButton = (title: string, onClick: () => void) => {
  return (
    <React.Fragment>
      <div>
        <button className='rounded-md bg-purple-400 p-4' type='button' onClick={() => onClick()}>
          {title}
        </button>
      </div>
    </React.Fragment>
  );
};
