import { useEffect, useState } from 'react';

interface Props { api: string; headers: Record<string, string>; }

interface RecentVault { id: string; title: string; buyer: string; amount: number; state: string; }
interface DashboardData { 
  activeVaults: number; 
  pendingKyc: number; 
  openDisputes: number; 
  completedToday: number; 
  totalLocked: number; 
  recentVaults: RecentVault[];
  compliance: {
    escrowReconciled: boolean;
    auditRetention: boolean;
    kycResponseTime: boolean;
    paymentSuccessRate: number;
    incidentReports: number;
  };
  health: {
    invoiceEngine: number;
    payoutOrchestrator: number;
    notificationBroadcast: number;
    vaultWatcher: number;
    ledgerSync: number;
  };
}

export default function Dashboard({ api, headers }: Props) {
  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`${api}/admin/stats`, { headers })
      .then(r => r.json())
      .then(d => { setData(d.data); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);

  const stats = data ? [
    { label: 'Active Vaults', value: data.activeVaults, icon: '🔐', color: 'var(--primary)', description: 'Secure assets in custody' },
    { label: 'KYC Queue', value: data.pendingKyc, icon: '🪪', color: 'var(--warning)', description: 'Pending identity audits' },
    { label: 'Dispute Protocol', value: data.openDisputes, icon: '⚖️', color: 'var(--danger)', description: 'Active arbitration cases' },
    { label: 'Settled (24h)', value: data.completedToday, icon: '✅', color: 'var(--primary)', description: 'Released to beneficiaries' },
    { label: 'Total Locked (NPR)', value: `₨ ${(data.totalLocked / 10000000).toFixed(2)}Cr`, icon: '💰', color: 'var(--gold)', description: 'Aggregated vault liquidity' },
    { label: 'System Uptime', value: '99.9%', icon: '📈', color: 'var(--primary)', description: 'Node network stability' },
  ] : [];

  const stateBadge = (s: string) => {
    const map: Record<string, string> = { FUNDED: 'badge-blue', SHIPPED: 'badge-yellow', DISPUTED: 'badge-red', COMPLETED: 'badge-green', INITIATED: 'badge-gray' };
    return map[s] || 'badge-gray';
  };

  if (loading) return <div className="text-muted" style={{ padding: 40, textAlign: 'center' }}>Synchronizing audit data...</div>;
  if (!data) return <div className="text-muted" style={{ padding: 40, textAlign: 'center' }}>Failed to load dashboard.</div>;

  return (
    <div>
      <div className="stats-grid">
        {stats.map(s => (
          <div key={s.label} className="stat-card">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
               <div className="stat-icon">{s.icon}</div>
               <div className="badge badge-gray" style={{ fontSize: 8 }}>LIVE</div>
            </div>
            <div className="stat-value" style={{ color: s.color }}>{s.value}</div>
            <div className="stat-label">{s.label}</div>
            <div style={{ fontSize: 10, opacity: 0.4, marginTop: 8 }}>{s.description}</div>
          </div>
        ))}
      </div>

      <div className="section-header">
        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          <h2>Audit Intelligence</h2>
          <p className="text-muted">Real-time surveillance of vault state transitions</p>
        </div>
        <button className="btn btn-outline btn-sm">VIEW ALL LEDGERS</button>
      </div>

      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>PROTOCOL ID</th>
              <th>DESCRIPTION</th>
              <th>ORCHESTRATOR</th>
              <th>LIQUIDITY (NPR)</th>
              <th>STATUS</th>
            </tr>
          </thead>
          <tbody>
            {data.recentVaults.map(v => (
              <tr key={v.id}>
                <td className="monospace" style={{ color: 'var(--primary)' }}>{v.id}</td>
                <td style={{ fontWeight: 700, letterSpacing: -0.2 }}>{v.title}</td>
                <td className="text-muted">{v.buyer}</td>
                <td style={{ fontWeight: 600 }}>{v.amount.toLocaleString()}</td>
                <td><span className={`badge ${stateBadge(v.state)}`}>{v.state}</span></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="grid-2 mt-16" style={{ marginTop: 40 }}>
        <div className="card">
          <div className="card-title">Compliance Protocol (NRB-10)</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            {[
              ['Escrow balance reconciled', data.compliance.escrowReconciled],
              ['Audit logs ≥ 7yr retention', data.compliance.auditRetention],
              ['KYC response time ≤ 4h', data.compliance.kycResponseTime],
              ['Payment failure rate < 2%', data.compliance.paymentSuccessRate > 98],
              ['Incident reports filed', data.compliance.incidentReports === 0],
            ].map(([label, ok]) => (
              <div key={String(label)} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: 13, color: 'var(--text-muted)', fontWeight: 500 }}>{String(label)}</span>
                <span className={`badge ${ok ? 'badge-green' : 'badge-red'}`}>{ok ? 'VERIFIED' : 'FAILED'}</span>
              </div>
            ))}
          </div>
        </div>
        <div className="card">
          <div className="card-title">Infrastructure Health</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            {[
              ['invoice-generation-engine', data.health.invoiceEngine], 
              ['payout-orchestrator', data.health.payoutOrchestrator], 
              ['notification-broadcast', data.health.notificationBroadcast], 
              ['vault-expiry-watcher', data.health.vaultWatcher],
              ['ledger-hash-chain-sync', data.health.ledgerSync],
            ].map(([q, depth]) => (
              <div key={String(q)} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span className="monospace" style={{ fontSize: 11 }}>{String(q)}</span>
                <span className={`badge ${Number(depth) === 0 ? 'badge-green' : 'badge-yellow'}`}>{String(depth)} active</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
