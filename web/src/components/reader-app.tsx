"use client";

import { useCallback, useEffect, useRef, useState, type ReactNode } from "react";
import { ArrowLeft, ArrowRight, ArrowUp, ArrowUpRight, BookOpen, Bookmark, Check, ChevronDown, Compass, ExternalLink, Globe2, History, Info, LoaderCircle, Minus, Monitor, Moon, Plus, RefreshCw, Settings2, Share2, Sparkles, Sun, X } from "lucide-react";
import { dayStamp, depths, isLanguage, isRtl, languages, type Article, type Language, type Mode, type Screen, type Theme } from "@/lib/model";
import { strings, yearsAgo, type Strings } from "@/lib/i18n";
import { useReaderStore } from "@/lib/store";
import { useFeed } from "@/lib/use-feed";
import { loadArticle, loadCredit, loadRelated, type Credit } from "@/lib/wiki";

const sourceLabel = (article: Article) => article.source === "wikivoyage" ? "Wikivoyage" : "Wikipedia";

function IconButton({ label, children, onClick, active = false, disabled = false, className = "" }: { label: string; children: ReactNode; onClick?: () => void; active?: boolean; disabled?: boolean; className?: string }) {
  return <button type="button" title={label} aria-label={label} disabled={disabled} className={`icon-button ${active ? "is-active" : ""} ${className}`} onClick={onClick}>{children}</button>;
}

