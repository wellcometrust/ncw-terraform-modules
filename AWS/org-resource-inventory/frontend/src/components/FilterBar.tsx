interface Props {
  query: string;
  status: string;
  type: string;
  region: string;
  types: string[];
  regions: string[];
  onChange: (next: { query?: string; status?: string; type?: string; region?: string }) => void;
}

export function FilterBar({ query, status, type, region, types, regions, onChange }: Props) {
  const selectClass = 'rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm shadow-sm';
  return (
    <div className="grid gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm md:grid-cols-4">
      <input value={query} onChange={(e) => onChange({ query: e.target.value })} placeholder="Search ID, name, ARN, tags" className="rounded-lg border border-slate-200 px-3 py-2 text-sm shadow-sm md:col-span-1" />
      <select value={status} onChange={(e) => onChange({ status: e.target.value })} className={selectClass}>
        <option value="all">All statuses</option><option value="managed">Managed</option><option value="unmanaged">Unmanaged</option><option value="ignored">Ignored</option><option value="cloudformation">CFN</option>
      </select>
      <select value={type} onChange={(e) => onChange({ type: e.target.value })} className={selectClass}>
        <option value="all">All types</option>{types.map((t) => <option key={t} value={t}>{t}</option>)}
      </select>
      <select value={region} onChange={(e) => onChange({ region: e.target.value })} className={selectClass}>
        <option value="all">All regions</option>{regions.map((r) => <option key={r} value={r}>{r}</option>)}
      </select>
    </div>
  );
}
