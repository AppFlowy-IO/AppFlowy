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

export class AFTauriService implements AFService {
  authService: AuthService;
  userService: UserService;
  documentService: DocumentService;

  constructor(config: AFServiceConfig) {
    this.authService = new TauriAuthService(config.cloudConfig);
    this.userService = new TauriUserService();
    this.documentService = new TauriDocumentService();
  }

  async load() {
    // Do nothing
  }
}