export default function ReaderApp() {
  const { settings, favorites, history, hydrated, storageWarning, hydrate, updateSettings, toggleFavorite, record } = useReaderStore();
  const [screen, setScreen] = useState<Screen>("discover");
  const [mode, setMode] = useState<Mode>("random");
  const [settingsOpen, setSettingsOpen] = useState(false), [aboutOpen, setAboutOpen] = useState(false);
  const [detail, setDetail] = useState<Article | null>(null), [detailLoading, setDetailLoading] = useState(false), [detailError, setDetailError] = useState(false);
  const [image, setImage] = useState<Article | null>(null), [removing, setRemoving] = useState<Article | null>(null);
  const [toast, setToast] = useState(""), [showTop, setShowTop] = useState(false);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const detailRequest = useRef<AbortController | null>(null);
  const content = useRef<HTMLElement>(null);
  const feed = useFeed(settings, mode, hydrated);
  const ui = strings(settings.language);
  const current = feed.current;
  const overlayOpen = settingsOpen || aboutOpen || !!detail || detailLoading || detailError || !!image || !!removing;
  const flash = useCallback((message: string) => {
    clearTimeout(toastTimer.current); setToast(message);
    toastTimer.current = setTimeout(() => setToast(""), 2600);
  }, []);

  useEffect(() => { void hydrate(); return () => clearTimeout(toastTimer.current); }, [hydrate]);
  useEffect(() => {
    if (!hydrated) return;
    const media = matchMedia("(prefers-color-scheme: dark)");
    const apply = () => { document.documentElement.dataset.theme = settings.theme === "dark" || (settings.theme === "system" && media.matches) ? "dark" : "light"; };
    apply(); media.addEventListener("change", apply);
    document.documentElement.lang = settings.language;
    document.documentElement.dir = isRtl(settings.language) ? "rtl" : "ltr";
    return () => media.removeEventListener("change", apply);
  }, [settings.language, settings.theme, hydrated]);
  useEffect(() => { if (screen === "discover" && current && !feed.loading) record(current); }, [current?.id, current?.year, screen, feed.loading, record]); // Each visible article is recorded once.
  useEffect(() => {
    if (!hydrated) return;
    const sync = () => {
      detailRequest.current?.abort();
      const params = new URLSearchParams(location.search), title = params.get("article");
      setDetailError(false); setDetail(null);
      if (!title) { setDetailLoading(false); return; }
      const controller = new AbortController();
      detailRequest.current = controller;
      setDetailLoading(true);
      void loadArticle(params.get("lang") ?? "zh", params.get("source") ?? "wikipedia", title, controller.signal).then((article) => {
        if (!controller.signal.aborted) { setDetail(article); record(article); }
      }).catch(() => { if (!controller.signal.aborted) setDetailError(true); }).finally(() => { if (!controller.signal.aborted) setDetailLoading(false); });
    };
    sync(); addEventListener("popstate", sync);
    return () => { detailRequest.current?.abort(); removeEventListener("popstate", sync); };
  }, [hydrated, record]);
  useEffect(() => {
    let last = 0;
    const keydown = (event: KeyboardEvent) => {
      if (screen !== "discover" || overlayOpen || feed.loading || event.repeat || event.ctrlKey || event.metaKey || event.altKey || (event.target instanceof HTMLElement && event.target.closest("input, textarea, select, [contenteditable=true]"))) return;
      if (event.key === " " && event.target instanceof HTMLElement && event.target.closest("button, a")) return;
      if (!["ArrowDown", "ArrowUp", " "].includes(event.key)) return;
      event.preventDefault();
      if (Date.now() - last < 300) return;
      last = Date.now();
      if (event.key === "ArrowUp") feed.previous(); else void feed.next();
    };
    addEventListener("keydown", keydown);
    return () => removeEventListener("keydown", keydown);
  }, [screen, overlayOpen, feed.loading, feed.previous, feed.next]);
  useEffect(() => {
    let stamp = dayStamp();
    const check = () => { const next = dayStamp(); if (next !== stamp) { stamp = next; if (mode === "onThisDay") feed.retry(); } };
    const timer = setInterval(check, 60000);
    addEventListener("visibilitychange", check);
    return () => { clearInterval(timer); removeEventListener("visibilitychange", check); };
  }, [mode, feed.retry]);

  const navigate = (value: Screen) => { setScreen(value); content.current?.scrollTo({ top: 0 }); setShowTop(false); };
  const open = (article: Article) => {
    detailRequest.current?.abort();
    setDetail(article); setDetailLoading(false); setDetailError(false); record(article);
    const params = new URLSearchParams({ article: article.title, lang: article.language, source: article.source });
    window.history.pushState({}, "", `${location.pathname}?${params}`);
  };
  const closeDetail = () => { detailRequest.current?.abort(); setDetail(null); setDetailError(false); setDetailLoading(false); window.history.replaceState({}, "", location.pathname); };
  const bookmark = (article: Article) => { const exists = favorites.some((item) => item.id === article.id); toggleFavorite(article); flash(exists ? ui.removed : ui.saved); };
  const share = async (article: Article) => {
    const data = { title: article.title, text: article.title, url: article.url };
    if (navigator.share) {
      try { await navigator.share(data); return; } catch (error) { if ((error as Error).name === "AbortError") return; }
    }
    try { await navigator.clipboard.writeText(`${article.title}\n${article.url}`); flash(ui.copied); }
    catch { window.prompt(ui.share, `${article.title}\n${article.url}`); }
  };
  const goOriginal = (article: Article) => { record(article); };
  const nav = [{ screen: "favorites" as const, icon: Bookmark, title: ui.favoriteTab }, { screen: "history" as const, icon: History, title: ui.history }];

  return <div className="app-shell">
    <header className="site-header">
      <div className="topbar">
        <label className="language-switch" title={ui.contentLanguage}>
          <Globe2 size={16} /><span className="language-name">{languages.find((language) => language.code === settings.language)?.name}</span><span className="language-code">{settings.language.toUpperCase()}</span><ChevronDown size={12} />
          <select aria-label={ui.contentLanguage} value={settings.language} onChange={(event) => { if (isLanguage(event.target.value)) updateSettings({ language: event.target.value }); }}>{languages.map((language) => <option key={language.code} value={language.code}>{language.name}</option>)}</select>
        </label>
        <a className="wordmark" href="/" onClick={(event) => { event.preventDefault(); navigate("discover"); }} aria-label="Random Wiki">Random <i>Wiki</i><span>.</span></a>
        <nav className="header-nav" aria-label={ui.appName}>
          {nav.map(({ screen: target, icon: Icon, title }) => <button key={target} className={`header-link ${screen === target ? "selected" : ""}`} title={title} aria-label={title} onClick={() => navigate(screen === target ? "discover" : target)} aria-current={screen === target ? "page" : undefined}><Icon size={17} strokeWidth={1.7} /><span>{title}</span></button>)}
          <button className="header-link" title={ui.settings} aria-label={ui.settings} onClick={() => setSettingsOpen(true)}><Settings2 size={17} strokeWidth={1.7} /><span>{ui.settings}</span></button>
        </nav>
      </div>
      {screen === "discover" && <div className="mode-tabs" role="tablist" aria-label={ui.switchFeed}>{(["random", "onThisDay", "voyage"] as Mode[]).map((item) => <button role="tab" aria-selected={mode === item} key={item} className={mode === item ? "selected" : ""} onClick={() => setMode(item)}>{item === "random" ? "Wikipedia" : item === "onThisDay" ? ui.onThisDay : "Wikivoyage"}</button>)}</div>}
    </header>
    <main className="main-content" ref={content} onScroll={(event) => setShowTop(event.currentTarget.scrollTop > 360)}>
      {screen === "discover" ? <div className="discover-page">
        {feed.fallback && <p className="notice"><Info size={14} />{ui.fallback}</p>}
        <div className="reader-stage">
          {feed.loading || !hydrated ? <FeedSkeleton ui={ui} /> : feed.error || !current ? <div className="feed-error"><BookOpen size={32} strokeWidth={1} /><h2>{ui.loadFailed}</h2><button className="primary-button" onClick={feed.retry}><RefreshCw size={16} />{ui.retry}</button></div> : <StoryCard article={current} ui={ui} bookmarked={favorites.some((item) => item.id === current.id)} onBookmark={() => bookmark(current)} onOpen={() => open(current)} onShare={() => void share(current)} onImage={() => setImage(current)} onNext={() => void feed.next()} onPrevious={feed.previous} />}
        </div>
        <nav className="feed-navigation" aria-label={ui.switchFeed}>
          <button className="pager-previous" title={ui.previous} disabled={feed.index === 0 || feed.loading} onClick={feed.previous} aria-label={ui.previous}><ArrowLeft size={17} /></button>
          <button className="next-button" title={ui.hint} disabled={feed.loading || (mode === "onThisDay" && feed.index >= feed.articles.length - 1) || (feed.moreLoading && feed.index >= feed.articles.length - 1)} onClick={() => void feed.next()}><span>{ui.next}</span>{feed.moreLoading && feed.index >= feed.articles.length - 1 ? <LoaderCircle size={15} className="spin" /> : <ArrowRight size={16} />}</button>
        </nav>
        {feed.moreError && <div className="inline-retry"><span>{ui.loadFailed}</span><button onClick={() => void feed.loadMore()}><RefreshCw size={14} />{ui.retry}</button></div>}
        {mode === "onThisDay" && feed.articles.length > 0 && feed.index === feed.articles.length - 1 && <p className="end-note">{ui.allRead}</p>}
      </div> : <Collection screen={screen} articles={screen === "favorites" ? favorites : history.map((entry) => entry.article)} ui={ui} onOpen={open} onRemove={setRemoving} onDiscover={() => navigate("discover")} />}
    </main>
    {storageWarning && <div className="storage-warning" role="status">{ui.storageWarning}</div>}
    {showTop && screen !== "discover" && <IconButton className="back-top" label={ui.backToTop} onClick={() => content.current?.scrollTo({ top: 0, behavior: "smooth" })}><ArrowUp size={20} /></IconButton>}
    {toast && <div className="toast" role="status"><Check size={16} />{toast}</div>}
    {settingsOpen && <SettingsDialog ui={ui} onClose={() => setSettingsOpen(false)} onAbout={() => { setSettingsOpen(false); setAboutOpen(true); }} />}
    {aboutOpen && <Dialog title={ui.about} onClose={() => setAboutOpen(false)} ui={ui} className="about-dialog"><div className="about-content"><span className="about-wordmark">randomwiki<span>✦</span></span><h3>{ui.headline}</h3><p>{settings.language === "zh" ? "Random Wiki 是一个独立的知识阅读器。随机遇见百科知识、历史事件和旅行目的地。无需账号，收藏与阅读历史只保存在当前浏览器中。" : "Random Wiki is an independent reader for Wikipedia, historical events and travel destinations. No account needed. Favorites and history stay in this browser."}</p><p>{settings.language === "zh" ? "内容来自 Wikipedia、Wikivoyage 与 Wikimedia Commons。本网站与维基媒体基金会没有隶属关系。" : "Content comes from Wikipedia, Wikivoyage and Wikimedia Commons. This website is not affiliated with the Wikimedia Foundation."}</p><a href="https://creativecommons.org/licenses/by-sa/4.0/" target="_blank" rel="noreferrer">Text · CC BY-SA 4.0 <ArrowUpRight size={14} /></a><p className="fine-print">{settings.language === "zh" ? "图片许可与署名以各文件说明页为准。可在图片预览中查看。浏览器缓存不等同于完整离线下载。" : "Image licenses and attribution are specific to each file. See image previews for credits. Browser caching is not a full offline download."}</p><div className="about-links"><a href="https://www.wikipedia.org/" target="_blank" rel="noreferrer">Wikipedia <ArrowUpRight size={14} /></a><a href="https://www.wikivoyage.org/" target="_blank" rel="noreferrer">Wikivoyage <ArrowUpRight size={14} /></a></div></div></Dialog>}
    {(detail || detailLoading || detailError) && <Dialog title={ui.articleDetails} onClose={closeDetail} ui={ui} className="article-dialog">{detailLoading ? <div className="dialog-loading"><LoaderCircle className="spin" /><p>{ui.loading}</p></div> : detailError || !detail ? <div className="dialog-loading"><p>{ui.loadFailed}</p><button className="primary-button" onClick={() => dispatchEvent(new PopStateEvent("popstate"))}>{ui.retry}</button></div> : <ArticleDetail article={detail} ui={ui} language={settings.language} bookmarked={favorites.some((item) => item.id === detail.id)} onBookmark={() => bookmark(detail)} onShare={() => void share(detail)} onImage={() => setImage(detail)} onOpen={open} onOriginal={() => goOriginal(detail)} />}</Dialog>}
    {image && <ImageDialog article={image} ui={ui} onClose={() => setImage(null)} />}
    {removing && <Dialog title={ui.removeFavoriteTitle} onClose={() => setRemoving(null)} ui={ui} className="confirm-dialog"><p className="confirm-title">{removing.title}</p><div className="confirm-actions"><button className="secondary-button" onClick={() => setRemoving(null)}>{ui.cancel}</button><button className="primary-button" onClick={() => { bookmark(removing); setRemoving(null); }}>{ui.confirm}</button></div></Dialog>}
  </div>;
}

