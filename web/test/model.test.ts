import test from "node:test";
import assert from "node:assert/strict";
import { articleId, dayStamp, eventArticles, mergeHistory, pageToArticle, selectByDepth, validArticle, viewBand, voyageLead, type Article } from "../src/lib/model.ts";

const article = (title: string): Article => ({ id: articleId("zh", "wikipedia", title), title, extract: "一段真实文章格式的导语。", source: "wikipedia", language: "zh", url: `https://zh.wikipedia.org/wiki/${encodeURIComponent(title)}` });
test("rereading moves one history entry to the front and retains the latest 100", () => {
  const entries = Array.from({ length: 100 }, (_, index) => ({ article: article(`条目${index}`), openedAt: 100 - index }));
  const reread = mergeHistory(entries, article("条目99"), 200);
  assert.equal(reread.length, 100);
  assert.equal(reread[0].article.title, "条目99");
  assert.equal(reread.filter((item) => item.article.title === "条目99").length, 1);
  const added = mergeHistory(reread, article("新条目"), 201);
  assert.equal(added.length, 100);
  assert.equal(added.at(-1)?.article.title, "条目97");
});
test("Wikipedia and Wikivoyage entries with the same title cannot overwrite each other", () => {
  assert.notEqual(articleId("zh", "wikipedia", "京都"), articleId("zh", "wikivoyage", "京都"));
  assert.notEqual(articleId("zh", "wikipedia", "Earth"), articleId("en", "wikipedia", "Earth"));
});
test("stored article validation rejects external or executable links", () => {
  assert.equal(validArticle(article("京都")), true);
  assert.equal(validArticle({ ...article("京都"), url: "javascript:alert(1)" }), false);
  assert.equal(validArticle({ ...article("京都"), url: "https://example.com/" }), false);
  assert.equal(validArticle({ ...article("京都"), id: "wrong-key" }), false);
  assert.equal(validArticle(null), false);
});
test("view bands preserve Flutter language scaling", () => {
  assert.deepEqual(viewBand("obscure", "en"), [0, 2]);
  assert.deepEqual(viewBand("obscure", "zh"), [0, .4]);
  assert.deepEqual(viewBand("balanced", "zh"), [2, Infinity]);
});
test("late pageview days are ignored and unknown readership is not counted as zero", () => {
  const pages = [
    { title: "low", pageviews: { d1: 1, d2: null } },
    { title: "quiet", pageviews: { d1: 0, d2: null } },
    { title: "unknown" },
    { title: "popular", pageviews: { d1: 40, d2: null } },
  ];
  assert.deepEqual(selectByDepth(pages, "obscure", "en").map((page) => page.title), ["low", "quiet"]);
});
test("balanced selection allows close candidates without including distant low-view pages", () => {
  const pages = [{ title: "eligible", pageviews: { d1: 20 } }, { title: "close", pageviews: { d1: 8 } }, { title: "far", pageviews: { d1: 1 } }];
  assert.deepEqual(selectByDepth(pages, "balanced", "en").map((page) => page.title), ["eligible", "close"]);
});
test("article parsing excludes disambiguation and unreadably short summaries", () => {
  const extract = "维基百科是一部自由内容、公开编辑的网络百科全书。".repeat(3);
  assert.equal(pageToArticle({ title: "消歧义", extract, pageprops: { disambiguation: "" } }, "zh"), undefined);
  assert.equal(pageToArticle({ title: "短文", extract: "短" }, "zh"), undefined);
  assert.equal(pageToArticle({ title: "正常", extract }, "zh")?.title, "正常");
});
test("on-this-day prefers topical pictured pages, filters namespaces, and sorts by year", () => {
  const payload = { events: [
    { year: 1900, text: "较早的事件。", pages: [{ title: "1900年" }, { title: "主题", thumbnail: { source: "https://upload.wikimedia.org/image.jpg" }, namespace: { id: 0 } }] },
    { year: 2000, text: "较近的事件。", pages: [{ title: "分类", namespace: { id: 14 } }, { title: "新事件", namespace: { id: 0 } }] },
  ] };
  const parsed = eventArticles(payload, "zh");
  assert.deepEqual(parsed.map((entry) => entry.title), ["新事件", "主题"]);
  assert.equal(parsed[1].extract, "较早的事件。");
  assert.equal(parsed[1].year, 1900);
});
test("Wikivoyage prose extraction does not expose section markup or clipped trailing sentences", () => {
  const lead = voyageLead("== 了解 ==\n\n京都是一座拥有悠久历史的日本古都，寺庙和庭园遍布城市，适合步行游览。\n\n== 交通 ==\n\n一段尚未完成");
  assert.match(lead, /^京都/);
  assert.doesNotMatch(lead, /==|一段尚未完成/);
});
test("on-this-day cache keys follow the local calendar date", () => {
  assert.equal(dayStamp(new Date(2026, 0, 2, 0, 1)), "2026-01-02");
});
