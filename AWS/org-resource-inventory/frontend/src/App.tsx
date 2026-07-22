import { useEffect, useMemo, useRef, useState } from 'react';
import { fetchLatest, triggerScan } from './api';
import type { Report } from './types';
import { AccountList } from './components/AccountList';
import { FilterBar } from './components/FilterBar';
import { Header } from './components/Header';
import { ResourceTable } from './components/ResourceTable';

export default function App() {
  const [report, setReport] = useState<Report>();
  const [selected, setSelected] = useState<string>();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>();
  const [scanning, setScanning] = useState(false);
  const [scanMessage, setScanMessage] = useState<string>();
  const [filters, setFilters] = useState({ query: '', status: 'all', type: 'all', region: 'all' });
  const pollRef = useRef<number>();
  const load = async () => { setLoading(true); setError(undefined); try { const data = await fetchLatest(); setReport(data); setSelected((current) => current && data.accounts.some((a) => a.id === current) ? current : data.accounts[0]?.id); return data; } catch (e) { setError(e instanceof Error ? e.message : String(e)); } finally { setLoading(false); } };
  useEffect(() => { void load(); return () => { if (pollRef.current) window.clearInterval(pollRef.current); }; }, []);
  const startScan = async () => {
    if (scanning) return;
    setScanning(true);
    setScanMessage('Scan started — this can take a few minutes…');
    try {
      await triggerScan();
      const startedAt = report?.generated_at;
      const started = Date.now();
      pollRef.current = window.setInterval(async () => {
        const data = await fetchLatest();
        if (data.generated_at && data.generated_at !== startedAt) {
          setReport(data);
          setScanMessage('Scan complete ✔');
          setScanning(false);
          window.clearInterval(pollRef.current);
          window.setTimeout(() => setScanMessage(undefined), 5000);
        } else if (Date.now() - started > 20 * 60 * 1000) {
          setScanMessage('Scan is taking longer than expected — check CloudWatch logs.');
          setScanning(false);
          window.clearInterval(pollRef.current);
        }
      }, 15000);
    } catch (e) {
      setScanMessage(`Scan failed to start: ${e instanceof Error ? e.message : String(e)}`);
      setScanning(false);
    }
  };
  const account = report?.accounts.find((a) => a.id === selected);
  const resources = account?.resources ?? [];
  const types = useMemo(() => [...new Set(resources.map((r) => r.type))].sort(), [resources]);
  const regions = useMemo(() => [...new Set(resources.map((r) => r.region))].sort(), [resources]);
  const filtered = useMemo(() => resources.filter((r) => {
    const q = filters.query.toLowerCase();
    const searchable = [r.id, r.name, r.arn, JSON.stringify(r.tags || {})].join(' ').toLowerCase();
    return (!q || searchable.includes(q)) && (filters.status === 'all' || r.management_status === filters.status) && (filters.type === 'all' || r.type === filters.type) && (filters.region === 'all' || r.region === filters.region);
  }), [resources, filters]);
  return (
    <div className="min-h-screen p-6">
      {loading && !report ? <div className="grid min-h-screen place-items-center text-slate-500">Loading inventory…</div> : null}
      {error ? <div className="mx-auto mt-20 max-w-xl rounded-2xl border border-rose-200 bg-rose-50 p-6 text-rose-700">{error}</div> : null}
      {report ? <div className="flex gap-6">
        <AccountList accounts={report.accounts} selectedId={selected} onSelect={setSelected} />
        <main className="min-w-0 flex-1 space-y-5">
          <Header generatedAt={report.generated_at} onRefresh={load} onScan={startScan} loading={loading} scanning={scanning} scanMessage={scanMessage} />
          <section className="grid gap-4 md:grid-cols-4">
            {['total','managed','unmanaged','ignored'].map((key) => <div key={key} className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm"><div className="text-xs uppercase text-slate-500">{key}</div><div className="text-2xl font-semibold">{report.summary?.[key] ?? 0}</div></div>)}
          </section>
          <FilterBar {...filters} types={types} regions={regions} onChange={(next) => setFilters((f) => ({ ...f, ...next }))} />
          <ResourceTable resources={filtered} />
        </main>
      </div> : null}
    </div>
  );
}