function StoryCard({ article, ui, bookmarked, onBookmark, onOpen, onShare, onImage, onNext, onPrevious }: { article: Article; ui: Strings; bookmarked: boolean; onBookmark: () => void; onOpen: () => void; onShare: () => void; onImage: () => void; onNext: () => void; onPrevious: () => void }) {
  const [failedImage, setFailedImage] = useState<string>();
  const hasImage = !!article.image && failedImage !== article.image;
  const wheel = useRef(0), locked = useRef(0), touch = useRef<{ x: number; y: number } | undefined>(undefined);
  return <article className={`story-card ${hasImage ? "" : "text-only"}`} data-testid="story-card" onWheel={(event) => {
    if (Math.abs(event.deltaX) > Math.abs(event.deltaY) || window.getSelection()?.toString() || Date.now() - locked.current < 650) return;
    wheel.current += event.deltaY;
    if (Math.abs(wheel.current) > 90) { locked.current = Date.now(); if (wheel.current > 0) onNext(); else onPrevious(); wheel.current = 0; }
  }} onTouchStart={(event) => { touch.current = event.touches.length === 1 ? { x: event.touches[0].clientX, y: event.touches[0].clientY } : undefined; }} onTouchEnd={(event) => {
    const start = touch.current;
    touch.current = undefined;
    if (!start || window.getSelection()?.toString() || (event.target instanceof HTMLElement && event.target.closest("button, a") && !event.target.closest(".article-image"))) return;
    const end = event.changedTouches[0], dy = start.y - end.clientY, dx = start.x - end.clientX;
    if (Math.abs(dy) > 65 && Math.abs(dy) > Math.abs(dx) * 1.3) { if (dy > 0) onNext(); else onPrevious(); }
  }}>
    {hasImage && <div className="story-visual" key={`${article.id}:visual`}><ArticleImage article={article} onClick={onImage} onFailure={() => setFailedImage(article.image)} /></div>}
    <div className="story-copy" key={`${article.id}:${article.year ?? ""}:copy`} dir={isRtl(article.language) ? "rtl" : "ltr"} lang={article.language}>
      <a className="story-source" href={article.url} target="_blank" rel="noreferrer">{sourceLabel(article)}<span>·</span>{article.language.toUpperCase()}<ArrowUpRight size={12} /></a>
      <h1 className="article-title">{article.title}</h1>
      {(article.year !== undefined || article.description) && <p className="article-category">{article.year !== undefined ? `${article.year} · ${yearsAgo(article.language, new Date().getFullYear() - article.year)}` : article.description}</p>}
      <p className="article-extract">{article.extract}</p>
      <div className="story-actions">
        <IconButton label={bookmarked ? ui.removeCurrent : ui.saveCurrent} active={bookmarked} onClick={onBookmark}><Bookmark size={20} fill={bookmarked ? "currentColor" : "none"} strokeWidth={1.6} /></IconButton>
        <IconButton label={ui.share} onClick={onShare}><Share2 size={19} strokeWidth={1.6} /></IconButton>
        <button className="read-more" onClick={onOpen}><span>{ui.articleDetails}</span><ArrowUpRight size={16} /></button>
      </div>
    </div>
  </article>;
}

