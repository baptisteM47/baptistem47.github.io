(function () {
  "use strict";

  const $ = (sel, root = document) => root.querySelector(sel);
  const el = (tag, attrs = {}, ...children) => {
    const node = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs)) {
      if (v == null || v === false) continue;
      if (k === "class") node.className = v;
      else if (k.startsWith("on")) node.addEventListener(k.slice(2), v);
      else node.setAttribute(k, v === true ? "" : v);
    }
    for (const c of children.flat()) if (c != null) node.append(c.nodeType ? c : document.createTextNode(c));
    return node;
  };
  const store = {
    get(k) { try { return localStorage.getItem(k); } catch (e) { return null; } },
    set(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }
  };

  /* ---------- state ---------- */
  const params = new URLSearchParams(location.search);
  let lang = params.get("lang") || store.get("bm-lang") ||
    ((navigator.language || "fr").toLowerCase().startsWith("fr") ? "fr" : "en");
  if (!["fr", "en"].includes(lang)) lang = "fr";
  let theme = null;
  const openCourses = new Set();

  const t = (obj) => (obj && typeof obj === "object" ? (obj[lang] ?? obj.fr) : obj);
  const ui = () => UI[lang];
  const getPath = (o, path) => path.split(".").reduce((a, k) => (a ? a[k] : undefined), o);
  const byId = (id) => PROJECTS.find((p) => p.id === id);
  const metricValue = (p) => (lang === "en" && p.metric.valueEn) ? p.metric.valueEn : p.metric.value;
  const fmtMonth = (ym) => {
    const [y, m] = ym.split("-").map(Number);
    const s = new Date(y, m - 1, 1).toLocaleDateString(lang === "fr" ? "fr-FR" : "en-GB", { month: "long", year: "numeric" });
    return s.charAt(0).toUpperCase() + s.slice(1);
  };
  const TOOL_NAMES = { r: "R", python: "Python", stata: "Stata" };
  const tools = (p) => p.skills.filter((s) => TOOL_NAMES[s]).map((s) => TOOL_NAMES[s]);

  /* ---------- static text ---------- */
  function renderStatic() {
    document.documentElement.lang = lang;
    document.title = lang === "fr" ? "Baptiste Messant, CV" : "Baptiste Messant, résumé";
    document.querySelectorAll("[data-i18n]").forEach((n) => { n.textContent = getPath(ui(), n.dataset.i18n); });
    $("#role").textContent = t(PROFILE.role);
    $("#pitch").textContent = t(PROFILE.pitch);
    $("#status").textContent = t(PROFILE.status);
    $("#cta-projects").textContent = ui().ctaProjects;
    $("#cta-path").textContent = ui().ctaPath;
    $("#print-btn").textContent = ui().print;
    const lt = $("#lang-toggle");
    lt.textContent = ui().langSwitch;
    lt.setAttribute("aria-label", ui().langSwitchLabel);
    lt.setAttribute("lang", lang === "fr" ? "en" : "fr");
    $("#theme-toggle").setAttribute("aria-label", ui().themeLabel);
    $(".skip").textContent = lang === "fr" ? "Aller au contenu" : "Skip to content";
    $("#dlg-close").setAttribute("aria-label", ui().close);
    $("#curve-cap").textContent = ui().curveCaption;
    for (const id of ["#profile-links", "#footer-links"]) {
      $(id).replaceChildren(...PROFILE.links.map((l) =>
        el("li", {}, el("a", { href: l.url, target: "_blank", rel: "noopener" }, l.label))));
    }
  }

  /* ---------- career curve ---------- */
  function goToStep(id) {
    const node = document.getElementById(id);
    if (!node) return;
    node.scrollIntoView({ block: "center" });
    node.classList.remove("flash");
    void node.offsetWidth;
    node.classList.add("flash");
  }

  function renderCurve() {
    const svg = $("#curve-svg");
    const narrow = svg.parentElement.clientWidth < 520;
    const W = narrow ? 420 : 560, H = narrow ? 300 : 330, padL = 8, padR = 24, padT = 34, padB = 34;
    svg.setAttribute("viewBox", `0 0 ${W} ${H}`);
    const t0 = 2021, t1 = 2027;
    const x = (v) => padL + ((v - t0) / (t1 - t0)) * (W - padL - padR);
    const y = (v) => H - padB - v * (H - padT - padB);
    const pts = CAREER.map((p) => [x(p.t), y(p.y)]);
    let d = `M${pts[0][0]},${pts[0][1]}`;
    for (let i = 0; i < pts.length - 1; i++) {
      const p0 = pts[i - 1] || pts[i], p1 = pts[i], p2 = pts[i + 1], p3 = pts[i + 2] || p2;
      const c1 = [p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6];
      const c2 = [p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6];
      d += ` C${c1[0]},${c1[1]} ${c2[0]},${c2[1]} ${p2[0]},${p2[1]}`;
    }
    const base = H - padB;
    const ns = "http://www.w3.org/2000/svg";
    const s = (tag, attrs, text) => {
      const n = document.createElementNS(ns, tag);
      for (const [k, v] of Object.entries(attrs)) n.setAttribute(k, v);
      if (text != null) n.textContent = text;
      return n;
    };
    svg.replaceChildren();
    svg.append(s("path", { class: "area", d: `${d} L${pts.at(-1)[0]},${base} L${pts[0][0]},${base} Z` }));
    svg.append(s("line", { class: "axis", x1: padL, x2: W - padR, y1: base, y2: base }));
    for (let yr = 2021; yr <= 2026; yr++) svg.append(s("text", { class: "tick", x: x(yr), y: H - 10, "text-anchor": "middle" }, String(yr)));
    svg.append(s("path", { class: "line", d }));

    CAREER.forEach((p, i) => {
      const [px, py] = pts[i];
      const g = s("g", { class: "pt" + (p.current ? " current" : ""), tabindex: "0", role: "link" });
      const label = t(p.label);
      g.setAttribute("aria-label", label);
      const right = px < W * 0.55;
      g.append(s("circle", { class: "hit", cx: px, cy: py, r: 18 }));
      g.append(s("circle", { class: "mark", cx: px, cy: py, r: 6 }));
      const txt = s("text", { x: right ? px + 14 : px - 14, y: py + 4, "text-anchor": right ? "start" : "end" }, label);
      g.append(txt);
      const go = () => goToStep(p.target);
      g.addEventListener("click", go);
      g.addEventListener("keydown", (e) => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); go(); } });
      svg.append(g);
      requestAnimationFrame(() => {
        try {
          const bb = txt.getBBox();
          g.insertBefore(s("rect", { class: "label-bg", x: bb.x - 4, y: bb.y - 2, width: bb.width + 8, height: bb.height + 4, rx: 4 }), txt);
        } catch (e) {}
      });
    });
  }

  /* ---------- timeline ---------- */
  function renderTimeline() {
    $("#timeline").replaceChildren(...TIMELINE.map((step) => {
      const open = openCourses.has(step.id);
      const listId = "courses-" + step.id;
      const content = el("div", { class: "tl-body" },
        step.current ? el("p", { class: "now" }, ui().now) : null,
        el("h3", {}, t(step.title)),
        el("p", { class: "org" }, el("strong", {}, step.org), step.kind ? ", " + t(step.kind) : null),
        step.note ? el("p", { class: "note" }, t(step.note)) : null,
        step.bullets ? el("ul", { class: "bullets" }, t(step.bullets).map((b) => el("li", {}, b))) : null,
        step.tags ? el("div", { class: "tags" }, step.tags.map((x) => el("span", { class: "tag" }, x))) : null,
        step.projects ? el("div", { class: "tl-projects" },
          el("p", { class: "tl-label" }, ui().projectsDone + " (" + step.projects.length + ")"),
          el("ul", {}, step.projects.map((pid) => {
            const p = byId(pid);
            return el("li", {}, el("button", { class: "proj-link", type: "button", onclick: () => openProject(pid) }, t(p.title)));
          }))) : null,
        step.courses ? el("button", {
          class: "toggle", type: "button", "aria-expanded": String(open), "aria-controls": listId,
          onclick: () => { open ? openCourses.delete(step.id) : openCourses.add(step.id); renderTimeline(); }
        }, open ? ui().hideCourses : ui().showCourses) : null,
        step.courses ? el("ul", { class: "courses", id: listId, hidden: !open }, step.courses.map((c) => el("li", {}, c[lang]))) : null
      );
      return el("li", { class: `tl-item ${step.type}${step.current ? " current" : ""}`, id: step.id },
        el("div", { class: "tl-period" }, t(step.period)),
        el("div", { class: "tl-rail", "aria-hidden": "true" }, el("span", { class: "mark " + step.type })),
        content);
    }));
    $("#summer-list").replaceChildren(...SUMMER_JOBS.map((j) => el("li", {}, el("b", {}, j.year), j[lang])));
  }

  /* ---------- projects ---------- */
  function renderFilters() {
    const mk = (id, label, n) => el("button", {
      class: "filter", type: "button", "aria-pressed": String(theme === id),
      onclick: () => { theme = id; renderFilters(); renderProjects(); }
    }, label, el("span", { class: "n" }, String(n)));
    $("#filters").replaceChildren(
      mk(null, ui().all, PROJECTS.length),
      ...THEMES.map((th) => mk(th.id, th[lang], PROJECTS.filter((p) => p.themes.includes(th.id)).length))
    );
  }

  function sparkline() {
    const ns = "http://www.w3.org/2000/svg";
    const v = CPU_SERIES.values, W = 600, H = 120, pad = 6;
    const min = Math.min(...v), max = Math.max(...v);
    const x = (i) => pad + (i / (v.length - 1)) * (W - 2 * pad);
    const y = (val) => H - pad - ((val - min) / (max - min)) * (H - 2 * pad);
    const [sy, sm] = CPU_SERIES.start.split("-").map(Number);
    const idx = (ym) => { const [yy, mm] = ym.split("-").map(Number); return (yy - sy) * 12 + (mm - sm); };
    const svg = document.createElementNS(ns, "svg");
    svg.setAttribute("viewBox", `0 0 ${W} ${H}`);
    svg.setAttribute("preserveAspectRatio", "none");
    svg.setAttribute("aria-hidden", "true");
    const path = document.createElementNS(ns, "path");
    path.setAttribute("d", v.map((val, i) => (i ? "L" : "M") + x(i).toFixed(1) + "," + y(val).toFixed(1)).join(""));
    path.setAttribute("class", "spark-line");
    path.setAttribute("vector-effect", "non-scaling-stroke");
    svg.append(path);
    const wrap = el("div", { class: "spark" }, svg);
    CPU_SERIES.spikes.forEach((ym) => {
      const i = idx(ym);
      const dot = el("span", { class: "spark-dot" });
      dot.style.left = (x(i) / W * 100) + "%";
      dot.style.top = (y(v[i]) / H * 100) + "%";
      wrap.append(dot);
    });
    return el("figure", { class: "spark-fig" }, wrap, el("figcaption", {}, ui().sparkCaption));
  }

  function projectLinks(p, max) {
    const main = p.links.filter((l) => l.kind !== "data" && l.kind !== "slides").slice(0, max);
    return main.map((l) => el("a", { class: "link-btn", href: l.href, target: "_blank", rel: "noopener" }, ui().linkKinds[l.kind]));
  }

  function renderProjects() {
    const vis = PROJECTS.filter((p) => !theme || p.themes.includes(theme));
    const cards = vis.map((p) => {
      const titleId = "pt-" + p.id;
      const body = el("div", { class: "card-main" },
        el("p", { class: "meta" },
          el("span", {}, p.featured ? ui().featured : t(p.context)),
          el("span", {}, fmtMonth(p.date))),
        el("h3", { id: titleId },
          el("button", { class: "card-title", type: "button", onclick: () => openProject(p.id) }, t(p.title))),
        el("p", { class: "question" }, t(p.question)),
        el("p", { class: "result" }, el("span", { class: "result-label" }, ui().keyResult), el("b", {}, metricValue(p)), " " + t(p.metric.label)),
        el("div", { class: "card-foot" },
          el("div", { class: "actions" },
            el("button", { class: "link-btn primary", type: "button", onclick: () => openProject(p.id), "aria-describedby": titleId }, ui().details),
            projectLinks(p, 2)),
          el("span", { class: "tools" }, tools(p).join(", ")))
      );
      return el("article", { class: "project" + (p.featured ? " featured" : ""), "data-id": p.id, "aria-labelledby": titleId },
        body, p.featured ? sparkline() : null);
    });
    if (!cards.length) cards.push(el("p", { class: "empty" }, ui().noProjects));
    $("#project-list").replaceChildren(...cards);
  }

  /* ---------- project dialog ---------- */
  const dlg = $("#project-dialog");
  let lastFocus = null;

  function openProject(id, push = true) {
    const p = byId(id);
    if (!p) return;
    if (!dlg.open) lastFocus = document.activeElement;
    const L = ui();
    $("#dlg-body").replaceChildren(
      el("p", { class: "context" }, t(p.context) + ", " + fmtMonth(p.date).toLowerCase()),
      el("h2", { id: "dlg-title" }, t(p.title)),
      el("p", { class: "coauthors" }, L.with + " " + p.coauthors),
      el("div", { class: "actions top" }, p.links.map((l, i) =>
        el("a", { class: "link-btn" + (i === 0 ? " primary" : ""), href: l.href, target: "_blank", rel: "noopener" }, L.linkKinds[l.kind]))),
      el("div", { class: "stat" }, el("b", {}, metricValue(p)), el("span", {}, t(p.metric.label))),
      el("h3", {}, L.question), el("p", {}, t(p.question)),
      el("h3", {}, L.method), el("p", {}, t(p.method)),
      el("h3", {}, L.results), el("ul", {}, t(p.results).map((r) => el("li", {}, r))),
      p.figure ? el("figure", {},
        el("img", { src: p.figure.src, alt: t(p.figure.alt), loading: "lazy" }),
        el("figcaption", {}, t(p.figure.alt))) : null
    );
    if (!dlg.open) dlg.showModal();
    dlg.scrollTop = 0;
    if (push && location.hash !== "#p-" + id) history.pushState(null, "", "#p-" + id);
  }

  dlg.addEventListener("close", () => {
    if (location.hash.startsWith("#p-")) history.pushState(null, "", location.pathname + location.search);
    if (lastFocus && document.contains(lastFocus)) lastFocus.focus({ preventScroll: true });
  });
  dlg.addEventListener("click", (e) => { if (e.target === dlg) dlg.close(); });
  $("#dlg-close").addEventListener("click", () => dlg.close());

  function syncHash() {
    const h = location.hash;
    if (h.startsWith("#p-")) openProject(h.slice(3), false);
    else if (dlg.open) dlg.close();
  }
  window.addEventListener("popstate", syncHash);

  /* ---------- skills ---------- */
  function renderSkills() {
    $("#skill-groups").replaceChildren(...SKILL_GROUPS.map((g) =>
      el("div", { class: "skill-group" },
        el("h3", {}, g.name[lang]),
        el("ul", {}, g.items.map((s) => el("li", {}, s[lang]))))));
  }

  /* ---------- nav highlight ---------- */
  function watchSections() {
    if (!("IntersectionObserver" in window)) return;
    const links = [...document.querySelectorAll(".nav a")];
    const io = new IntersectionObserver((entries) => {
      entries.forEach((en) => {
        if (en.isIntersecting) links.forEach((a) => a.classList.toggle("is-current", a.getAttribute("href") === "#" + en.target.id));
      });
    }, { rootMargin: "-40% 0px -55% 0px" });
    document.querySelectorAll("main section[id]").forEach((s) => io.observe(s));
  }

  /* ---------- controls ---------- */
  function renderAll() {
    renderStatic();
    renderCurve();
    renderTimeline();
    renderFilters();
    renderProjects();
    renderSkills();
    if (dlg.open && location.hash.startsWith("#p-")) openProject(location.hash.slice(3), false);
  }

  $("#lang-toggle").addEventListener("click", () => {
    lang = lang === "fr" ? "en" : "fr";
    store.set("bm-lang", lang);
    const u = new URL(location.href);
    u.searchParams.set("lang", lang);
    history.replaceState(null, "", u);
    renderAll();
  });

  $("#theme-toggle").addEventListener("click", () => {
    const current = document.documentElement.getAttribute("data-theme") ||
      (matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
    const next = current === "dark" ? "light" : "dark";
    document.documentElement.setAttribute("data-theme", next);
    store.set("bm-theme", next);
  });

  $("#print-btn").addEventListener("click", () => { if (dlg.open) dlg.close(); window.print(); });
  window.addEventListener("beforeprint", () => {
    document.querySelectorAll("details").forEach((d) => { d.open = true; });
    theme = null; renderFilters(); renderProjects();
  });

  renderAll();
  let lastNarrow = $("#curve").clientWidth < 520;
  window.addEventListener("resize", () => {
    const n = $("#curve").clientWidth < 520;
    if (n !== lastNarrow) { lastNarrow = n; renderCurve(); }
  });
  watchSections();
  syncHash();
})();
