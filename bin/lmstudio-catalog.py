#!/usr/bin/env python3
"""Model catalog browser for lmstudio-sync: staff picks + Hugging Face,
capability-aware, sized against the local machine's RAM.

Usage: lmstudio-catalog.py <query> <sort> <caps> <window> <limit> <ram_gib>
  sort:   downloads | date | params | trending
  caps:   comma list of tools,vision,reasoning (empty = no capability preference)
  window: all | month | quarter | year   (HF top-chart window)
"""
import json
import re
import sys
import time
import urllib.parse
import urllib.request

QUERY = sys.argv[1].lower().strip()
SORT = sys.argv[2] if len(sys.argv) > 2 else "downloads"
WANT = [c for c in (sys.argv[3] if len(sys.argv) > 3 else "").split(",") if c]
WINDOW = sys.argv[4] if len(sys.argv) > 4 else "all"
LIMIT = int(sys.argv[5]) if len(sys.argv) > 5 else 6
RAM = float(sys.argv[6]) if len(sys.argv) > 6 else 0
BUDGET = RAM * 0.62

BPW = {"Q8_0": 8.5, "Q8_K_XL": 8.5, "Q6_K": 6.59, "Q5_K_M": 5.69, "Q5_K_S": 5.54,
       "Q4_K_M": 4.85, "Q4_K_XL": 4.9, "Q4_K_S": 4.58, "IQ4_XS": 4.25, "IQ4_NL": 4.5,
       "Q3_K_M": 3.91, "Q3_K_L": 3.9, "Q3_K_S": 3.5, "IQ3_M": 3.66, "IQ3_XS": 3.3,
       "IQ3_XXS": 3.06, "Q2_K": 3.35, "IQ2_M": 2.7, "IQ2_XS": 2.31, "IQ2_XXS": 2.06,
       "IQ1_M": 1.75, "IQ1_S": 1.56, "F16": 16, "BF16": 16, "F32": 32}
CAP_PATTERNS = {"tools": re.compile(r"tool use|function call", re.I),
                "vision": re.compile(r"vision|image|multimodal", re.I),
                "reasoning": re.compile(r"reasoning|thinking", re.I),
                "computer": re.compile(r"computer use", re.I)}
VISION_PIPELINES = {"image-text-to-text", "any-to-any", "video-text-to-text",
                    "visual-document-retrieval", "image-text-to-text"}
ISO_FMT = "%Y-%m-%d"


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "lmstudio-sync"})
    with urllib.request.urlopen(req, timeout=25) as r:
        return r.read().decode("utf-8", "ignore")


def GiB(n): return n / 2**30


def verdict(g): return "LOADABLE" if g <= BUDGET else ("TIGHT" if g <= RAM * 0.80 else "TOO BIG")


def hf_caps(repo):
    caps = set()
    pipe = (repo.get("pipeline_tag") or "")
    tags = " ".join(repo.get("tags", [])).lower() + " " + pipe
    if pipe in VISION_PIPELINES or "vision" in tags: caps.add("vision")
    if "tool" in tags or "agentic" in tags or "function" in tags: caps.add("tools")
    if "reason" in tags: caps.add("reasoning")
    if "computer" in tags: caps.add("computer")
    return caps


def est_params_b(size_bytes, filename):
    """Estimate parameter count (billions) from a quant file's size."""
    m = re.search(r"(?:UD-|Distilled[._-])?(IQ\d[_A-Za-z]*|Q\d[_A-Za-z]*|F16|BF16|F32)", filename)
    bpw = BPW.get(m.group(1), 4.8) if m else 4.8
    return size_bytes * 8 / bpw / 1e9