function ArticleImage({ article, onClick, onFailure, className = "" }: { article: Article; onClick?: () => void; onFailure?: () => void; className?: string }) {
  const [failed, setFailed] = useState(false);
  useEffect(() => setFailed(false), [article.image]);
  const image = article.image && !failed ? <img src={article.image} alt={article.title} onError={() => { setFailed(true); onFailure?.(); }} draggable={false} /> : <div className="image-placeholder"><BookOpen size={48} strokeWidth={.7} /><span>{sourceLabel(article)}</span></div>;
  return onClick && article.image && !failed ? <button className={`article-image ${className}`} onClick={onClick} aria-label={article.title}>{image}</button> : <div className={`article-image ${className}`}>{image}</div>;
}
function FeedSkeleton({ ui }: { ui: Strings }) {
  return <div className="feed-loading" role="status"><LoaderCircle size={22} className="spin" /><span>{ui.loading}</span></div>;
}
function Collection({ screen, articles, ui, onOpen, onRemove, onDiscover }: { screen: "favorites" | "history"; articles: Article[]; ui: Strings; onOpen: (article: Article) => void; onRemove: (article: Article) => void; onDiscover: () => void }) {
  const Icon = screen === "favorites" ? Bookmark : History;
  return <div className="collection-page">
    <button className="back-to-feed" onClick={onDiscover}><ArrowLeft size={16} />{ui.discover}</button>
    <header className="collection-header"><h1>{screen === "favorites" ? ui.favorites : ui.history}<span>{articles.length}</span></h1><p>{ui.local}</p></header>
    {articles.length ? <div className="collection-list">{articles.map((article) => <div className="collection-row" key={article.id}><button className="collection-open" onClick={() => onOpen(article)}>{article.image && <ArticleImage article={article} />}<span className="list-copy"><span className="list-source">{sourceLabel(article)} · {article.language.toUpperCase()}</span><span className="list-title" dir="auto">{article.title}</span><span className="list-extract" dir="auto">{article.extract}</span></span></button>{screen === "favorites" ? <IconButton label={ui.removeCurrent} onClick={() => onRemove(article)} active><Bookmark size={19} fill="currentColor" strokeWidth={1.6} /></IconButton> : <IconButton label={ui.more} onClick={() => onOpen(article)}><ArrowUpRight size={18} /></IconButton>}</div>)}</div> : <div className="empty-state"><Icon size={28} strokeWidth={1.2} /><h2>{screen === "favorites" ? ui.noFavorites : ui.noHistory}</h2><p>{ui.emptyHint}</p><button className="primary-button" onClick={onDiscover}>{ui.discover}<ArrowRight size={16} /></button></div>}
  </div>;
}

