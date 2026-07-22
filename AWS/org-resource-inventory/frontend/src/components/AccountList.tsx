import type { AccountReport } from '../types';

interface Props {
  accounts: AccountReport[];
  selectedId?: string;
  onSelect: (id: string) => void;
}

export function AccountList({ accounts, selectedId, onSelect }: Props) {
  return (
    <aside className="w-80 shrink-0 rounded-2xl bg-slate-950 p-4 text-white shadow-xl">
      <div className="mb-4 text-xs font-semibold uppercase tracking-wider text-slate-400">Accounts</div>
      <div className="space-y-2">
        {accounts.map((account) => {
          const selected = account.id === selectedId;
          return (
            <button key={account.id} onClick={() => onSelect(account.id)} className={`w-full rounded-xl p-3 text-left transition ${selected ? 'bg-indigo-600' : 'bg-slate-900 hover:bg-slate-800'}`}>
              <div className="flex items-center justify-between gap-3">
                <div className="min-w-0">
                  <div className="truncate font-medium">{account.name || account.id}</div>
                  <div className="font-mono text-xs text-slate-300">{account.id}</div>
                </div>
                <span className="rounded-full bg-rose-500/20 px-2 py-1 text-xs font-semibold text-rose-100">{account.counts?.unmanaged ?? 0}</span>
              </div>
            </button>
          );
        })}
      </div>
    </aside>
  );
}