def show_quants(repo_id, indent="      "):
    try:
        tree = json.loads(get(f"https://huggingface.co/api/models/{repo_id}/tree/main"))
    except Exception:
        print(f"{indent}(quant listing unavailable)"); return
    mm = min((f.get("size", 0) for f in tree if f["path"].startswith("mmproj")), default=0)
    # group shards ("-00002-of-00003") into one entry per quant
    groups = {}
    for f in tree:
        p = f["path"]
        if not p.endswith(".gguf") or p.startswith("mmproj"): continue
        stem = re.sub(r"-\d+-of-\d+$", "", p[:-5])
        label = stem.split("-")[-1]
        g = groups.setdefault(label, {"size": 0, "name": stem})
        g["size"] += f.get("size", 0)
    if not groups:
        print(f"{indent}(no root-level quant files in {repo_id})"); return
    smallest = min(groups.values(), key=lambda g: g["size"])["name"]

    def canon(lab):  # UD-Q4_K_M vs Q4_K_M count as the same quant family for collision purposes
        return re.sub(r"^(UD-|Distilled[._-])", "", lab)

    fams = {}
    for lab in groups:
        fams.setdefault(canon(lab), []).append(lab)
    for lab, g in sorted(groups.items(), key=lambda kv: kv[1]["size"]):
        gsize = GiB(g["size"])
        lab_show = lab
        if len(fams[canon(lab)]) > 1:  # disambiguate UD/MTP/MAX variants by their prefix segment
            parts = g["name"].split("-")
            lab_show = "-".join(parts[-2:])
        p = est_params_b(g["size"], g["name"])
        print(f"{indent}{lab_show:<20} {gsize:6.2f} GiB  ~{p:5.1f}B  {gsize/RAM*100:4.0f}% RAM  {verdict(gsize)}"
              f"{'   [vision: +mmproj %.1f GiB]' % GiB(mm) if mm and g['name'] == smallest else ''}")
    print(f"{indent}(repo: {repo_id})")


def cap_str(caps):
    return ",".join(sorted(caps)) if caps else "-"


def score(caps):
    return len([c for c in WANT if c in caps]) if WANT else 0


print(f"Machine: {RAM:.1f} GiB RAM  |  loadable budget ~{BUDGET:.1f} GiB (62% of RAM)"
      + (f"  |  caps first: {','.join(WANT)}" if WANT else ""))

# ---------------- staff picks ----------------
staff = []
try:
    html = get("https://lmstudio.ai/models")
    frags = re.findall(r'self\.__next_f\.push\(\[1,\s*("(?:[^"\\]|\\.)*")\]\)', html, re.S)
    blob = "".join(f.encode().decode("unicode_escape", "ignore") for f in frags)
    for i, m in enumerate(re.finditer(r'\["\$","li","([\w.-]+)",\{(.*?)\}\]\]', blob, re.S)):
        slug, body = m.group(1), m.group(2)
        t = re.search(r'"children":"([^"]{2,60})"', body)
        staff.append({"title": t.group(1) if t else slug, "slug": slug, "order": i})
except Exception as e:
    print(f"(staff catalog unavailable: {e})")


def matches(text):
    if not QUERY: return True
    toks = [t for t in re.split(r"[^a-z0-9.]+", QUERY) if t]
    return all(t in text.lower() for t in toks)


def hf_search(q, limit, sort="downloads", since=None):
    url = ("https://huggingface.co/api/models?search=" + urllib.parse.quote(q)
           + "&library=gguf&sort=" + sort + "&direction=-1&limit=" + str(limit))
    if since: url += "&created=" + since
    return json.loads(get(url))


def staff_details(slug):
    """caps, params, downloads from a staff model page."""
    caps, params, downloads = set(), 0.0, None
    try:
        html = get(f"https://lmstudio.ai/models/{slug}")
        frags = re.findall(r'self\.__next_f\.push\(\[1,\s*("(?:[^"\\]|\\.)*")\]\)', html, re.S)
        blob = "".join(f.encode().decode("unicode_escape", "ignore") for f in frags)
        # capability chips render as "children":["Trained for tool use", ...] or plain strings
        text = " ".join(re.findall(r'"children":"([^"]{4,400})"', blob)
                        + re.findall(r'"children":\["([^"\]]{4,120})"', blob))
        for cap, pat in CAP_PATTERNS.items():
            if pat.search(text): caps.add(cap)
        ps = [float(x[:-1]) for x in re.findall(r'"children":"(\d+(?:\.\d+)?)B"', blob)]
        if ps: params = max(ps)
        d = re.search(r'"children":"([\d.]+[KM]?)"\]," ","Downloads"', blob)
        if d:
            v = d.group(1)
            mult = {"K": 1e3, "M": 1e6}
            downloads = int(float(v[:-1]) * mult.get(v[-1], 1))
    except Exception:
        pass
    return caps, params, downloads


