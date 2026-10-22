import { create } from "zustand";
import { defaultSettings, depths, isLanguage, mergeHistory, validArticle, type Article, type HistoryEntry, type Settings } from "./model";
import { pruneCache, readData, writeData } from "./storage";

interface ReaderState {
  settings: Settings; favorites: Article[]; history: HistoryEntry[]; hydrated: boolean; storageWarning: boolean;
  hydrate: () => Promise<void>;
  updateSettings: (patch: Partial<Settings>) => void;
  toggleFavorite: (article: Article) => void;
  record: (article: Article) => void;
}
let hydration: Promise<void> | undefined;
export const useReaderStore = create<ReaderState>((set, get) => ({
  settings: defaultSettings, favorites: [], history: [], hydrated: false, storageWarning: false,
  hydrate: () => hydration ??= (async () => {
    let settings = defaultSettings;
    try {
      const stored = JSON.parse(localStorage.getItem("random-wiki:settings") ?? "{}");
      settings = { language: isLanguage(stored.language) ? stored.language : "zh",
        depth: depths.includes(stored.depth) ? stored.depth : "balanced",
        theme: ["system", "light", "dark"].includes(stored.theme) ? stored.theme : "system" };
    } catch { set({ storageWarning: true }); }
    set({ settings });
    try {
      const [favorites, history] = await Promise.all([readData<unknown[]>("favorites"), readData<HistoryEntry[]>("history")]);
      set({ favorites: Array.isArray(favorites) ? favorites.filter(validArticle) : [],
        history: Array.isArray(history) ? history.filter((entry) => validArticle(entry?.article) && Number.isFinite(entry.openedAt)).sort((a, b) => b.openedAt - a.openedAt).slice(0, 100) : [] });
    } catch { set({ storageWarning: true }); }
    set({ hydrated: true });
    void pruneCache();
  })(),
  updateSettings: (patch) => {
    const settings = { ...get().settings, ...patch };
    set({ settings });
    try { localStorage.setItem("random-wiki:settings", JSON.stringify(settings)); } catch { set({ storageWarning: true }); }
  },
  toggleFavorite: (article) => {
    const previous = get().favorites;
    const favorites = previous.some((item) => item.id === article.id) ? previous.filter((item) => item.id !== article.id) : [article, ...previous];
    set({ favorites });
    void writeData("favorites", favorites).catch(() => set({ storageWarning: true }));
  },
  record: (article) => {
    const history = mergeHistory(get().history, article);
    set({ history });
    void writeData("history", history).catch(() => set({ storageWarning: true }));
  },
}));
