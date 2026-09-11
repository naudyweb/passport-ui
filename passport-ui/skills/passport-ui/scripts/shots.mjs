#!/usr/bin/env node
// passport-ui: capturas en perfiles de viewport pasaporte. Fallback de CI para cuando no hay Chrome MCP.
// Uso: node shots.mjs <url> [outDir]
// Requiere playwright ya instalado en el proyecto. No lo instala por su cuenta.

const [, , url = 'http://localhost:3000', outDir = './passport-shots'] = process.argv;

const PROFILES = [
  { name: 'passport-cover-xs', width: 820, height: 490, dpr: 2.5 },
  { name: 'passport-cover', width: 880, height: 550, dpr: 2.5 },
  { name: 'passport-wide', width: 900, height: 535, dpr: 2.5 },
  { name: 'unfolded', width: 1000, height: 750, dpr: 2 },
  { name: 'phone-tall', width: 390, height: 844, dpr: 3 },
];

const PROBE = () => {
  const vw = innerWidth, vh = innerHeight;
  const fixedPx = [...document.querySelectorAll('body *')]
    .filter((el) => ['fixed', 'sticky'].includes(getComputedStyle(el).position))
    .filter((el) => el.getBoundingClientRect().width > vw * 0.5)
    .reduce((sum, el) => sum + el.getBoundingClientRect().height, 0);
  const overflowing = [...document.querySelectorAll('body *')]
    .filter((el) => el.getBoundingClientRect().right > vw + 1)
    .slice(0, 10)
    .map((el) => el.tagName.toLowerCase() + (el.className ? '.' + String(el.className).split(' ')[0] : ''));
  return {
    viewport: `${vw}x${vh}`,
    pageHeight: document.scrollingElement.scrollHeight,
    screensOfScroll: +(document.scrollingElement.scrollHeight / vh).toFixed(1),
    horizontalScroll: document.scrollingElement.scrollWidth > vw + 1,
    fixedChromePct: Math.round((fixedPx / vh) * 100),
    overflowing,
  };
};

let chromium;
try {
  ({ chromium } = await import('playwright'));
} catch {
  console.error('playwright no está instalado en este proyecto.');
  console.error('Usa el camino principal (Chrome MCP) descrito en references/verify.md,');
  console.error('o instala playwright a mano si de verdad lo necesitas en CI.');
  process.exit(2);
}

const { mkdir } = await import('node:fs/promises');
await mkdir(outDir, { recursive: true });

const browser = await chromium.launch();
const rows = [];

for (const p of PROFILES) {
  const ctx = await browser.newContext({
    viewport: { width: p.width, height: p.height },
    deviceScaleFactor: p.dpr,
    isMobile: true,
    hasTouch: true,
  });
  const page = await ctx.newPage();
  try {
    await page.goto(url, { waitUntil: 'networkidle', timeout: 30_000 });
    const probe = await page.evaluate(PROBE);
    const file = `${outDir}/${p.name}.png`;
    await page.screenshot({ path: file });
    const verdict =
      probe.horizontalScroll || probe.fixedChromePct > 25 || probe.overflowing.length ? 'FALLA' : 'pasa';
    rows.push({ perfil: p.name, ...probe, overflowing: probe.overflowing.join(', ') || '—', verdict, file });
  } catch (err) {
    rows.push({ perfil: p.name, verdict: 'ERROR', error: err.message });
  }
  await ctx.close();
}

await browser.close();
console.table(rows);
console.log(`\nCapturas en ${outDir}/`);
process.exit(rows.some((r) => r.verdict !== 'pasa') ? 1 : 0);
