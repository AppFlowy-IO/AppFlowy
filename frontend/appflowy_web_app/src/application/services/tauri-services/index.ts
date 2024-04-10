import {
  AFService,
  AFServiceConfig,
  AuthService,
  DocumentService,
  UserService,
} from '@/application/services/services.type';
import { TauriAuthService } from '@/application/services/tauri-services/auth.service';
import { TauriUserService } from '@/application/services/tauri-services/user.service';
import { TauriDocumentService } from '@/application/services/tauri-services/document.service';
import { nanoid } from 'nanoid';

export class AFClientService implements AFService {
  authService: AuthService;
  userService: UserService;
  documentService: DocumentService;
  private deviceId: string = nanoid(8);
  private clientId: string = 'web';
  getDeviceID = (): string => {
    return this.deviceId;
  };

  getClientID = (): string => {
    return this.clientId;
  };

  constructor(config: AFServiceConfig) {
    this.authService = new TauriAuthService(config.cloudConfig, {
      deviceId: this.deviceId,
      clientId: this.clientId,
    });
    this.userService = new TauriUserService();
    this.documentService = new TauriDocumentService();
  }

  async load() {
    // Do nothing
  }
}
