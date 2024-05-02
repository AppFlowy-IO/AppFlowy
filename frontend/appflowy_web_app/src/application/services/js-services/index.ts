import {
  AFService,
  AFServiceConfig,
  AuthService,
  DocumentService,
  FolderService,
  UserService,
} from '@/application/services/services.type';
import { JSUserService } from '@/application/services/js-services/user.service';
import { JSAuthService } from '@/application/services/js-services/auth.service';
import { JSFolderService } from '@/application/services/js-services/folder.service';
import { JSDocumentService } from '@/application/services/js-services/document.service';
import { nanoid } from 'nanoid';
import { initAPIService } from '@/application/services/js-services/wasm/client_api';

export class AFClientService implements AFService {
  authService: AuthService;

  userService: UserService;

  documentService: DocumentService;

  folderService: FolderService;

  private deviceId: string = nanoid(8);

  private clientId: string = 'web';

  getDeviceID = (): string => {
    return this.deviceId;
  };

  getClientID = (): string => {
    return this.clientId;
  };

  constructor(config: AFServiceConfig) {
    initAPIService({
      ...config.cloudConfig,
      deviceId: this.deviceId,
      clientId: this.clientId,
    });

    this.authService = new JSAuthService();
    this.userService = new JSUserService();
    this.documentService = new JSDocumentService();
    this.folderService = new JSFolderService();
  }
}
