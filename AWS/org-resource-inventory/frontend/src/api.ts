import type { Report } from './types';

export async function fetchLatest(): Promise<Report> {
  const response = await fetch('/api/reports/latest.json', { cache: 'no-cache' });
  if (!response.ok) throw new Error(`Failed to load report (${response.status})`);
  return response.json();
}

export async function triggerScan(): Promise<void> {
  const response = await fetch('/api/scan', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: '{}',
  });
  if (!response.ok && response.status !== 202) {
    throw new Error(`Failed to trigger scan (${response.status})`);
  }
}