JUNK = re.compile(r"uncensored|heretic|ablated|nsfw|erot|gaslight|derpMENT", re.I)
def find_hf_repo(title):
    """Best HF GGUF repo for a staff title: direct lmstudio-community guess, then hyphen-slug,
    then token match — skipping fine-tune junk."""
    slugish = title.lower().replace(" ", "-")
    compact = title.lower().replace(" ", "")
    toks = [t for t in re.split(r"[^a-z0-9.]+", title.lower()) if len(t) > 2 and t not in
            {"pro", "mini", "max", "open", "flash", "small", "large", "lite", "air"}]
    try:
        for guess in (f"lmstudio-community/{compact.upper()}-GGUF", f"lmstudio-community/{slugish.upper()}-GGUF"):
            info = json.loads(get("https://huggingface.co/api/models/" + urllib.parse.quote(guess)))
            if info.get("id"): return info["id"], info.get("downloads", 0), (info.get("createdAt") or "")[:10]
    except Exception:
        pass
    try:
        cands = [c for c in hf_search(f"{title} GGUF", 8) if not JUNK.search(c["id"])]
        for c in cands:  # strongest: hyphenated or compact full-title substring
            rid = c["id"].lower()
            if slugish in rid or compact in rid.replace("-", ""):
                return c["id"], c.get("downloads", 0), (c.get("createdAt") or "")[:10]
        best = None
        for c in cands:  # then: all significant tokens, most downloads first
            rid = c["id"].lower()
            if toks and all(t in rid for t in toks):
                best = c; break
        if best: return best["id"], best.get("downloads", 0), (best.get("createdAt") or "")[:10]
    except Exception:
        pass
    return None, 0, None

print()
print("STAFF PICKS — lmstudio.ai catalog" + ("  (query: %s)" % QUERY if QUERY else ""))
rows = []
for e in staff:
    if not matches(e["title"] + " " + e["slug"]): continue
    caps, params, downloads = staff_details(e["slug"])
    rows.append({**e, "caps": caps, "params": params, "downloads": downloads, "date": None})
    if len(rows) >= LIMIT: break

if SORT == "date":
    # staff pages expose no publish date; curated order is the catalog's own recency ranking
    rows.sort(key=lambda r: r["order"])
elif SORT == "params":
    rows.sort(key=lambda r: (-score(r["caps"]), -r["params"]))
else:
    rows.sort(key=lambda r: (-score(r["caps"]), r["order"]))

for r in rows:
    star = "★" if WANT and score(r["caps"]) else " "
    p = f"~{r['params']:.1f}B" if r["params"] else "params ?"
    dl = f"{r['downloads']:,} dl" if r["downloads"] else "dl ?"
    print(f" {star} {r['title']}  ({r['slug']})  {p}  caps: {cap_str(r['caps'])}  {dl}")
    repo, rdownloads, rdate = find_hf_repo(r["title"])
    r["date"] = r["date"] or rdate
    if r["date"]: print(f"     published: {r['date']}")
    if repo: show_quants(repo)
    else: print(f"     (no HF GGUF match — see lmstudio.ai/models/{r['slug']})")
if not rows: print("  (no matches)")

# ---------------- hugging face ----------------
print()
print("HUGGING FACE — " + {"downloads": "most downloaded (30-day)",
                          "date": "newest published",
                          "params": "most downloaded (params shown per quant)",
                          "trending": "trending now"}.get(SORT, SORT))
hf_sort = {"date": "createdAt", "downloads": "downloads"}.get(SORT, "downloads")
if SORT == "trending":
    try:
        repos = [it["repoData"] for it in json.loads(get("https://huggingface.co/api/trending?type=model"))["recentlyTrending"]]
        repos = [r for r in repos if not r.get("private")]
    except Exception as e:
        print(f"  (trending unavailable: {e})"); repos = []
else:
    since = None
    if WINDOW == "month":   since = time.strftime("%Y-%m-%dT00:00:00Z", time.gmtime(time.time() - 30 * 86400))
    if WINDOW == "quarter": since = time.strftime("%Y-%m-%dT00:00:00Z", time.gmtime(time.time() - 91 * 86400))
    if WINDOW == "year":    since = time.strftime("%Y-%m-%dT00:00:00Z", time.gmtime(time.time() - 365 * 86400))
    try:
        repos = hf_search(QUERY or "gguf", LIMIT + 4, hf_sort, since)
    except Exception as e:
        print(f"  (HF search failed: {e})"); repos = []

shown = 0
for r in repos:
    caps = hf_caps(r)
    if WANT and not (set(WANT) & caps) and SORT != "params":
        continue  # capability-matching entries only when a caps preference is set
    shown += 1
    if shown > LIMIT: break
    star = "★" if WANT else " "
    created = (r.get("createdAt") or "")[:10]
    dl = f"{r.get('downloads',0):,} dl/{r.get('likes',0)} likes"
    print(f" {star} {r['id']}  caps: {cap_str(caps)}  {dl}" + (f"  published {created}" if created else ""))
    show_quants(r["id"])
if not shown and SORT != "trending":
    print("  (no entries matched the capability filter — try widening caps=)")
