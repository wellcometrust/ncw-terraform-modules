import { useMemo, useState } from 'react';
import type { Resource } from '../types';

type SortKey = 'type' | 'id' | 'name' | 'region' | 'management_status';
const badge: Record<string, string> = { managed: 'bg-emerald-100 text-emerald-700', unmanaged: 'bg-rose-100 text-rose-700', ignored: 'bg-slate-200 text-slate-700', cloudformation: 'bg-amber-100 text-amber-700' };

interface Props { resources: Resource[] }

export function ResourceTable({ resources }: Props) {
  const [sort, setSort] = useState<{ key: SortKey; dir: 1 | -1 }>({ key: 'management_status', dir: 1 });
  const sorted = useMemo(() => [...resources].sort((a, b) => String(a[sort.key] ?? '').localeCompare(String(b[sort.key] ?? '')) * sort.dir), [resources, sort]);
  const setKey = (key: SortKey) => setSort((prev) => ({ key, dir: prev.key === key ? (prev.dir === 1 ? -1 : 1) : 1 }));
  if (!sorted.length) return <div className="rounded-2xl border border-dashed border-slate-300 bg-white p-12 text-center text-slate-500">No resources match your filters.</div>;
  return (
    <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      <table className="min-w-full divide-y divide-slate-200 text-sm">
        <thead className="bg-slate-50 text-left text-xs uppercase tracking-wide text-slate-500">
          <tr>{(['type','id','name','region','management_status'] as SortKey[]).map((key) => <th key={key} onClick={() => setKey(key)} className="cursor-pointer px-4 py-3">{key === 'management_status' ? 'Status' : key}</th>)}<th className="px-4 py-3">Tags</th></tr>
        </thead>
        <tbody className="divide-y divide-slate-100">
          {sorted.map((r, i) => <tr key={`${r.type}-${r.id}-${i}`} className="hover:bg-slate-50">
            <td className="px-4 py-3 font-medium">{r.type}</td><td className="max-w-md truncate px-4 py-3 font-mono text-xs text-slate-700" title={r.arn || r.id}>{r.id}</td><td className="px-4 py-3">{r.name || '—'}</td><td className="px-4 py-3">{r.region}</td>
            <td className="px-4 py-3"><span className={`rounded-full px-2 py-1 text-xs font-semibold ${badge[r.management_status]}`}>{r.management_status === 'cloudformation' ? 'cfn' : r.management_status}</span></td>
            <td className="max-w-xs truncate px-4 py-3 text-xs text-slate-500" title={JSON.stringify(r.tags)}>{Object.entries(r.tags || {}).map(([k,v]) => `${k}=${v}`).join(', ') || '—'}</td>
          </tr>)}
        </tbody>
      </table>
    </div>
  );
}
