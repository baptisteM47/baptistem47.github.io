(function () {
  "use strict";

  const $ = (sel, root = document) => root.querySelector(sel);
  const el = (tag, attrs = {}, ...children) => {
    const node = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs)) {
      if (v == null || v === false) continue;
      if (k === "class") node.className = v;
      else if (k === "text") node.textContent = v;
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
  let theme = null;        // active theme filter id
  let skill = null;        // active skill filter id
  const openCourses = new Set();

  const t = (obj) => (obj && typeof obj === "object" ? (obj[lang] ?? obj.fr) : obj);
  const ui = () => UI[lang];
  const getPath = (o, path) => path.split(".").reduce((a, k) => (a ? a[k] : undefined), o);

  const skillName = (id) => {
    for (const g of SKILL_GROUPS) for (const s of g.items) if (s.id === id) return s[lang];
    return id;
  };
  const projectCount = (id) => PROJECTS.filter((p) => p.skills.includes(id)).length;
  const metricValue = (p) => (lang === "en" && p.metric.valueEn) ? p.metric.valueEn : p.metric.value;
  const fmtMonth = (ym) => {
    const [y, m] = ym.split("-").map(Number);
    return new Date(y, m - 1, 1).toLocaleDateString(lang === "fr" ? "fr-FR" : "en-GB", { month: "long", year: "numeric" });
  };

  /* ---------- static text ---------- */
  function renderStatic() {
    document.documentElement.lang = lang;
    document.title = lang === "fr" ? "Baptiste Messant, CV" : "Baptiste Messant, résumé";
    document.querySelectorAll("[data-i18n]").forEach((n) => { n.textContent = getPath(ui(), n.dataset.i18n); });
    $("#role").textContent = t(PROFILE.role);
    $("#pitch").textContent = t(PROFILE.pitch);
    $("#availability").textContent = t(PROFILE.availability);
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
      const ul = $(id);
      ul.replaceChildren(...PROFILE.links.map((l) => el("li", {}, el("a", { href: l.url, target: "_blank", rel: "noopener" }, l.label))));
    }
  }

  /* ---------- career curve ---------- */
  function renderCurve() {
    const svg = $("#curve-svg");
    const narrow = svg.parentElement.clientWidth < 520;
    const W = narrow ? 420 : 560, H = narrow ? 300 : 330, padL = 8, padR = 24, padT = 34, padB = 34;
    svg.setAttribute("viewBox", `0 0 ${W} ${H}`);
    const t0 = 2021, t1 = 2027;
    const x = (v) => padL + ((v - t0) / (t1 - t0)) * (W - padL - padR);
    const y = (v) => H - padB - v * (H - padT - padB);
    const pts = CAREER.map((p) => [x(p.t), y(p.y)]);

    // smooth path (Catmull-Rom to Bézier)
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
    for (let yr = 2021; yr <= 2026; yr++) {
      svg.append(s("text", { class: "tick", x: x(yr), y: H - 10, "text-anchor": "middle" }, String(yr)));
    }
    svg.append(s("path", { class: "line", d }));

    CAREER.forEach((p, i) => {
      const [px, py] = pts[i];
      const g = s("g", { class: "pt" + (p.open ? " open" : ""), tabindex: "0", role: "link" });
      const label = t(p.label);
      g.setAttribute("aria-label", label);
      const right = px < W * 0.55;
      const anchor = right ? "start" : "end";
      const lx = right ? px + 14 : px - 14;
      const ly = py + 4;
      g.append(s("circle", { class: "hit", cx: px, cy: py, r: 18 }));
      g.append(s("circle", { class: "mark", cx: px, cy: py, r: 6 }));
      const txt = s("text", { x: lx, y: ly, "text-anchor": anchor }, label);
      g.append(txt);
      const go = () => {
        const target = document.getElementById(p.target);
        if (target) target.scrollIntoView({ block: "start" });
      };
      g.addEventListener("click", go);
      g.addEventListener("keydown", (e) => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); go(); } });
      svg.append(g);
      // label halo for legibility over the curve
      requestAnimationFrame(() => {
        try {
          const bb = txt.getBBox();
          g.insertBefore(s("rect", { class: "label-bg", x: bb.x - 4, y: bb.y - 2, width: bb.width + 8, height: bb.height + 4, rx: 4 }), txt);
        } catch (e) {}
      });
    });
  }

  /* ---------- experience ---------- */
  function renderExperience() {
    $("#exp-list").replaceChildren(...EXPERIENCE.map((job) =>
      el("article", { class: "job" },
        el("div", { class: "job-period" }, job.period),
        el("div", {},
          el("h3", {}, t(job.title)),
          el("p", { class: "org" }, el("strong", {}, job.company), ", " + t(job.kind)),
          el("ul", {}, t(job.bullets).map((b) => el("li", {}, b))),
          el("div", { class: "chips" }, job.skills.map((id) =>
            el("span", { class: "chip" }, skillName(id))))
        )
      )
    ));
    $("#summer-list").replaceChildren(...SUMMER_JOBS.map((j) => el("li", {}, el("b", {}, j.year), j[lang])));
  }

  /* ---------- projects ---------- */
  function visibleProjects() {
    return PROJECTS.filter((p) =>
      (!theme || p.themes.includes(theme)) && (!skill || p.skills.includes(skill)));
  }

  function renderFilters() {
    const mk = (id, label, n) => el("button", {
      class: "filter", type: "button", "aria-pressed": String(theme === id),
      onclick: () => { theme = id; renderFilters(); renderProjects(); }
    }, label, el("span", { class: "n" }, String(n)));
    $("#filters").replaceChildren(
      mk(null, ui().all, PROJECTS.length),
      ...THEMES.map((th) => mk(th.id, th[lang], PROJECTS.filter((p) => p.themes.includes(th.id)).length))
    );
    const af = $("#active-filter");
    if (skill) {
      af.hidden = false;
      af.replaceChildren(
        el("span", {}, ui().filterBy + " : ", el("strong", {}, skillName(skill))),
        el("button", { type: "button", onclick: () => setSkill(null) }, ui().clearFilter)
      );
    } else {
      af.hidden = true;
      af.replaceChildren();
    }
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

  function renderProjects() {
    const list = $("#project-list");
    const vis = new Set(visibleProjects().map((p) => p.id));
    const cards = PROJECTS.map((p) => {
      const card = el("button", {
        class: "project" + (p.featured ? " featured" : "") + (skill && vis.has(p.id) ? " is-match" : ""),
        type: "button", "data-id": p.id, hidden: !vis.has(p.id),
        onclick: () => openProject(p.id)
      },
        el("div", { class: "meta" },
          el("span", {}, t(p.context)),
          p.featured ? el("span", { class: "badge" }, ui().featured) : el("span", {}, p.date.slice(0, 4))
        ),
        el("p", { class: "metric" }, metricValue(p)),
        el("p", { class: "metric-label" }, t(p.metric.label)),
        p.featured ? sparkline() : null,
        p.featured ? el("p", { class: "lede" }, t(p.question)) : null,
        el("h3", {}, t(p.title)),
        el("span", { class: "more", "aria-hidden": "true" }, ui().details)
      );
      return card;
    });
    const nodes = [...cards];
    if (vis.size === 0) nodes.push(el("p", { class: "empty" }, ui().noProjects));
    list.replaceChildren(...nodes);
  }

  /* ---------- project dialog ---------- */
  const dlg = $("#project-dialog");
  let lastFocus = null;

  function openProject(id, push = true) {
    const p = PROJECTS.find((x) => x.id === id);
    if (!p) return;
    lastFocus = document.activeElement;
    const L = ui();
    const body = $("#dlg-body");
    body.replaceChildren(
      el("p", { class: "context" }, t(p.context) + ", " + fmtMonth(p.date)),
      el("h2", { id: "dlg-title" }, t(p.title)),
      el("p", { class: "coauthors" }, L.with + " " + p.coauthors),
      el("div", { class: "stat" }, el("b", {}, metricValue(p)), el("span", {}, t(p.metric.label))),
      el("h3", {}, L.question), el("p", {}, t(p.question)),
      el("h3", {}, L.method), el("p", {}, t(p.method)),
      el("h3", {}, L.results), el("ul", {}, t(p.results).map((r) => el("li", {}, r))),
      p.figure ? el("figure", {},
        el("img", { src: p.figure.src, alt: t(p.figure.alt), loading: "lazy" }),
        el("figcaption", {}, t(p.figure.alt))) : null,
      el("div", { class: "chips" }, p.skills.map((sid) =>
        el("button", { class: "chip", type: "button", onclick: () => { dlg.close(); setSkill(sid, true); } }, skillName(sid)))),
      el("div", { class: "actions" }, p.links.map((l) =>
        el("a", { href: l.href, target: "_blank", rel: "noopener" }, L.linkKinds[l.kind])))
    );
    if (!dlg.open) dlg.showModal();
    $(".sheet-inner").scrollTop = 0;
    dlg.scrollTop = 0;
    if (push && location.hash !== "#p-" + id) history.pushState(null, "", "#p-" + id);
  }

  dlg.addEventListener("close", () => {
    if (location.hash.startsWith("#p-")) history.pushState(null, "", location.pathname + location.search + "#projects");
    if (lastFocus && document.contains(lastFocus)) lastFocus.focus();
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
  function setSkill(id, scroll) {
    skill = id;
    if (id) theme = null;
    renderFilters();
    renderProjects();
    renderSkills();
    if (scroll || id) $("#projects").scrollIntoView({ block: "start" });
  }

  function renderSkills() {
    $("#skill-groups").replaceChildren(...SKILL_GROUPS.map((g) =>
      el("div", { class: "skill-group" },
        el("h3", {}, g.name[lang]),
        el("ul", {}, g.items.map((s) => {
          const n = projectCount(s.id);
          if (n === 0) return el("li", {}, el("span", { class: "skill" }, s[lang]));
          return el("li", {}, el("button", {
            class: "skill", type: "button", "aria-pressed": String(skill === s.id),
            title: ui().usedIn(n),
            onclick: () => setSkill(skill === s.id ? null : s.id)
          }, s[lang], el("span", { class: "n" }, ui().usedIn(n))));
        }))
      )
    ));
  }

  /* ---------- education ---------- */
  function renderEducation() {
    $("#edu-list").replaceChildren(...EDUCATION.map((e, i) => {
      const open = openCourses.has(i) || e.courses.length === 1;
      const listId = "courses-" + i;
      return el("article", { class: "edu" },
        el("div", { class: "edu-period" }, e.period),
        el("div", {},
          el("h3", {}, t(e.degree)),
          el("p", { class: "school" }, e.school),
          e.courses.length > 1 ? el("button", {
            class: "toggle", type: "button", "aria-expanded": String(open), "aria-controls": listId,
            onclick: () => { open ? openCourses.delete(i) : openCourses.add(i); renderEducation(); }
          }, open ? ui().hideCourses : ui().showCourses) : null,
          el("ul", { id: listId, hidden: !open }, e.courses.map((c) => el("li", {}, c[lang])))
        )
      );
    }));
  }

  /* ---------- nav highlight ---------- */
  function watchSections() {
    if (!("IntersectionObserver" in window)) return;
    const links = [...document.querySelectorAll(".nav a")];
    const io = new IntersectionObserver((entries) => {
      entries.forEach((en) => {
        if (en.isIntersecting) {
          links.forEach((a) => a.classList.toggle("is-current", a.getAttribute("href") === "#" + en.target.id));
        }
      });
    }, { rootMargin: "-40% 0px -55% 0px" });
    document.querySelectorAll("main section[id]").forEach((s) => io.observe(s));
  }

  /* ---------- controls ---------- */
  function renderAll() {
    renderStatic();
    renderCurve();
    renderExperience();
    renderFilters();
    renderProjects();
    renderSkills();
    renderEducation();
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

  $("#print-btn").addEventListener("click", () => {
    if (dlg.open) dlg.close();
    window.print();
  });
  // Print always shows every project, whatever the active filter
  window.addEventListener("beforeprint", () => { document.querySelectorAll("details").forEach((d) => { d.open = true; }); theme = null; skill = null; renderFilters(); renderProjects(); renderSkills(); });

  renderAll();
  let lastNarrow = $("#curve").clientWidth < 520;
  window.addEventListener("resize", () => {
    const n = $("#curve").clientWidth < 520;
    if (n !== lastNarrow) { lastNarrow = n; renderCurve(); }
  });
  watchSections();
  syncHash();
})();
