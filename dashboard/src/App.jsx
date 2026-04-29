import { useEffect, useState } from "react";
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer,
  ScatterChart, Scatter, CartesianGrid, Cell,
} from "recharts";

// ── Data loading ──────────────────────────────────────────────────────────────

const BASE = import.meta.env.BASE_URL ?? "/";

async function loadJson(filename) {
  const res = await fetch(`${BASE}data/silver/${filename}`);
  if (!res.ok) throw new Error(`Failed to load ${filename}`);
  const json = await res.json();
  return json.data;
}

// ── Colour helpers ────────────────────────────────────────────────────────────

const HEALTH_COLOUR = {
  Healthy:   "bg-emerald-100 text-emerald-800",
  Monitor:   "bg-yellow-100  text-yellow-800",
  "At Risk": "bg-orange-100  text-orange-800",
  Degraded:  "bg-red-100     text-red-800",
};

const GATE_COLOUR = {
  Clear:   "bg-emerald-100 text-emerald-800",
  Blocked: "bg-red-100     text-red-800",
};

const OUTCOME_COLOUR = {
  Approved:                  "bg-emerald-100 text-emerald-800",
  "Approved with Conditions":"bg-yellow-100  text-yellow-800",
  Deferred:                  "bg-orange-100  text-orange-800",
  Pending:                   "bg-slate-100   text-slate-700",
  "Not Reviewed":            "bg-slate-100   text-slate-500",
};

const SEVERITY_COLOUR = {
  Critical: "bg-red-100     text-red-800",
  High:     "bg-orange-100  text-orange-800",
  Medium:   "bg-yellow-100  text-yellow-800",
  Low:      "bg-slate-100   text-slate-700",
};

function Badge({ label, colourClass }) {
  return (
    <span className={`inline-block rounded px-2 py-0.5 text-xs font-semibold ${colourClass ?? "bg-slate-100 text-slate-700"}`}>
      {label}
    </span>
  );
}

function fmt(n, decimals = 0) {
  if (n == null) return "—";
  return Number(n).toLocaleString("en-US", { maximumFractionDigits: decimals });
}

