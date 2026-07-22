import { PlayCircle, RefreshCw } from 'lucide-react';

interface Props {
  generatedAt?: string;
  onRefresh: () => void;
  onScan: () => void;
  loading: boolean;
  scanning: boolean;
  scanMessage?: string;
}

export function Header({ generatedAt, onRefresh, onScan, loading, scanning, scanMessage }: Props) {
  return (
    <header className="flex items-center justify-between rounded-2xl border border-slate-200 bg-white px-6 py-4 shadow-sm">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Wellcome Cloud Inventory</h1>
        <p className="text-sm text-slate-500">
          Generated {generatedAt ? new Date(generatedAt).toLocaleString() : '—'}
          {scanMessage ? <span className="ml-3 text-indigo-600">{scanMessage}</span> : null}
        </p>
      </div>
      <div className="flex items-center gap-2">
        <button
          onClick={onScan}
          className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-60"
          disabled={scanning || loading}
          title="Kick off a fresh scan across all accounts"
        >
          <PlayCircle className={`h-4 w-4 ${scanning ? 'animate-pulse' : ''}`} />
          {scanning ? 'Scanning…' : 'Scan Now'}
        </button>
        <button
          onClick={onRefresh}
          className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-60"
          disabled={loading}
        >
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} /> Refresh
        </button>
      </div>
    </header>
  );
}
