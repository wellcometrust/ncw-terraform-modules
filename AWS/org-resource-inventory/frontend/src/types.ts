export type ManagementStatus = 'managed' | 'unmanaged' | 'ignored' | 'cloudformation';

export interface Resource {
  type: string;
  id: string;
  arn?: string;
  name?: string;
  region: string;
  tags: Record<string, string>;
  raw: Record<string, unknown>;
  management_status: ManagementStatus;
}

export interface AccountReport {
  id: string;
  name: string;
  email: string;
  resources: Resource[];
  counts: Record<string, number>;
  errors: { region: string; error: string }[];
}

export interface Report {
  generated_at: string;
  org_id?: string;
  accounts: AccountReport[];
  summary: Record<string, number>;
}
