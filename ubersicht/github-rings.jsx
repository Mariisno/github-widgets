// github-rings.jsx — Übersicht: GitHub-status som glass-kort med fargekodede tall-fliser.
// Grønt = dine ting (PR-er, issues). Amber = venter på deg (varsler, review). Grått = 0.
// Hver flis er klikkbar og åpner riktig GitHub-side.

import { run } from "uebersicht";

export const command = "__REPO_DIR__/fetch-github.sh"; // settes av install.sh
export const refreshFrequency = 60000; // 1 minutt

// [datanøkkel, etikett, ikon, farge, lenke ved klikk]
const CATS = [
  { key: "notifications",   label: "Varsler", icon: "🔔", color: "amber", link: "https://github.com/notifications" },
  { key: "reviewRequested", label: "Review",  icon: "✓",  color: "amber", link: "https://github.com/pulls/review-requested" },
  { key: "myPullRequests",  label: "PR-er",   icon: "⊙",  color: "green", link: "https://github.com/pulls" },
  { key: "assignedIssues",  label: "Issues",  icon: "◇",  color: "green", link: "https://github.com/issues/assigned" },
];

export const className = `
  top: 48px; right: 24px; width: 360px;
  font-family: -apple-system, BlinkMacSystemFont, sans-serif;
  color: #fff; -webkit-font-smoothing: antialiased;
  background: rgba(255,255,255,0.16);
  backdrop-filter: blur(28px) saturate(160%);
  -webkit-backdrop-filter: blur(28px) saturate(160%);
  border: 1px solid rgba(255,255,255,0.30);
  border-radius: 28px;
  box-shadow: 0 12px 40px rgba(0,0,0,0.28), inset 0 1px 0 rgba(255,255,255,0.25);
  padding: 18px 20px;

  .head { display:flex; align-items:center; gap:8px; font-size:15px; font-weight:600; margin-bottom:14px; }
  .head .mark { color:#30d158; }
  .err { font-size:12px; color:#f85149; }

  .tiles { display:grid; grid-template-columns:repeat(4,1fr); gap:8px; }
  .tile { border-radius:14px; padding:12px 8px 10px; display:flex; flex-direction:column;
          align-items:center; gap:4px; background:rgba(255,255,255,0.06);
          cursor:pointer; transition:transform 0.1s ease, background 0.15s ease; }
  .tile:hover { background:rgba(255,255,255,0.14); }
  .tile:active { transform:scale(0.95); }
  .tile.on-green { background:rgba(48,209,88,0.16); }
  .tile.on-amber { background:rgba(255,159,10,0.16); }
  .tile .icon { font-size:13px; opacity:0.9; }
  .tile .num { font-size:26px; font-weight:700; line-height:1; font-variant-numeric:tabular-nums; }
  .tile .num.zero  { color:rgba(255,255,255,0.40); }
  .tile .num.green { color:#30d158; }
  .tile .num.amber { color:#ff9f0a; }
  .tile .label { font-size:10.5px; color:rgba(255,255,255,0.72); }
`;

const openUrl = (url) => run(`open "${url}"`);

export const render = ({ output }) => {
  let data;
  try {
    data = JSON.parse(output);
  } catch (e) {
    return <div><div className="head"><span className="mark">◆</span><span>GitHub</span></div><div className="err">Venter på data…</div></div>;
  }
  if (!data.ok) {
    return <div><div className="head"><span className="mark">◆</span><span>GitHub</span></div><div className="err">{data.error || "Kunne ikke hente data"}</div></div>;
  }
  return (
    <div>
      <div className="head"><span className="mark">◆</span><span>GitHub</span></div>
      <div className="tiles">
        {CATS.map((c) => {
          const count = data[c.key].length;
          const on = count > 0;
          return (
            <div className={on ? `tile on-${c.color}` : "tile"} key={c.key} onClick={() => openUrl(c.link)}>
              <span className="icon">{c.icon}</span>
              <span className={on ? `num ${c.color}` : "num zero"}>{count}</span>
              <span className="label">{c.label}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
};
