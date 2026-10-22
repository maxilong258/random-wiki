export const languages = [
  { code: "en", name: "English" }, { code: "es", name: "Español" },
  { code: "fr", name: "Français" }, { code: "de", name: "Deutsch" },
  { code: "it", name: "Italiano" }, { code: "pt", name: "Português" },
  { code: "ru", name: "Русский" }, { code: "ja", name: "日本語" },
  { code: "zh", name: "中文" }, { code: "ar", name: "العربية" },
  { code: "hi", name: "हिन्दी" }, { code: "ko", name: "한국어" },
  { code: "he", name: "עברית" }, { code: "nl", name: "Nederlands" },
  { code: "pl", name: "Polski" },
] as const;
export type Language = (typeof languages)[number]["code"];
export type Source = "wikipedia" | "wikivoyage";
export const depths = ["popular", "familiar", "balanced", "niche", "obscure"] as const;
export type Depth = (typeof depths)[number];
export type Mode = "random" | "onThisDay" | "voyage";
export type Screen = "discover" | "favorites" | "history";
export type Theme = "system" | "light" | "dark";
export interface Article {
  id: string; title: string; extract: string; language: Language; source: Source;
  url: string; description?: string; image?: string; imageFile?: string; year?: number;
}
export interface HistoryEntry { article: Article; openedAt: number }
export interface Settings { language: Language; theme: Theme; depth: Depth }
export const defaultSettings: Settings = { language: "zh", theme: "system", depth: "balanced" };
export const isLanguage = (value: unknown): value is Language => languages.some((item) => item.code === value);
export const articleId = (language: Language, source: Source, title: string) => `${source}:${language}:${title}`;
export const isRtl = (language: Language) => language === "ar" || language === "he";
export function validArticle(value: unknown): value is Article {
  if (!value || typeof value !== "object") return false;
  const item = value as Article;
  if (!isLanguage(item.language) || !["wikipedia", "wikivoyage"].includes(item.source) ||
      typeof item.title !== "string" || typeof item.extract !== "string" ||
      item.id !== articleId(item.language, item.source, item.title)) return false;
  try { return new URL(item.url).origin === `https://${item.language}.${item.source}.org`; } catch { return false; }
}
export function mergeHistory(entries: HistoryEntry[], article: Article, now = Date.now()): HistoryEntry[] {
  return [{ article, openedAt: now }, ...entries.filter((entry) => entry.article.id !== article.id)].slice(0, 100);
}
export function dayStamp(date = new Date()): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}
const viewScales: Record<string, number> = { zh: .2, ja: 1, ru: .6, de: .5, he: .4, fr: .3, it: .25, pt: .25, es: .25, pl: .2, ko: .2, hi: .15, ar: .15, nl: .1 };
export function viewBand(depth: Depth, language: Language): [number, number] {
  const band: [number, number] = depth === "obscure" ? [0, 2] : depth === "niche" ? [2, 30] : depth === "familiar" ? [100, 300] : depth === "popular" ? [300, Infinity] : [10, Infinity];
  const scale = viewScales[language] ?? 1;
  return [band[0] * scale, band[1] * scale];
}
export type WikiPage = Record<string, unknown>;
export function selectByDepth(pages: WikiPage[], depth: Depth, language: Language): WikiPage[] {
  const live = new Set<string>();
  for (const page of pages) {
    const views = page.pageviews;
    if (!views || typeof views !== "object") continue;
    for (const [day, value] of Object.entries(views)) if (typeof value === "number" && Number.isFinite(value) && value >= 0) live.add(day);
  }
  const scored = pages.flatMap((page) => {
    const views = page.pageviews;
    if (!views || typeof views !== "object") return [];
    const values = Object.entries(views).filter(([day]) => live.has(day)).map(([, value]) => value);
    if (!values.some((value) => typeof value === "number" && Number.isFinite(value) && value >= 0)) return [];
    const usable = values.filter((value) => value === null || (typeof value === "number" && Number.isFinite(value) && value >= 0));
    const sum = usable.reduce<number>((total, value) => total + (typeof value === "number" ? value : 0), 0);
    return [{ page, views: sum / usable.length }];
  });
  const [low, high] = viewBand(depth, language);
  const eligible = scored.filter(({ views }) => views >= low && views <= high);
  if (depth !== "balanced" || eligible.length >= 5) return eligible.slice(0, 20).map(({ page }) => page);
  const selected = new Set(eligible.map(({ page }) => page));
  const nearby = scored.filter(({ page, views }) => !selected.has(page) && views < low && Math.log1p(low) - Math.log1p(views) <= Math.log(2)).sort((a, b) => b.views - a.views);
  return [...eligible, ...nearby.slice(0, Math.min(3, 5 - eligible.length))].map(({ page }) => page);
}
export function pageToArticle(page: WikiPage, language: Language, source: Source = "wikipedia", minimum = 50): Article | undefined {
  const title = typeof page.title === "string" ? page.title.trim() : "";
  const extract = typeof page.extract === "string" ? page.extract.trim() : "";
  const props = page.pageprops as Record<string, unknown> | undefined;
  if (!title || extract.length < minimum || (props && "disambiguation" in props) || page.missing === true) return;
  const thumbnail = page.thumbnail as { source?: string } | undefined;
  return { id: articleId(language, source, title), title, extract, language, source,
    url: `https://${language}.${source}.org/wiki/${encodeURIComponent(title.replaceAll(" ", "_"))}`,
    description: typeof page.description === "string" ? page.description : undefined,
    image: thumbnail?.source?.startsWith("https://") ? thumbnail.source : undefined,
    imageFile: typeof props?.page_image_free === "string" ? props.page_image_free : undefined,
  };
}
export function eventArticles(payload: { events?: WikiPage[] }, language: Language): Article[] {
  return [...(payload.events ?? [])].sort((a, b) => Number(b.year) - Number(a.year)).flatMap((event) => {
    const text = typeof event.text === "string" ? event.text.trim() : "";
    const pages = Array.isArray(event.pages) ? (event.pages as WikiPage[]).filter((page) => {
      const namespace = page.namespace as { id?: number } | undefined;
      return typeof page.title === "string" && (!namespace || namespace.id === 0);
    }) : [];
    const topical = pages.filter((page) => !/^\d{1,4}年?$/.test(String(page.title)));
    const pool = topical.length ? topical : pages;
    const page = pool.find((page) => page.thumbnail) ?? pool[0];
    if (!page || !text) return [];
    const article = pageToArticle({ ...page, extract: text }, language, "wikipedia", 1);
    return article ? [{ ...article, year: Number(event.year) }] : [];
  });
}
export function voyageLead(text: string): string {
  const paragraphs = text.split(/\n\s*\n|\n(?=\s*=)/).map((part) => part.split("\n").filter((line) => !/^\s*=/.test(line) && !/^[^.!?。！？]{1,60}\s[-–—:]\s/.test(line)).join(" ").replace(/\s+/g, " ").trim());
  let lead = "";
  for (const part of paragraphs) {
    const minimum = /[\u3040-\u30ff\u3400-\u9fff\uac00-\ud7af]/.test(part) ? 25 : 60;
    if (part.length < minimum || !/[.!?。！？]/.test(part)) continue;
    lead += `${lead ? " " : ""}${part}`;
    if (lead.length >= 300) break;
  }
  return lead.replace(/[^.!?。！？]*$/, "").trim();
}