function Dialog({ title, children, onClose, ui, className = "" }: { title: string; children: ReactNode; onClose: () => void; ui: Strings; className?: string }) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => { const dialog = ref.current; dialog?.showModal(); return () => dialog?.close(); }, []);
  return <dialog ref={ref} className={`dialog ${className}`} onCancel={onClose} onClick={(event) => { if (event.target === event.currentTarget) { const box = event.currentTarget.getBoundingClientRect(); if (event.clientX < box.left || event.clientX > box.right || event.clientY < box.top || event.clientY > box.bottom) onClose(); } }} aria-label={title}><header className="dialog-header"><span>{title}</span><IconButton label={ui.closePreview} onClick={onClose}><X size={20} /></IconButton></header>{children}</dialog>;
}
function SettingsDialog({ ui, onClose, onAbout }: { ui: Strings; onClose: () => void; onAbout: () => void }) {
  const { settings, updateSettings } = useReaderStore();
  return <Dialog title={ui.settings} onClose={onClose} ui={ui} className="settings-dialog"><div className="settings-content"><section className="settings-section"><h3><Globe2 size={18} />{ui.contentLanguage}</h3><select className="settings-select" value={settings.language} aria-label={ui.contentLanguage} onChange={(event) => { if (isLanguage(event.target.value)) updateSettings({ language: event.target.value }); }}>{languages.map((language) => <option key={language.code} value={language.code}>{language.name}</option>)}</select></section><section className="settings-section"><h3><Compass size={18} />{ui.articleDepth}</h3><p>{ui.articleDepthHint}</p><input className="depth-range" type="range" min={0} max={4} step={1} aria-label={ui.articleDepth} aria-valuetext={ui[settings.depth]} value={depths.indexOf(settings.depth)} onChange={(event) => updateSettings({ depth: depths[Number(event.target.value)] })} /><div className="depth-labels">{depths.map((depth) => <button className={depth === settings.depth ? "selected" : ""} onClick={() => updateSettings({ depth })} key={depth}>{ui[depth]}</button>)}</div></section><section className="settings-section"><h3><Sun size={18} />{ui.appearance}</h3><div className="theme-options">{([{ value: "light", label: ui.light, icon: Sun }, { value: "dark", label: ui.dark, icon: Moon }, { value: "system", label: ui.followSystem, icon: Monitor }] as const).map(({ value, label, icon: Icon }) => <button aria-pressed={settings.theme === value} className={settings.theme === value ? "selected" : ""} key={value} onClick={() => updateSettings({ theme: value as Theme })}><Icon size={22} strokeWidth={1.4} /><span>{label}</span>{settings.theme === value && <Check size={13} className="theme-check" />}</button>)}</div></section><div className="settings-footer"><span>{ui.local}</span><button onClick={onAbout}>{ui.about}<ArrowUpRight size={13} /></button></div></div></Dialog>;
}
function ArticleDetail({ article, ui, language, bookmarked, onBookmark, onShare, onImage, onOpen, onOriginal }: { article: Article; ui: Strings; language: Language; bookmarked: boolean; onBookmark: () => void; onShare: () => void; onImage: () => void; onOpen: (article: Article) => void; onOriginal: () => void }) {
  const [related, setRelated] = useState<Article[]>([]), [loading, setLoading] = useState(true), [failed, setFailed] = useState(false), [retry, setRetry] = useState(0);
  const scroll = useRef<HTMLDivElement>(null);
  useEffect(() => {
    scroll.current?.scrollTo({ top: 0 });
    const controller = new AbortController();
    setRelated([]); setFailed(false); setLoading(article.source === "wikipedia");
    if (article.source === "wikipedia") void loadRelated(article, controller.signal).then((items) => { if (!controller.signal.aborted) setRelated(items); }).catch(() => { if (!controller.signal.aborted) setFailed(true); }).finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [article.id, retry]);
  return <div className="article-detail-scroll" ref={scroll}><div className="detail-body" dir={isRtl(article.language) ? "rtl" : "ltr"} lang={article.language}><div className="detail-meta"><span>{sourceLabel(article)} · {article.language.toUpperCase()}</span><div><IconButton label={bookmarked ? ui.removeCurrent : ui.saveCurrent} active={bookmarked} onClick={onBookmark}><Bookmark size={19} fill={bookmarked ? "currentColor" : "none"} /></IconButton><IconButton label={ui.share} onClick={onShare}><Share2 size={18} /></IconButton></div></div>{article.description && <p className="article-category">{article.description}</p>}{article.year !== undefined && <p className="article-category">{article.year} · {yearsAgo(language, new Date().getFullYear() - article.year)}</p>}<h2>{article.title}</h2>{article.image && <ArticleImage article={article} onClick={onImage} className="detail-image" />}<div className="full-extract">{article.extract.split(/\n+/).filter(Boolean).map((paragraph, index) => <p key={index}>{paragraph}</p>)}</div><div className="detail-actions"><a className="primary-button" href={article.url} target="_blank" rel="noreferrer" onClick={onOriginal}>{ui.readOnWikipedia}<ExternalLink size={15} /></a><button className="secondary-button" onClick={onShare}><Share2 size={15} />{ui.share}</button></div><p className="article-attribution">{sourceLabel(article)} · <a href={article.url} target="_blank" rel="noreferrer">{article.title}</a> · <a href="https://creativecommons.org/licenses/by-sa/4.0/" target="_blank" rel="noreferrer">CC BY-SA 4.0</a></p>{article.source === "wikipedia" && (loading || failed || related.length > 0) && <section className="related-section"><h3><Sparkles size={17} />{ui.relatedArticles}</h3>{loading ? <LoaderCircle className="spin" size={18} /> : failed ? <div className="inline-retry"><span>{ui.relatedFailed}</span><button onClick={() => setRetry((value) => value + 1)}>{ui.retry}</button></div> : <div className="related-list">{related.map((item) => <button className="related-item" key={item.id} onClick={() => onOpen(item)}><ArticleImage article={item} /><span><strong>{item.title}</strong><small>{item.extract}</small></span><ArrowUpRight size={17} /></button>)}</div>}</section>}</div></div>;
}
function ImageDialog({ article, ui, onClose }: { article: Article; ui: Strings; onClose: () => void }) {
  const [scale, setScale] = useState(1), [position, setPosition] = useState({ x: 0, y: 0 }), [credit, setCredit] = useState<Credit | undefined>(undefined);
  const drag = useRef<{ x: number; y: number } | null>(null), pinch = useRef(0);
  const zoom = (difference: number) => setScale((value) => Math.max(.8, Math.min(4, value + difference)));
  useEffect(() => { const controller = new AbortController(); void loadCredit(article, controller.signal).then(setCredit).catch(() => {}); return () => controller.abort(); }, [article.id]);
  return <Dialog title={article.title} onClose={onClose} ui={ui} className="image-dialog"><div className="image-viewport" onWheel={(event) => zoom(event.deltaY > 0 ? -.1 : .1)} onPointerDown={(event) => { if (event.pointerType === "touch") return; event.currentTarget.setPointerCapture(event.pointerId); drag.current = { x: event.clientX - position.x, y: event.clientY - position.y }; }} onPointerMove={(event) => { if (drag.current) setPosition({ x: event.clientX - drag.current.x, y: event.clientY - drag.current.y }); }} onPointerUp={() => { drag.current = null; }} onPointerCancel={() => { drag.current = null; }} onTouchStart={(event) => { if (event.touches.length === 2) pinch.current = Math.hypot(event.touches[0].clientX - event.touches[1].clientX, event.touches[0].clientY - event.touches[1].clientY); else if (event.touches.length === 1) drag.current = { x: event.touches[0].clientX - position.x, y: event.touches[0].clientY - position.y }; }} onTouchMove={(event) => { if (event.touches.length === 2) { const distance = Math.hypot(event.touches[0].clientX - event.touches[1].clientX, event.touches[0].clientY - event.touches[1].clientY); if (pinch.current) setScale((value) => Math.max(.8, Math.min(4, value * distance / pinch.current))); pinch.current = distance; } else if (drag.current && event.touches.length === 1) setPosition({ x: event.touches[0].clientX - drag.current.x, y: event.touches[0].clientY - drag.current.y }); }} onTouchEnd={() => { drag.current = null; pinch.current = 0; }}><img src={article.image} alt={article.title} draggable={false} style={{ transform: `translate(${position.x}px, ${position.y}px) scale(${scale})` }} /></div><div className="image-controls"><IconButton label="−" onClick={() => zoom(-.25)}><Minus size={18} /></IconButton><button onClick={() => { setScale(1); setPosition({ x: 0, y: 0 }); }}>{Math.round(scale * 100)}%</button><IconButton label="+" onClick={() => zoom(.25)}><Plus size={18} /></IconButton><a href={credit?.url ?? (article.imageFile ? `https://commons.wikimedia.org/wiki/File:${encodeURIComponent(article.imageFile)}` : article.url)} target="_blank" rel="noreferrer">{ui.photo}<ArrowUpRight size={13} /></a></div>{credit && <p className="image-credit">{credit.author} {credit.license && `· ${credit.license}`}</p>}</Dialog>;
}
