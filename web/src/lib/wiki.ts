import { dayStamp, eventArticles, isLanguage, pageToArticle, selectByDepth, voyageLead, type Article, type Depth, type Language, type Mode, type Source, type WikiPage } from "./model";
import { readCache, saveCache } from "./storage";

type Query = Record<string, string | number | undefined>;
interface Payload { query?: { pages?: WikiPage[]; normalized?: { from: string; to: string }[] }; continue?: Record<string, string>; error?: { info?: string }; events?: WikiPage[] }
export interface FeedResult { articles: Article[]; cursor: number; fallback: boolean; cached: boolean }
const agent = "RandomWikiWeb/0.1 (https://github.com/maxilong258/random-wiki)";
function aborted(signal: AbortSignal) { signal.throwIfAborted(); }
async function json(url: URL, signal: AbortSignal): Promise<Payload> {
  aborted(signal);
  const response = await fetch(url, { credentials: "omit", signal: AbortSignal.any([signal, AbortSignal.timeout(18000)]), headers: { "Api-User-Agent": agent } });
  if (!response.ok) throw new Error(`Wikipedia HTTP ${response.status}`);
  const payload = await response.json() as Payload;
  if (!payload || typeof payload !== "object" || payload.error) throw new Error(payload?.error?.info ?? "Invalid Wikipedia response");
  return payload;
}
async function query(language: Language, source: Source, values: Query, signal: AbortSignal) {
  const url = new URL(`https://${language}.${source}.org/w/api.php`);
  const params: Query = { action: "query", format: "json", formatversion: 2, origin: "*", ...values };
  if (language === "zh") params.variant = "zh-cn";
  for (const [key, value] of Object.entries(params)) if (value !== undefined) url.searchParams.set(key, String(value));
  return json(url, signal);
}
const props = (views = false): Query => ({
  prop: `extracts|pageimages|description|info|pageprops${views ? "|pageviews" : ""}`,
  exintro: 1, explaintext: 1, exlimit: 20, piprop: "thumbnail", pithumbsize: 1000, pilimit: "max",
  inprop: "url", ppprop: "disambiguation|page_image_free", ...(views ? { pvipdays: 14 } : {}),
});
async function byTitles(language: Language, source: Source, titles: string[], signal: AbortSignal): Promise<Article[]> {
  const entries = await Promise.all(titles.map((title) => readCache<Article>(`article:${source}:${language}:${title}`)));
  const cached = entries.filter((item): item is Article => !!item);
  const missing = titles.filter((_, index) => !entries[index]);
  let fetched: Article[] = [];
  if (missing.length) {
    const payload = await query(language, source, { titles: missing.join("|"), redirects: 1, ...props() }, signal);
    const pages = payload.query?.pages ?? [];
    if (source === "wikivoyage") for (const page of pages.filter((item) => !item.extract && typeof item.pageid === "number")) {
      const full = await query(language, source, { pageids: Number(page.pageid), prop: "extracts", explaintext: 1, exsectionformat: "wiki", exchars: 1400 }, signal);
      page.extract = voyageLead(String(full.query?.pages?.[0]?.extract ?? ""));
    }
    fetched = pages.flatMap((page) => { const minimum = source === "wikivoyage" ? (/[\u3400-\u9fff\u3040-\u30ff]/.test(String(page.extract)) ? 20 : 40) : 50; const article = pageToArticle(page, language, source, minimum); return article ? [article] : []; });
    await Promise.all(fetched.map((article) => saveCache(`article:${source}:${language}:${article.title}`, article)));
  }
  const unique = new Map([...cached, ...fetched].map((article) => [article.id, article]));
  return [...unique.values()];
}
const vitalPages = ["Arts", "Biology and health sciences", "Everyday life", "Geography", "History", "Mathematics", "People", "Philosophy and religion", "Physical sciences", "Society and social sciences", "Technology"];
const vitalLoads = new Map<number, Promise<string[]>>();
const vitalPools = new Map<Depth, string[]>();
function shuffled<T>(values: T[]): T[] {
  const result = [...values];
  for (let i = result.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [result[i], result[j]] = [result[j], result[i]]; }
  return result;
}
async function loadVital(level: number, signal: AbortSignal): Promise<string[]> {
  const cached = await readCache<string[]>(`vital:${level}`);
  if (cached && cached.length >= (level === 3 ? 500 : 3000)) return cached;
  const ongoing = vitalLoads.get(level);
  if (ongoing) return ongoing;
  const promise = (async () => {
    const names = level === 3 ? ["Wikipedia:Vital articles/Level 3"] : vitalPages.map((name) => `Wikipedia:Vital articles/Level 4/${name}`);
    const titles = new Set<string>();
    for (const name of names) {
      let continuation: string | undefined;
      do {
        const payload = await query("en", "wikipedia", { titles: name, prop: "links", plnamespace: 0, pllimit: "max", plcontinue: continuation, redirects: 1 }, signal);
        const links = payload.query?.pages?.[0]?.links;
        if (Array.isArray(links)) for (const link of links) if (typeof link.title === "string" && !link.title.includes("|")) titles.add(link.title);
        continuation = payload.continue?.plcontinue;
      } while (continuation);
    }
    const values = [...titles];
    if (values.length < (level === 3 ? 500 : 3000)) throw new Error("Incomplete vital articles list");
    await saveCache(`vital:${level}`, values, 7);
    return values;
  })();
  vitalLoads.set(level, promise);
  try { return await promise; } finally { vitalLoads.delete(level); }
}
async function vitalArticles(language: Language, depth: Depth, cursor: number, signal: AbortSignal) {
  let pool = vitalPools.get(depth);
  if (!pool) {
    const essential = await loadVital(3, signal);
    const essentialSet = new Set(essential);
    const titles = depth === "popular" ? essential : (await loadVital(4, signal)).filter((title) => !essentialSet.has(title));
    pool = shuffled(titles);
    vitalPools.set(depth, pool);
  }
  if (cursor >= pool.length) return { articles: [], cursor: pool.length };
  const english = pool.slice(cursor, cursor + 20);
  let titles = english;
  if (language !== "en") {
    const payload = await query("en", "wikipedia", { titles: english.join("|"), prop: "langlinks", lllang: language, lllimit: "max", redirects: 1 }, signal);
    titles = (payload.query?.pages ?? []).flatMap((page) => Array.isArray(page.langlinks) ? page.langlinks.map((link) => link.title).filter((title): title is string => typeof title === "string" && !title.includes("|")) : []);
  }
  return { articles: await byTitles(language, "wikipedia", titles, signal), cursor: cursor + english.length };
}
async function randomArticles(language: Language, depth: Depth, cursor: number, seen: Set<string>, signal: AbortSignal) {
  const result: Article[] = [];
  let useVital = depth === "popular" || depth === "familiar";
  for (let attempt = 0; attempt < 3 && result.length < 3; attempt++) {
    aborted(signal);
    if (useVital) {
      try {
        const batch = await vitalArticles(language, depth, cursor, signal);
        cursor = batch.cursor;
        result.push(...batch.articles.filter((article) => !seen.has(article.id) && !result.some((item) => item.id === article.id)));
        if (!batch.articles.length && cursor === vitalPools.get(depth)?.length) break;
        continue;
      } catch (error) { if (signal.aborted) throw error; useVital = false; }
    }
    const payload = await query(language, "wikipedia", { generator: "random", grnnamespace: 0, grnlimit: 20, ...props(true) }, signal);
    const pages = payload.query?.pages ?? [];
    const missing = pages.filter((page) => !page.pageviews && typeof page.pageid === "number");
    for (let start = 0; start < missing.length; start += 5) {
      if (selectByDepth(pages, depth, language).filter((page) => pageToArticle(page, language)).length >= 3) break;
      const chunk = missing.slice(start, start + 5);
      const views = await query(language, "wikipedia", { pageids: chunk.map((page) => page.pageid).join("|"), prop: "pageviews", pvipdays: 14 }, signal);
      for (const page of chunk) page.pageviews = views.query?.pages?.find((item) => item.pageid === page.pageid)?.pageviews;
    }
    for (const page of selectByDepth(pages, depth, language)) {
      const article = pageToArticle(page, language);
      if (article && !seen.has(article.id) && !result.some((item) => item.id === article.id)) result.push(article);
    }
  }
  return { articles: shuffled(result), cursor };
}
const voyageEditions = new Set(["en", "es", "fr", "de", "it", "pt", "ru", "ja", "zh", "he", "nl", "pl"]);
const phrasebookCategories: Record<string, string> = { en: "Category:Phrasebooks", de: "Kategorie:Sprachführer", es: "Categoría:Guías de conversación", fr: "Catégorie:Guides linguistiques", he: "קטגוריה:שיחונים", it: "Categoria:Frasari", ja: "カテゴリ:会話集", nl: "Categorie:Taalgids", pl: "Kategoria:Rozmówki", pt: "Categoria:Guias de conversação", ru: "Категория:Разговорники", zh: "Category:会话手册" };
const unwantedVoyage = /\bphrasebooks?\b|^Sprachführer\b|^Guías? de conversación\b|^Guides? linguistiques?\b|^שיחו[ןנ]|^Frasari[oi]?\b|会話集$|^Taalgids\b|^Rozmówki\b|^Guias? de conversação\b|разговорник|会话手册|會話手冊|^(?:travel topics?|itineraries)(?:[ :/]|$)/iu;
async function voyageArticles(language: Language, signal: AbortSignal): Promise<Article[]> {
  const payload = await query(language, "wikivoyage", { generator: "random", grnnamespace: 0, grnlimit: 12,
    ...props(), exlimit: 12, exchars: 1000, prop: "extracts|pageimages|description|info|pageprops|categories|images",
    cllimit: "max", clcategories: phrasebookCategories[language], imlimit: "max" }, signal);
  const pages = (payload.query?.pages ?? []).filter((page) => !unwantedVoyage.test(String(page.title)) && (!Array.isArray(page.categories) || !page.categories.length));
  for (const page of pages.filter((item) => !item.extract).slice(0, 6)) {
    try {
      const lead = await query(language, "wikivoyage", { pageids: Number(page.pageid), prop: "extracts", explaintext: 1, exsectionformat: "wiki", exchars: 1400 }, signal);
      page.extract = voyageLead(String(lead.query?.pages?.[0]?.extract ?? ""));
    } catch (error) { if (signal.aborted) throw error; }
  }
  const imagePicks = new Map<WikiPage, string[]>();
  for (const page of pages) if (!page.thumbnail && Array.isArray(page.images)) {
    const names = page.images.map((image) => String(image.title)).filter((name) => /^File:/i.test(name) && /\.(jpe?g|png|webp)$/i.test(name) && !/\b(flag|logo|icon|symbol|map|locator|coat.of.arms|gpx|pictogram|default|disambig)\b/i.test(name.replaceAll("_", " "))).sort((a, b) => Number(/banner/i.test(b)) - Number(/banner/i.test(a))).slice(0, 2);
    if (names.length) imagePicks.set(page, names);
  }
  const names = [...new Set([...imagePicks.values()].flat())].slice(0, 20);
  if (names.length) try {
    const url = new URL("https://commons.wikimedia.org/w/api.php");
    url.search = new URLSearchParams({ action: "query", titles: names.join("|"), prop: "imageinfo", iiprop: "url|size", iiurlwidth: "1000", format: "json", formatversion: "2", origin: "*" }).toString();
    const images = await json(url, signal);
    const normalized = new Map(images.query?.normalized?.map((item) => [item.from, item.to]) ?? []);
    for (const [page, candidates] of imagePicks) for (const name of candidates) {
      const match = images.query?.pages?.find((item) => item.title === (normalized.get(name) ?? name));
      const info = (match?.imageinfo as { thumburl?: string; url?: string; width?: number; height?: number }[] | undefined)?.[0];
      if (info && (info.width ?? 0) >= 240 && (info.height ?? 0) >= 100) {
        page.thumbnail = { source: info.thumburl ?? info.url };
        page.pageprops = { ...(page.pageprops as object ?? {}), page_image_free: name.replace(/^File:/, "") };
        break;
      }
    }
  } catch (error) { if (signal.aborted) throw error; }
  return pages.flatMap((page) => { const article = pageToArticle(page, language, "wikivoyage", /[\u3400-\u9fff\u3040-\u30ff]/.test(String(page.extract)) ? 20 : 40); return article ? [article] : []; });
}
export async function loadFeed(language: Language, mode: Mode, depth: Depth, cursor: number, seen: Set<string>, signal: AbortSignal): Promise<FeedResult> {
  const edition = mode === "voyage" && !voyageEditions.has(language) ? "en" : language;
  const key = mode === "onThisDay" ? `day:${language}:${dayStamp()}` : `batch:${mode}:${edition}:${depth}`;
  const cached = await readCache<FeedResult>(key);
  if (mode === "onThisDay" && cached?.articles.length) return { ...cached, cached: true };
  try {
    let articles: Article[], nextCursor = cursor, fallback = edition !== language;
    if (mode === "random") {
      const batch = await randomArticles(language, depth, cursor, seen, signal);
      articles = batch.articles; nextCursor = batch.cursor;
    } else if (mode === "voyage") {
      articles = [];
      for (let attempt = 0; attempt < 3 && !articles.length; attempt++) articles = (await voyageArticles(edition, signal)).filter((article) => !seen.has(article.id));
    } else {
      const date = new Date();
      const day = `${String(date.getMonth() + 1).padStart(2, "0")}/${String(date.getDate()).padStart(2, "0")}`;
      try { articles = eventArticles(await json(new URL(`https://${language}.wikipedia.org/api/rest_v1/feed/onthisday/events/${day}`), signal), language); }
      catch (error) { if (signal.aborted || language === "en") throw error; articles = []; }
      if (!articles.length && language !== "en") { articles = eventArticles(await json(new URL(`https://en.wikipedia.org/api/rest_v1/feed/onthisday/events/${day}`), signal), "en"); fallback = true; }
    }
    aborted(signal);
    if (!articles.length) throw new Error("No readable articles in this batch");
    const result = { articles, cursor: nextCursor, fallback, cached: false };
    await saveCache(key, result);
    await Promise.all(articles.map((article) => saveCache(`article:${article.source}:${article.language}:${article.title}`, article)));
    return result;
  } catch (error) {
    if (signal.aborted) throw error;
    const reusable = cached?.articles.filter((article) => !seen.has(article.id)) ?? [];
    if (cached && reusable.length) return { ...cached, articles: reusable, cached: true };
    throw error;
  }
}
export async function loadArticle(language: string, source: string, title: string, signal: AbortSignal): Promise<Article> {
  if (!isLanguage(language) || !["wikipedia", "wikivoyage"].includes(source) || title.length > 300 || title.includes("|")) throw new Error("Invalid article link");
  const cached = await readCache<Article>(`article:${source}:${language}:${title}`);
  if (cached) return cached;
  const articles = await byTitles(language, source as Source, [title], signal);
  if (!articles[0]) throw new Error("Article unavailable");
  return articles[0];
}
export async function loadRelated(article: Article, signal: AbortSignal): Promise<Article[]> {
  const key = `related:${article.id}`;
  const cached = await readCache<Article[]>(key);
  if (cached) return cached;
  const payload = await query(article.language, "wikipedia", { generator: "search", gsrsearch: `morelike:${article.title}`, gsrlimit: 8, gsrnamespace: 0, ...props() }, signal);
  const articles = (payload.query?.pages ?? []).flatMap((page) => { const item = pageToArticle(page, article.language, "wikipedia", 20); return item && item.title !== article.title ? [item] : []; }).slice(0, 6);
  await saveCache(key, articles);
  return articles;
}
export interface Credit { author: string; license: string; url: string }
export async function loadCredit(article: Article, signal: AbortSignal): Promise<Credit | undefined> {
  if (!article.imageFile) return;
  const url = new URL("https://commons.wikimedia.org/w/api.php");
  url.search = new URLSearchParams({ action: "query", titles: `File:${article.imageFile}`, prop: "imageinfo", iiprop: "extmetadata|url", format: "json", formatversion: "2", origin: "*" }).toString();
  const payload = await json(url, signal);
  const info = (payload.query?.pages?.[0]?.imageinfo as { descriptionurl?: string; extmetadata?: Record<string, { value?: string }> }[] | undefined)?.[0];
  if (!info) return;
  const plain = (value = "") => value.replace(/<[^>]*>/g, "").replaceAll("&amp;", "&").trim();
  return { author: plain(info.extmetadata?.Artist?.value), license: plain(info.extmetadata?.LicenseShortName?.value), url: info.descriptionurl ?? `https://commons.wikimedia.org/wiki/File:${encodeURIComponent(article.imageFile)}` };
}
