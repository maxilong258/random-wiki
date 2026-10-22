import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Random Wiki — 让好奇心，随处漫游",
  description: "上下滑动，随机发现维基百科、历史上的今天和旅行目的地。收藏好奇，漫游知识。",
  applicationName: "Random Wiki",
  icons: { icon: "/icon.svg" },
  openGraph: { title: "Random Wiki", description: "A whole new world, one article away.", type: "website" },
};
export const viewport: Viewport = { width: "device-width", initialScale: 1, themeColor: "#f7f7f2" };
const themeScript = `try{const s=JSON.parse(localStorage.getItem('random-wiki:settings')||'{}');document.documentElement.dataset.theme=s.theme==='dark'||((!s.theme||s.theme==='system')&&matchMedia('(prefers-color-scheme:dark)').matches)?'dark':'light'}catch{}`;
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="zh" suppressHydrationWarning><head><script dangerouslySetInnerHTML={{ __html: themeScript }} /></head><body>{children}</body></html>;
}
