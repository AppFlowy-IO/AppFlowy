export enum TemplateCategoryType {
  ByUseCase,
  ByFeature,
}

export enum TemplateIcon {
  project = 'project',
  engineering = 'engineering',
  startups = 'startups',
  schools = 'schools',
  marketing = 'marketing',
  management = 'management',
  humanResources = 'human-resources',
  sales = 'sales',
  teamMeetings = 'team-meetings',
  ai = 'ai',
  docs = 'docs',
  wiki = 'wiki',
  database = 'database',
  kanban = 'kanban',
}

export interface TemplateCategoryFormValues {
  name: string;
  icon: TemplateIcon;
  bg_color: string;
  description: string;
  category_type: TemplateCategoryType,
  priority: number;
}

export interface TemplateCategory extends TemplateCategoryFormValues {
  id: string;
}

export interface TemplateCreatorFormValues {
  name: string;
  avatar_url: string;
  account_links?: {
    link_type: string;
    url: string;
  }[];
}

export interface TemplateCreator {
  id: string;
  name: string;
  avatar_url: string;
  upload_template_count?: number;
  account_links?: {
    link_type: string;
    url: string;
  }[];
}

export interface UploadTemplatePayload {
  view_id: string;
  name: string;
  description: string;
  view_url: string;
  about: string;
  category_ids: string[];
  creator_id: string;
  is_new_template: boolean;
  is_featured: boolean;
  related_view_ids: string[];
}

export interface TemplateSummary {
  view_id: string;
  name: string;
  description: string;
  view_url: string;
  categories: TemplateCategory[];
  creator: TemplateCreator;
  is_new_template: boolean;
  is_featured: boolean;
}

export interface Template extends TemplateSummary {
  about: string;
  related_templates: TemplateSummary[];
}