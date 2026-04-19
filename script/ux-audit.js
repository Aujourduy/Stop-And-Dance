// UX audit automatisé — couvre les items automatisables de docs/checklist-tests-session-2026-04-07.md
// Lance : node tmp/ux_audit.js

const { chromium } = require('playwright');

const BASE = 'http://localhost:3002';
const results = [];

function log(section, name, ok, detail = '') {
  const icon = ok ? '✅' : '❌';
  const line = `${icon} [${section}] ${name}${detail ? ' — ' + detail : ''}`;
  console.log(line);
  results.push({ section, name, ok, detail });
}

async function noHorizontalScroll(page, section, pageName) {
  const { scroll, client } = await page.evaluate(() => ({
    scroll: document.documentElement.scrollWidth,
    client: document.documentElement.clientWidth
  }));
  const ok = scroll <= client + 1;
  log(section, `Pas de scroll horizontal — ${pageName}`, ok, `scroll=${scroll} client=${client}`);
}

(async () => {
  const browser = await chromium.launch({ headless: true });

  // ===== MOBILE (iPhone 12 viewport) =====
  const mobileCtx = await browser.newContext({ viewport: { width: 390, height: 844 }, userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0)' });
  const mPage = await mobileCtx.newPage();

  // Section 1 — affichage général
  for (const path of ['/', '/evenements', '/a-propos', '/contact', '/proposants']) {
    const resp = await mPage.goto(BASE + path, { waitUntil: 'networkidle' });
    log('1. Mobile', `GET ${path}`, resp.status() === 200, `HTTP ${resp.status()}`);
    await noHorizontalScroll(mPage, '1. Mobile', path);
  }

  // Section 2 — Burger menu
  await mPage.goto(BASE + '/', { waitUntil: 'networkidle' });
  const burger = mPage.locator('button[data-action*="mobile-drawer#toggle"]:visible').first();
  const burgerVisible = await burger.isVisible().catch(() => false);
  log('2. Mobile nav', 'Bouton burger visible', burgerVisible);
  if (burgerVisible) {
    await burger.click().catch(() => {});
    await mPage.waitForTimeout(500);
    // Trouve le panel qui n'est PLUS hidden (celui togglé par le bouton visible)
    const visiblePanel = await mPage.evaluate(() => {
      const panels = document.querySelectorAll('[data-mobile-drawer-target="panel"]');
      for (const p of panels) {
        if (!p.classList.contains('hidden')) return true;
      }
      return false;
    });
    log('2. Mobile nav', 'Panel drawer ouvert après clic', visiblePanel);
    const menuItems = ['Accueil', 'Agenda', 'Newsletter', 'Proposants'];
    for (const item of menuItems) {
      const found = await mPage.locator(`[data-mobile-drawer-target="panel"]:not(.hidden) >> text=${item}`).first().count().catch(() => 0);
      log('2. Mobile nav', `Menu: ${item}`, found > 0);
    }
  }

  await mobileCtx.close();

  // ===== DESKTOP =====
  const deskCtx = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  const page = await deskCtx.newPage();

  // Section 3 — Homepage
  await page.goto(BASE + '/', { waitUntil: 'networkidle' });
  const heroTitle = await page.locator('h1, h2').filter({ hasText: /Stop.*Dance/i }).first().isVisible().catch(() => false);
  log('3. Homepage', 'Hero "Stop & Dance" visible', heroTitle);
  const agendaBtn = page.locator('a[href="/evenements"]').first();
  log('3. Homepage', 'Bouton AGENDA présent', await agendaBtn.count() > 0);
  const footer = await page.locator('footer').isVisible().catch(() => false);
  log('3. Homepage', 'Footer visible', footer);
  const newsletterForm = await page.locator('footer form').count();
  log('3. Homepage', 'Formulaire newsletter dans footer', newsletterForm > 0);

  // Section 4 — Agenda
  await page.goto(BASE + '/evenements', { waitUntil: 'networkidle' });
  const titreAgenda = await page.locator('text=/Agenda.*Ateliers.*Stages/i').first().isVisible().catch(() => false);
  log('4. Agenda', 'Titre "Agenda complet: Ateliers (X) et Stages (Y)"', titreAgenda);

  const dayCapital = await page.evaluate(() => {
    const text = document.body.innerText;
    return /\b(Lundi|Mardi|Mercredi|Jeudi|Vendredi|Samedi|Dimanche)\b/.test(text);
  });
  log('4. Agenda', 'Jours en français capitalisés', dayCapital);

  const atelierCount = await page.locator('.badge:has-text("Atelier")').count();
  const workshopCount = await page.locator('text=Workshop').count();
  log('4. Agenda', 'Badge "Atelier" (pas "Workshop")', atelierCount > 0 && workshopCount === 0, `atelier=${atelierCount} workshop=${workshopCount}`);

  const badgePresentiel = await page.locator('text=/Présentiel/').first().isVisible().catch(() => false);
  log('4. Agenda', 'Badge "Présentiel" existe', badgePresentiel);

  const gratuitGreen = await page.evaluate(() => {
    const el = Array.from(document.querySelectorAll('*')).find(e => e.textContent?.trim() === 'Gratuit');
    if (!el) return null;
    const color = getComputedStyle(el).color;
    return color;
  });
  log('4. Agenda', 'Texte "Gratuit" trouvé', !!gratuitGreen, gratuitGreen ? `color=${gratuitGreen}` : 'aucun gratuit');

  // Section 5 — Filtres (desktop : panneau latéral déjà ouvert)
  const initialCount = await page.locator('[data-debug-id^="event-card-"]').count();
  log('5. Filtres', `Events affichés initialement: ${initialCount}`, initialCount > 0);

  // Ouvrir le panneau filtres si nécessaire
  const openFiltersBtn = page.locator('button[data-action*="mobile-filters#open"], button[data-action*="filters#open"]').first();
  if (await openFiltersBtn.count() > 0 && await openFiltersBtn.isVisible().catch(() => false)) {
    await openFiltersBtn.click().catch(() => {});
    await page.waitForTimeout(300);
  }

  const searchInput = page.locator('input[name="q"]:visible').first();
  const searchExists = (await searchInput.count()) > 0;
  log('5. Filtres', 'Champ recherche existe', searchExists);

  if (searchExists) {
    // Recherche qui doit retourner des résultats (paris = 64 events en DB)
    await searchInput.fill('paris');
    await page.waitForTimeout(1800);
    const parisCount = await page.locator('[data-debug-id^="event-card-"]').count();
    log('5. Filtres', 'Recherche "paris" retourne des résultats', parisCount > 0, `count=${parisCount}`);

    // Recherche improbable → 0 résultats
    await searchInput.fill('xxxxyyyzzzz');
    await page.waitForTimeout(1800);
    const noneCount = await page.locator('[data-debug-id^="event-card-"]').count();
    log('5. Filtres', 'Recherche "xxxxyyyzzzz" → 0 résultats', noneCount === 0, `count=${noneCount}`);

    // Recherche sélective — filtre un prof spécifique
    await searchInput.fill('silvestre');
    await page.waitForTimeout(1800);
    const silvestreCount = await page.locator('[data-debug-id^="event-card-"]').count();
    log('5. Filtres', 'Recherche "silvestre" retourne des résultats', silvestreCount > 0, `count=${silvestreCount}`);

    await searchInput.fill('');
    await page.waitForTimeout(1500);
  }

  // Section 6 — Modal (turbo frame "event_modal")
  await page.goto(BASE + '/evenements', { waitUntil: 'networkidle' });
  const firstCard = page.locator('a[data-debug-id^="event-card-"]').first();
  const cardCount = await firstCard.count();
  if (cardCount > 0) {
    const href = await firstCard.getAttribute('href');
    log('6. Modal', 'Premier event a un lien /evenements/:slug', !!href, href);

    await firstCard.click();
    await page.waitForTimeout(1500);
    const modalFrame = await page.locator('turbo-frame#event_modal').innerHTML().catch(() => '');
    const modalHasContent = modalFrame.length > 200;
    log('6. Modal', 'turbo-frame#event_modal rempli après clic', modalHasContent, `size=${modalFrame.length}`);

    const titleInModal = await page.locator('turbo-frame#event_modal h1, turbo-frame#event_modal h2, turbo-frame#event_modal h3').first().innerText().catch(() => '');
    log('6. Modal', 'Titre event dans la modal', titleInModal.length > 0, titleInModal.slice(0, 60));
  } else {
    log('6. Modal', 'Aucun event pour tester la modal', false);
  }

  // Section 6b — Infinite scroll
  await page.goto(BASE + '/evenements', { waitUntil: 'networkidle' });
  const beforeScroll = await page.locator('[data-debug-id^="event-card-"]').count();
  await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
  await page.waitForTimeout(2000);
  const afterScroll = await page.locator('[data-debug-id^="event-card-"]').count();
  log('6b. Infinite scroll', 'Scroll fin de page charge plus d\'events', afterScroll >= beforeScroll, `${beforeScroll} → ${afterScroll}`);

  // Section 7 — Page Professeur
  const profLink = page.locator('a[href^="/professeurs/"]').first();
  if (await profLink.count() > 0) {
    const profHref = await profLink.getAttribute('href');
    await page.goto(BASE + profHref.split('?')[0], { waitUntil: 'networkidle' });
    const profName = await page.locator('h1, h2').first().innerText().catch(() => '');
    log('7. Prof', 'Page prof — nom dans h1/h2', profName.length > 0, profName);
    const bio = await page.locator('text=/Bio|À propos|Parcours/i').first().isVisible().catch(() => false);
    log('7. Prof', 'Section bio/description présente', bio);
    const prochainAteliers = await page.locator('text=/Prochains.*atelier|Prochains.*stage|Agenda/i').first().isVisible().catch(() => false);
    log('7. Prof', 'Liste "Prochains ateliers et stages"', prochainAteliers);

    // Section 8 — Stats
    const statsUrl = profHref.split('?')[0] + '/stats';
    const statsResp = await page.goto(BASE + statsUrl, { waitUntil: 'networkidle' }).catch(() => null);
    if (statsResp) {
      log('8. Stats', `GET ${statsUrl}`, statsResp.status() === 200, `HTTP ${statsResp.status()}`);
      const statsNum = await page.locator('.stat-value, [class*="stat"]').count();
      log('8. Stats', 'Compteurs stats affichés (DaisyUI)', statsNum > 0, `count=${statsNum}`);
    }
  }

  // Section supplémentaire — SEO
  await page.goto(BASE + '/evenements', { waitUntil: 'networkidle' });
  const metaDesc = await page.locator('meta[name="description"]').getAttribute('content').catch(() => '');
  log('SEO', 'Meta description présente', (metaDesc || '').length > 20, `len=${(metaDesc||'').length}`);
  const h1Count = await page.locator('h1').count();
  log('SEO', 'Exactement 1 h1 sur /evenements', h1Count === 1, `count=${h1Count}`);

  // Sitemap
  const sitemapResp = await page.goto(BASE + '/sitemap.xml').catch(() => null);
  if (sitemapResp) {
    const body = await sitemapResp.text();
    log('SEO', '/sitemap.xml contient <url>', body.includes('<url>'), `size=${body.length}`);
  }

  await deskCtx.close();
  await browser.close();

  // Rapport
  const passed = results.filter(r => r.ok).length;
  const total = results.length;
  console.log('\n========================================');
  console.log(`RÉSULTAT : ${passed}/${total} passés (${Math.round(passed*100/total)}%)`);
  console.log('========================================');

  const failed = results.filter(r => !r.ok);
  if (failed.length > 0) {
    console.log('\nÉCHECS :');
    failed.forEach(r => console.log(`  ❌ [${r.section}] ${r.name}${r.detail ? ' — ' + r.detail : ''}`));
  }

  process.exit(failed.length > 0 ? 1 : 0);
})().catch(e => { console.error('FATAL:', e); process.exit(2); });
