"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import type { Article, Mode, Settings } from "./model";
import { loadFeed } from "./wiki";

interface FeedState { articles: Article[]; index: number; loading: boolean; moreLoading: boolean; error: boolean; moreError: boolean; fallback: boolean }
const initial: FeedState = { articles: [], index: 0, loading: true, moreLoading: false, error: false, moreError: false, fallback: false };
export function useFeed(settings: Settings, mode: Mode, ready: boolean) {
  const [state, setState] = useState(initial);
  const [revision, setRevision] = useState(0);
  const stateRef = useRef(state);
  stateRef.current = state;
  const request = useRef<AbortController | null>(null);
  const generation = useRef(0), cursor = useRef(0), busy = useRef(false);
  const seen = useRef(new Set<string>());
  const effectiveDepth = mode === "random" ? settings.depth : "balanced";

  useEffect(() => {
    if (!ready) return;
    const epoch = ++generation.current;
    const controller = new AbortController();
    request.current?.abort(); request.current = controller;
    cursor.current = 0; seen.current = new Set(); busy.current = true;
    setState(initial);
    void loadFeed(settings.language, mode, effectiveDepth, 0, new Set(), controller.signal).then((batch) => {
      if (epoch !== generation.current || controller.signal.aborted) return;
      cursor.current = batch.cursor;
      for (const article of batch.articles) seen.current.add(article.id);
      setState({ ...initial, articles: batch.articles, loading: false, fallback: batch.fallback });
    }).catch(() => {
      if (epoch === generation.current && !controller.signal.aborted) setState({ ...initial, loading: false, error: true });
    }).finally(() => { if (epoch === generation.current) busy.current = false; });
    return () => controller.abort();
  }, [ready, settings.language, mode, effectiveDepth, revision]);

  const loadMore = useCallback(async () => {
    if (busy.current || mode === "onThisDay" || !stateRef.current.articles.length) return false;
    const epoch = generation.current;
    const controller = new AbortController();
    request.current = controller; busy.current = true;
    setState((previous) => ({ ...previous, moreLoading: true, moreError: false }));
    try {
      const batch = await loadFeed(settings.language, mode, effectiveDepth, cursor.current, new Set(seen.current), controller.signal);
      if (epoch !== generation.current || controller.signal.aborted) return false;
      cursor.current = batch.cursor;
      const unique = batch.articles.filter((article) => !seen.current.has(article.id));
      for (const article of unique) seen.current.add(article.id);
      if (!unique.length) throw new Error("No new articles");
      setState((previous) => ({ ...previous, articles: [...previous.articles, ...unique], moreLoading: false, fallback: batch.fallback }));
      return true;
    } catch {
      if (epoch === generation.current && !controller.signal.aborted) setState((previous) => ({ ...previous, moreLoading: false, moreError: true }));
      return false;
    } finally { if (epoch === generation.current) busy.current = false; }
  }, [settings.language, mode, effectiveDepth]);

  useEffect(() => {
    if (!state.loading && !state.moreError && state.articles.length && state.index >= state.articles.length - 3) void loadMore();
  }, [state.index, state.articles.length, state.loading, state.moreError, loadMore]);
  useEffect(() => () => { generation.current++; request.current?.abort(); }, []);

  const previous = useCallback(() => setState((current) => ({ ...current, index: Math.max(0, current.index - 1) })), []);
  const next = useCallback(async () => {
    const current = stateRef.current;
    if (current.index < current.articles.length - 1) {
      setState((previous) => ({ ...previous, index: Math.min(previous.index + 1, previous.articles.length - 1) }));
    } else if (await loadMore()) {
      setState((previous) => ({ ...previous, index: Math.min(previous.index + 1, previous.articles.length - 1) }));
    }
  }, [loadMore]);
  const retry = useCallback(() => setRevision((value) => value + 1), []);
  return { ...state, current: state.articles[state.index], previous, next, loadMore, retry };
}