function fmtUsd(n) {
  if (!n) return "—";
  if (n >= 1_000_000) return `$${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000)     return `$${(n / 1_000).toFixed(0)}K`;
  return `$${n}`;
}

// ── KPI card ──────────────────────────────────────────────────────────────────

function KpiCard({ label, value, sub }) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white px-5 py-4 shadow-sm">
      <p className="text-xs font-medium uppercase tracking-wide text-slate-500">{label}</p>
      <p className="mt-1 text-3xl font-bold text-slate-900">{value}</p>
      {sub && <p className="mt-0.5 text-xs text-slate-400">{sub}</p>}
    </div>
  );
}

// ── Section wrapper ───────────────────────────────────────────────────────────

function Section({ title, children }) {
  return (
    <section className="mb-10">
      <h2 className="mb-3 text-lg font-semibold text-slate-800">{title}</h2>
      {children}
    </section>
  );
}

// ── Tables ────────────────────────────────────────────────────────────────────

function Table({ cols, rows, keyFn }) {
  return (
    <div className="overflow-x-auto rounded-xl border border-slate-200 shadow-sm">
      <table className="min-w-full divide-y divide-slate-200 text-sm">
        <thead className="bg-slate-50">
          <tr>
            {cols.map((c) => (
              <th key={c.key} className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                {c.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100 bg-white">
          {rows.map((row, i) => (
            <tr key={keyFn ? keyFn(row) : i} className="hover:bg-slate-50">
              {cols.map((c) => (
                <td key={c.key} className="whitespace-nowrap px-4 py-2.5 text-slate-700">
                  {c.render ? c.render(row) : (row[c.key] ?? "—")}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

const TABS = [
  "Executive Overview",
  "Portfolio",
  "Model Health",
  "SLA Compliance",
  "Governance",
  "Business Partner Portfolio",
];

function TabBar({ active, onChange }) {
  return (
    <div className="mb-6 flex gap-1 border-b border-slate-200">
      {TABS.map((t) => (
        <button
          key={t}
          onClick={() => onChange(t)}
          className={`px-4 py-2 text-sm font-medium transition-colors
            ${active === t
              ? "border-b-2 border-indigo-600 text-indigo-700"
              : "text-slate-500 hover:text-slate-800"
            }`}
        >
          {t}
        </button>
      ))}
    </div>
  );
}

// ── Executive Overview tab ────────────────────────────────────────────────────

function ExecutiveTab({ exec, portfolio }) {
  const totals = exec.reduce(
    (acc, r) => ({
      total_use_cases:          acc.total_use_cases          + r.total_use_cases,
      in_production:            acc.in_production            + r.in_production,
      in_flight:                acc.in_flight                + r.in_flight,
      sla_breached_stages:      acc.sla_breached_stages      + r.sla_breached_stages,
      total_stages_completed:   acc.total_stages_completed   + r.total_stages_completed,
      total_financial_realized_usd: acc.total_financial_realized_usd + (r.total_financial_realized_usd ?? 0),
      high_bias_models:         acc.high_bias_models         + r.high_bias_models,
    }),
    { total_use_cases: 0, in_production: 0, in_flight: 0,
      sla_breached_stages: 0, total_stages_completed: 0,
      total_financial_realized_usd: 0, high_bias_models: 0 }
  );

  const slaCompliancePct = totals.total_stages_completed > 0
    ? (100 * (totals.total_stages_completed - totals.sla_breached_stages) / totals.total_stages_completed).toFixed(1)
    : "N/A";

  const blocked = portfolio.filter((p) => p.gate_status === "Blocked").length;

  return (
    <>
      {/* KPIs */}
      <div className="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
        <KpiCard label="Total Use Cases"   value={totals.total_use_cases}         />
        <KpiCard label="In Production"     value={totals.in_production}           />
        <KpiCard label="In Flight"         value={totals.in_flight}               />
        <KpiCard label="SLA Compliance"    value={`${slaCompliancePct}%`}         />
        <KpiCard label="Blocked Gates"     value={blocked}                        />
        <KpiCard label="Financial Value"   value={fmtUsd(totals.total_financial_realized_usd)} sub="realized YTD" />
      </div>

      {/* Business unit table */}
      <Table
        rows={exec}
        keyFn={(r) => r.business_unit_id}
        cols={[
          { key: "business_unit",        label: "Business Unit" },
          { key: "division",             label: "Division" },
          { key: "total_use_cases",      label: "Use Cases" },
          { key: "in_production",        label: "In Prod" },
          { key: "in_flight",            label: "In Flight" },
          { key: "sla_compliance_pct",   label: "SLA %",
            render: (r) => `${r.sla_compliance_pct ?? 100}%` },
          { key: "avg_risk_score",       label: "Avg Risk",
            render: (r) => fmt(r.avg_risk_score, 0) },
          { key: "total_financial_realized_usd", label: "Value Realized",
            render: (r) => fmtUsd(r.total_financial_realized_usd) },
          { key: "high_bias_models",     label: "High-Bias Models",
            render: (r) => r.high_bias_models > 0
              ? <Badge label={r.high_bias_models} colourClass="bg-red-100 text-red-800" />
              : "0" },
        ]}
      />
    </>
  );
}

// ── Portfolio tab ─────────────────────────────────────────────────────────────

function PortfolioTab({ portfolio }) {
  const [search, setSearch] = useState("");
  const [stageFilter, setStageFilter] = useState("All");

  const stages = ["All", ...new Set(portfolio.map((r) => r.current_stage_name).filter(Boolean))];

  const rows = portfolio.filter((r) => {
    const matchSearch = !search || r.use_case_name.toLowerCase().includes(search.toLowerCase())
      || r.use_case_code.toLowerCase().includes(search.toLowerCase());
    const matchStage = stageFilter === "All" || r.current_stage_name === stageFilter;
    return matchSearch && matchStage;
  });

  return (
    <>
      <div className="mb-4 flex gap-3">
        <input
          className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400"
          placeholder="Search use cases…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <select
          className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400"
          value={stageFilter}
          onChange={(e) => setStageFilter(e.target.value)}
        >
          {stages.map((s) => <option key={s}>{s}</option>)}
        </select>
        <span className="ml-auto self-center text-xs text-slate-400">{rows.length} use cases</span>
      </div>

      <Table
        rows={rows}
        keyFn={(r) => r.use_case_id}
        cols={[
          { key: "use_case_code",    label: "Code" },
          { key: "use_case_name",    label: "Use Case",
            render: (r) => <span className="max-w-xs truncate block">{r.use_case_name}</span> },
          { key: "business_unit",    label: "Business Unit" },
          { key: "priority",         label: "Priority" },
          { key: "current_stage_name", label: "Stage" },
          { key: "gate_status",      label: "Gate",
            render: (r) => <Badge label={r.gate_status} colourClass={GATE_COLOUR[r.gate_status]} /> },
          { key: "last_review_outcome", label: "Last Review",
            render: (r) => <Badge label={r.last_review_outcome} colourClass={OUTCOME_COLOUR[r.last_review_outcome]} /> },
          { key: "total_sla_breaches", label: "SLA Breaches" },
          { key: "last_risk_score",  label: "Risk Score" },
        ]}
      />
    </>
  );
}

// ── Model Health tab ──────────────────────────────────────────────────────────

function ModelHealthTab({ modelHealth }) {
  // Deduplicate to latest monitoring row per model
  const latest = Object.values(
    modelHealth.reduce((acc, r) => {
      if (!acc[r.model_id] || r.monitoring_date > acc[r.model_id].monitoring_date) {
        acc[r.model_id] = r;
      }
      return acc;
    }, {})
  );

  const healthCounts = latest.reduce((acc, r) => {
    acc[r.health_status] = (acc[r.health_status] ?? 0) + 1;
    return acc;
  }, {});

  return (
    <>
      <div className="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
        {["Healthy", "Monitor", "At Risk", "Degraded"].map((h) => (
          <KpiCard key={h} label={h} value={healthCounts[h] ?? 0} />
        ))}
      </div>

      <Table
        rows={latest}
        keyFn={(r) => r.model_id}
        cols={[
          { key: "model_code",         label: "Model" },
          { key: "model_type",         label: "Type" },
          { key: "deployment_env",     label: "Env" },
          { key: "risk_tier",          label: "Risk Tier" },
          { key: "health_status",      label: "Health",
            render: (r) => <Badge label={r.health_status} colourClass={HEALTH_COLOUR[r.health_status]} /> },
          { key: "model_performance_score", label: "Perf Score",
            render: (r) => fmt(r.model_performance_score * 100, 1) + "%" },
          { key: "f1_score",           label: "F1",
            render: (r) => fmt(r.f1_score, 3) },
          { key: "drift_score",        label: "Drift",
            render: (r) => fmt(r.drift_score, 3) },
          { key: "bias_assessment",    label: "Bias" },
          { key: "alert_triggered",    label: "Alert",
            render: (r) => r.alert_triggered ? <Badge label={r.alert_type} colourClass="bg-red-100 text-red-800" /> : "—" },
          { key: "retrain_required",   label: "Retrain",
            render: (r) => r.retrain_required ? <Badge label="Yes" colourClass="bg-orange-100 text-orange-800" /> : "No" },
        ]}
      />
    </>
  );
}

// ── SLA Compliance tab ────────────────────────────────────────────────────────

function SlaTab({ sla }) {
  const open   = sla.filter((r) => r.breach_resolution_status === "Open").length;
  const resolved = sla.filter((r) => r.breach_resolution_status === "Resolved").length;
  const escalated = sla.filter((r) => r.escalated).length;
  const avgDays = sla.length
    ? (sla.reduce((a, r) => a + r.days_over_sla, 0) / sla.length).toFixed(1)
    : 0;

  return (
    <>
      <div className="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
        <KpiCard label="Total Breaches"  value={sla.length} />
        <KpiCard label="Open"            value={open} />
        <KpiCard label="Resolved"        value={resolved} />
        <KpiCard label="Avg Days Over"   value={avgDays} />
      </div>

      <Table
        rows={sla}
        keyFn={(r) => r.breach_id}
        cols={[
          { key: "use_case_code",  label: "Use Case" },
          { key: "stage_name",     label: "Stage" },
          { key: "breach_date",    label: "Date" },
          { key: "days_over_sla",  label: "Days Over SLA" },
          { key: "breach_severity",label: "Severity",
            render: (r) => <Badge label={r.breach_severity} colourClass={SEVERITY_COLOUR[r.breach_severity]} /> },
          { key: "breach_resolution_status", label: "Status",
            render: (r) => <Badge label={r.breach_resolution_status}
              colourClass={r.breach_resolution_status === "Resolved" ? "bg-emerald-100 text-emerald-800" : "bg-red-100 text-red-800"} /> },
          { key: "escalated",      label: "Escalated",
            render: (r) => r.escalated ? <Badge label="Yes" colourClass="bg-orange-100 text-orange-800" /> : "No" },
          { key: "stage_owner",    label: "Owner" },
          { key: "breach_reason",  label: "Reason",
            render: (r) => <span className="block max-w-xs truncate" title={r.breach_reason}>{r.breach_reason}</span> },
        ]}
      />
    </>
  );
}

// ── Governance tab ────────────────────────────────────────────────────────────

function GovernanceTab({ governance }) {
  const approved = governance.filter((r) => r.review_outcome === "Approved").length;
  const conditional = governance.filter((r) => r.review_outcome === "Approved with Conditions").length;
  const overdue = governance.filter((r) => r.review_health === "Overdue").length;
  const critical = governance.filter((r) => r.critical_findings > 0).length;

  return (
    <>
      <div className="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
        <KpiCard label="Total Reviews"         value={governance.length} />
        <KpiCard label="Approved"              value={approved} />
        <KpiCard label="With Conditions"       value={conditional} />
        <KpiCard label="Critical Findings"     value={critical} />
      </div>

      {overdue > 0 && (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          ⚠ {overdue} review{overdue > 1 ? "s are" : " is"} overdue for renewal.
        </div>
      )}

      <Table
        rows={governance}
        keyFn={(r) => r.review_id}
        cols={[
          { key: "use_case_code",   label: "Use Case" },
          { key: "risk_tier",       label: "Risk Tier" },
          { key: "review_type",     label: "Type" },
          { key: "review_date",     label: "Date" },
          { key: "review_outcome",  label: "Outcome",
            render: (r) => <Badge label={r.review_outcome} colourClass={OUTCOME_COLOUR[r.review_outcome]} /> },
          { key: "gate_status",     label: "Gate",
            render: (r) => <Badge label={r.gate_status} colourClass={GATE_COLOUR[r.gate_status]} /> },
          { key: "risk_score",      label: "Risk Score" },
          { key: "critical_findings", label: "Critical",
            render: (r) => r.critical_findings > 0
              ? <Badge label={r.critical_findings} colourClass="bg-red-100 text-red-800" />
              : "0" },
          { key: "review_health",   label: "Health",
            render: (r) => <Badge label={r.review_health}
              colourClass={
                r.review_health === "Overdue"   ? "bg-red-100 text-red-800" :
                r.review_health === "Due Soon"  ? "bg-yellow-100 text-yellow-800" :
                r.review_health === "On Track"  ? "bg-emerald-100 text-emerald-800" :
                "bg-slate-100 text-slate-600"
              } /> },
          { key: "reviewer_name",   label: "Reviewer" },
        ]}
      />
    </>
  );
}

// ── Business Partner Portfolio tab ───────────────────────────────────────────

const RISK_COLOUR_MAP = {
  Critical: "#dc2626",
  High:     "#ea580c",
  Medium:   "#ca8a04",
  Low:      "#16a34a",
};

const HANDOFF_COLOUR = {
  "Not Ready":   "bg-slate-100   text-slate-600",
  "Ready":       "bg-yellow-100  text-yellow-800",
  "In Delivery": "bg-blue-100    text-blue-800",
  "Live":        "bg-emerald-100 text-emerald-800",
};

function BpPortfolioTab({ bp }) {
  // 1. Demand by function: count of use cases
  const demandByFunction = Object.entries(
    bp.reduce((acc, r) => {
      acc[r.business_function] = (acc[r.business_function] ?? 0) + 1;
      return acc;
    }, {})
  )
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count);

  // 2. Value hypothesis by BU: sum of estimated_value_usd
  const valueByBu = Object.entries(
    bp.reduce((acc, r) => {
      acc[r.business_function] = (acc[r.business_function] ?? 0) + Number(r.estimated_value_usd);
      return acc;
    }, {})
  )
    .map(([name, value]) => ({ name, value: Math.round(value / 1000) }))
    .sort((a, b) => b.value - a.value);

  // 3. Scatter: feasibility vs org readiness, coloured by risk tier
  const scatterData = bp.map((r) => ({
    x: r.feasibility_score,
    y: r.organizational_readiness_score,
    name: r.business_unit,
    risk: r.risk_tier,
    fn: r.business_function,
  }));

  // 4. Reuse candidates
  const reuseCandidates = bp.filter((r) => r.reuse_candidate_flag);

  // 5. Ready for handoff (Ready or In Delivery)
  const handoffReady = bp.filter(
    (r) => r.delivery_handoff_status === "Ready" || r.delivery_handoff_status === "In Delivery"
  );

  // 6. Strategic risk: High/Critical + feasibility <= 2
  const atRisk = bp.filter((r) => r.strategic_risk_flag);

  const totalValue = bp.reduce((s, r) => s + Number(r.estimated_value_usd), 0);

  return (
    <>
      {/* KPI strip */}
      <div className="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-4 lg:grid-cols-6">
        <KpiCard label="Total Initiatives"      value={bp.length} />
        <KpiCard label="Est. Portfolio Value"   value={fmtUsd(totalValue)} sub="synthetic" />
        <KpiCard label="Reuse Candidates"       value={reuseCandidates.length} />
        <KpiCard label="Ready for Handoff"      value={handoffReady.length} />
        <KpiCard label="Live"                   value={bp.filter(r => r.delivery_handoff_status === "Live").length} />
        <KpiCard label="Strategic Risk"         value={atRisk.length} sub="High/Critical + low feasibility" />
      </div>

      {/* Charts row */}
      <div className="mb-6 grid grid-cols-1 gap-6 lg:grid-cols-3">

        {/* Demand by function */}
        <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
          <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
            Business Demand by Function
          </p>
          <ResponsiveContainer width="100%" height={180}>
            <BarChart data={demandByFunction} layout="vertical" margin={{ left: 8, right: 16 }}>
              <XAxis type="number" tick={{ fontSize: 11 }} allowDecimals={false} />
              <YAxis type="category" dataKey="name" width={90} tick={{ fontSize: 11 }} />
              <Tooltip formatter={(v) => [v, "Use Cases"]} />
              <Bar dataKey="count" fill="#6366f1" radius={[0, 3, 3, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Value hypothesis by function */}
        <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
          <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-slate-500">
            Est. Value by Function ($000s)
          </p>
          <ResponsiveContainer width="100%" height={180}>
            <BarChart data={valueByBu} layout="vertical" margin={{ left: 8, right: 16 }}>
              <XAxis type="number" tick={{ fontSize: 11 }} />
              <YAxis type="category" dataKey="name" width={90} tick={{ fontSize: 11 }} />
              <Tooltip formatter={(v) => [`$${v}K`, "Est. Value"]} />
              <Bar dataKey="value" fill="#0ea5e9" radius={[0, 3, 3, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Feasibility vs Readiness scatter */}
        <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
          <p className="mb-1 text-xs font-semibold uppercase tracking-wide text-slate-500">
            Feasibility vs. Org Readiness
          </p>
          <p className="mb-2 text-xs text-slate-400">Colour = risk tier</p>
          <ResponsiveContainer width="100%" height={180}>
            <ScatterChart margin={{ top: 4, right: 8, bottom: 4, left: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
              <XAxis dataKey="x" type="number" domain={[0, 6]} label={{ value: "Feasibility", position: "insideBottom", offset: -2, fontSize: 10 }} tick={{ fontSize: 10 }} />
              <YAxis dataKey="y" type="number" domain={[0, 6]} label={{ value: "Org Readiness", angle: -90, position: "insideLeft", fontSize: 10 }} tick={{ fontSize: 10 }} />
              <Tooltip
                content={({ payload }) => {
                  if (!payload?.length) return null;
                  const d = payload[0].payload;
                  return (
                    <div className="rounded bg-white p-2 text-xs shadow border border-slate-200">
                      <p className="font-semibold">{d.fn}</p>
                      <p>Feasibility: {d.x} | Readiness: {d.y}</p>
                      <p>Risk: {d.risk}</p>
                    </div>
                  );
                }}
              />
              <Scatter data={scatterData} isAnimationActive={false}>
                {scatterData.map((d, i) => (
                  <Cell key={i} fill={RISK_COLOUR_MAP[d.risk] ?? "#94a3b8"} />
                ))}
              </Scatter>
            </ScatterChart>
          </ResponsiveContainer>
          <div className="mt-2 flex flex-wrap gap-2">
            {Object.entries(RISK_COLOUR_MAP).map(([tier, colour]) => (
              <span key={tier} className="flex items-center gap-1 text-xs text-slate-600">
                <span className="inline-block h-2.5 w-2.5 rounded-full" style={{ backgroundColor: colour }} />
                {tier}
              </span>
            ))}
          </div>
        </div>
      </div>

      {/* Reuse candidates */}
      <Section title="Reuse Candidates">
        <Table
          rows={reuseCandidates}
          keyFn={(r) => r.bp_id}
          cols={[
            { key: "business_function",         label: "Function" },
            { key: "business_unit",             label: "Business Unit" },
            { key: "recommended_solution_pattern", label: "Solution Pattern" },
            { key: "delivery_handoff_status",   label: "Status",
              render: (r) => <Badge label={r.delivery_handoff_status} colourClass={HANDOFF_COLOUR[r.delivery_handoff_status]} /> },
            { key: "success_metric",            label: "Success Metric",
              render: (r) => <span className="block max-w-xs truncate text-xs" title={r.success_metric}>{r.success_metric}</span> },
          ]}
        />
      </Section>

      {/* Ready for handoff */}
      <Section title="Initiatives Ready for Delivery Handoff">
        {handoffReady.length === 0
          ? <p className="text-sm text-slate-500">No initiatives currently in Ready or In Delivery status.</p>
          : (
            <Table
              rows={handoffReady}
              keyFn={(r) => r.bp_id}
              cols={[
                { key: "business_function",   label: "Function" },
                { key: "business_unit",       label: "Business Unit" },
                { key: "business_problem",    label: "Business Problem",
                  render: (r) => <span className="block max-w-sm truncate text-xs" title={r.business_problem}>{r.business_problem}</span> },
                { key: "estimated_value_usd", label: "Est. Value",
                  render: (r) => fmtUsd(Number(r.estimated_value_usd)) },
                { key: "delivery_handoff_status", label: "Status",
                  render: (r) => <Badge label={r.delivery_handoff_status} colourClass={HANDOFF_COLOUR[r.delivery_handoff_status]} /> },
                { key: "roadmap_quarter",     label: "Quarter" },
                { key: "risk_tier",           label: "Risk",
                  render: (r) => <Badge label={r.risk_tier} colourClass={
                    r.risk_tier === "Critical" ? "bg-red-100 text-red-800" :
                    r.risk_tier === "High"     ? "bg-orange-100 text-orange-800" :
                    r.risk_tier === "Medium"   ? "bg-yellow-100 text-yellow-800" :
                    "bg-slate-100 text-slate-600"
                  } /> },
              ]}
            />
          )
        }
      </Section>

      {/* Strategic risk */}
      <Section title="Strategic Initiatives at Risk">
        <p className="mb-3 text-xs text-slate-500">
          Defined as risk tier High or Critical with feasibility score of 2 or below.
          These require active business partner intervention before roadmap commitment.
        </p>
        {atRisk.length === 0
          ? <p className="text-sm text-emerald-600 font-medium">No initiatives meet the at-risk criteria.</p>
          : (
            <Table
              rows={atRisk}
              keyFn={(r) => r.bp_id}
              cols={[
                { key: "business_function",   label: "Function" },
                { key: "business_unit",       label: "Business Unit" },
                { key: "business_problem",    label: "Business Problem",
                  render: (r) => <span className="block max-w-sm truncate text-xs" title={r.business_problem}>{r.business_problem}</span> },
                { key: "risk_tier",           label: "Risk Tier",
                  render: (r) => <Badge label={r.risk_tier} colourClass="bg-red-100 text-red-800" /> },
                { key: "feasibility_score",   label: "Feasibility (1-5)" },
                { key: "organizational_readiness_score", label: "Org Readiness (1-5)" },
                { key: "value_hypothesis",    label: "Value Hypothesis",
                  render: (r) => <span className="block max-w-sm truncate text-xs" title={r.value_hypothesis}>{r.value_hypothesis}</span> },
              ]}
            />
          )
        }
      </Section>
    </>
  );
}

// ── Root ──────────────────────────────────────────────────────────────────────

export default function App() {
  const [tab, setTab] = useState(TABS[0]);
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    Promise.all([
      loadJson("executive_delivery.json"),
      loadJson("portfolio_summary.json"),
      loadJson("model_health.json"),
      loadJson("sla_compliance.json"),
      loadJson("governance_status.json"),
      loadJson("bp_portfolio.json"),
    ])
      .then(([exec, portfolio, modelHealth, sla, governance, bp]) =>
        setData({ exec, portfolio, modelHealth, sla, governance, bp })
      )
      .catch((e) => setError(e.message));
  }, []);

  if (error) return (
    <div className="flex h-screen items-center justify-center text-red-600">
      Failed to load data: {error}
    </div>
  );

  if (!data) return (
    <div className="flex h-screen items-center justify-center text-slate-500">
      Loading…
    </div>
  );

  return (
    <div className="min-h-screen bg-slate-50 font-sans text-slate-900">
      {/* Header */}
      <header className="border-b border-slate-200 bg-white px-8 py-4 shadow-sm">
        <div className="mx-auto max-w-screen-xl flex items-center justify-between">
          <div>
            <h1 className="text-xl font-bold tracking-tight text-slate-900">
              AI Solution Delivery Control Tower
            </h1>
            <p className="text-xs text-slate-400 mt-0.5">Portfolio · Governance · Model Health · SLA · Business Partner</p>
          </div>
          <span className="rounded bg-indigo-50 px-2 py-1 text-xs font-medium text-indigo-700">
            Synthetic Data — Portfolio Project
          </span>
        </div>
      </header>

      {/* Main */}
      <main className="mx-auto max-w-screen-xl px-8 py-8">
        <TabBar active={tab} onChange={setTab} />

        {tab === "Executive Overview" && (
          <Section title="Executive Overview">
            <ExecutiveTab exec={data.exec} portfolio={data.portfolio} />
          </Section>
        )}
        {tab === "Portfolio" && (
          <Section title="AI Use Case Portfolio">
            <PortfolioTab portfolio={data.portfolio} />
          </Section>
        )}
        {tab === "Model Health" && (
          <Section title="Model Health Monitor">
            <ModelHealthTab modelHealth={data.modelHealth} />
          </Section>
        )}
        {tab === "SLA Compliance" && (
          <Section title="SLA Compliance — Breach Log">
            <SlaTab sla={data.sla} />
          </Section>
        )}
        {tab === "Governance" && (
          <Section title="Governance Review Status">
            <GovernanceTab governance={data.governance} />
          </Section>
        )}
        {tab === "Business Partner Portfolio" && (
          <Section title="Data & AI Business Partner Portfolio">
            <BpPortfolioTab bp={data.bp} />
          </Section>
        )}
      </main>
    </div>
  );
}
