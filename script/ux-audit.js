// UX audit automatisé headless (Playwright) — couvre docs/checklist-tests-session-2026-04-07.md
// Lance : node script/ux-audit.js (serveur Rails sur :3002 requis)

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

  // ======================================================
  // MOBILE (iPhone 12 viewport)
  // ======================================================
  const mobileCtx = await browser.newContext({ viewport: { width: 390, height: 844 }, userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0)' });
  const mPage = await mobileCtx.newPage();

  // Section 1 — affichage général sur 5 pages
  for (const path of ['/', '/evenements', '/a-propos', '/contact', '/proposants']) {
    const resp = await mPage.goto(BASE + path, { waitUntil: 'networkidle' });
    log('1. Mobile', `GET ${path}`, resp.status() === 200, `HTTP ${resp.status()}`);
    await noHorizontalScroll(mPage, '1. Mobile', path);
  }

  // Section 2 — Burger menu + navigation depuis drawer
  await mPage.goto(BASE + '/', { waitUntil: 'networkidle' });
  const burger = mPage.locator('button[data-action*="mobile-drawer#toggle"]:visible').first();
  const burgerVisible = await burger.isVisible().catch(() => false);
  log('2. Mobile nav', 'Bouton burger visible', burgerVisible);

  if (burgerVisible) {
    await burger.click();
    await mPage.waitForTimeout(500);

    const visiblePanel = await mPage.evaluate(() =>
      Array.from(document.querySelectorAll('[data-mobile-drawer-target="panel"]'))
        .some(p => !p.classList.contains('hidden'))
    );
    log('2. Mobile nav', 'Panel drawer ouvert après clic', visiblePanel);

    for (const item of ['Accueil', 'Agenda', 'Newsletter', 'Proposants']) {
      const found = await mPage.locator(`[data-mobile-drawer-target="panel"]:not(.hidden) >> text=${item}`).first().count().catch(() => 0);
      log('2. Mobile nav', `Menu: ${item}`, found > 0);
    }

    // Navigation depuis le drawer
    const agendaLink = mPage.locator('[data-mobile-drawer-target="panel"]:not(.hidden) a[href="/evenements"]').first();
    if (await agendaLink.count() > 0) {
      await Promise.all([
        mPage.waitForURL(/\/evenements$/, { timeout: 5000 }).catch(() => {}),
        agendaLink.click()
      ]);
      log('2. Mobile nav', 'Clic "Agenda" → /evenements', /\/evenements$/.test(mPage.url()), mPage.url());
    } else {
      log('2. Mobile nav', 'Clic "Agenda" → /evenements', false, 'lien introuvable');
    }

    // Fermeture drawer via touche Escape (géré par mobile_drawer_controller)
    await mPage.goto(BASE + '/', { waitUntil: 'networkidle' });
    await mPage.locator('button[data-action*="mobile-drawer#toggle"]:visible').first().click();
    await mPage.waitForTimeout(400);
    await mPage.keyboard.press('Escape');
    await mPage.waitForTimeout(400);
    const closedAfterEsc = await mPage.evaluate(() =>
      Array.from(document.querySelectorAll('[data-mobile-drawer-target="panel"]'))
        .every(p => p.classList.contains('hidden'))
    );
    log('2. Mobile nav', 'Touche Escape ferme le drawer', closedAfterEsc);
  }

  await mobileCtx.close();

  // ======================================================
  // DESKTOP
  // ======================================================
  const deskCtx = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  const page = await deskCtx.newPage();

  // Section 3 — Homepage : clic sur bouton AGENDA
  await page.goto(BASE + '/', { waitUntil: 'networkidle' });
  const heroTitle = await page.locator('h1, h2').filter({ hasText: /Stop.*Dance/i }).first().isVisible().catch(() => false);
  log('3. Homepage', 'Hero "Stop & Dance" visible', heroTitle);

  const agendaBtn = page.locator('a[href="/evenements"]:visible').filter({ hasText: /AGENDA/ }).first();
  const agendaBtnCount = await agendaBtn.count();
  log('3. Homepage', 'Bouton AGENDA présent', agendaBtnCount > 0);

  if (agendaBtnCount > 0) {
    await Promise.all([
      page.waitForURL(/\/evenements$/, { timeout: 5000 }).catch(() => {}),
      agendaBtn.click()
    ]);
    log('3. Homepage', 'Clic AGENDA → /evenements', /\/evenements$/.test(page.url()), page.url());
    await page.goto(BASE + '/', { waitUntil: 'networkidle' });
  }

  const footer = await page.locator('footer').isVisible().catch(() => false);
  log('3. Homepage', 'Footer visible', footer);
  const newsletterFormCount = await page.locator('footer form').count();
  log('3. Homepage', 'Formulaire newsletter dans footer', newsletterFormCount > 0);

  // Saisie newsletter (sans submit — on teste juste que l'input accepte)
  const newsletterEmail = page.locator('footer input[name="newsletter[email]"]').first();
  if (await newsletterEmail.count() > 0) {
    await newsletterEmail.fill('test@example.invalid');
    const val = await newsletterEmail.inputValue();
    log('3. Homepage', 'Newsletter: saisie email OK', val === 'test@example.invalid', `val="${val}"`);
    await newsletterEmail.fill('');
  }

  // Section 4 — Agenda (affichage et contenu)
  await page.goto(BASE + '/evenements', { waitUntil: 'networkidle' });
  const titreAgenda = await page.locator('text=/Agenda.*Ateliers.*Stages/i').first().isVisible().catch(() => false);
  log('4. Agenda', 'Titre "Agenda complet..."', titreAgenda);

  const dayCapital = await page.evaluate(() =>
    /\b(Lundi|Mardi|Mercredi|Jeudi|Vendredi|Samedi|Dimanche)\b/.test(document.body.innerText)
  );
  log('4. Agenda', 'Jours en français capitalisés', dayCapital);

  const atelierCount = await page.locator('.badge:has-text("Atelier")').count();
  const workshopCount = await page.locator('text=Workshop').count();
  log('4. Agenda', 'Badge "Atelier" (pas "Workshop")', atelierCount > 0 && workshopCount === 0, `atelier=${atelierCount} workshop=${workshopCount}`);

  const badgePresentiel = await page.locator('text=/Présentiel/').first().isVisible().catch(() => false);
  log('4. Agenda', 'Badge "Présentiel" existe', badgePresentiel);

  const gratuitCount = await page.locator('text=/Gratuit/i').count();
  log('4. Agenda', 'Texte "Gratuit" présent dans la page', gratuitCount > 0, `count=${gratuitCount}`);

  // Section 5 — Filtres : recherche + checkboxes + champ lieu + date
  const initialCount = await page.locator('[data-debug-id^="event-card-"]').count();
  log('5. Filtres', `Events affichés initialement: ${initialCount}`, initialCount > 0);

  const searchInput = page.locator('input[name="q"]:visible').first();
  const searchExists = (await searchInput.count()) > 0;
  log('5. Filtres', 'Champ recherche "q" existe', searchExists);

  if (searchExists) {
    // Recherche courante → résultats
    await searchInput.fill('paris');
    await page.waitForTimeout(1800);
    const parisCount = await page.locator('[data-debug-id^="event-card-"]').count();
    log('5. Filtres', 'Recherche "paris" → résultats', parisCount > 0, `count=${parisCount}`);

    // Recherche improbable → 0
    await searchInput.fill('xxxxyyyzzzz');
    await page.waitForTimeout(1800);
    const noneCount = await page.locator('[data-debug-id^="event-card-"]').count();
    log('5. Filtres', 'Recherche "xxxxyyyzzzz" → 0 résultats', noneCount === 0, `count=${noneCount}`);

    // Filtre AND multi-mots (marc + rennes OU similaire — on teste juste le AND)
    await searchInput.fill('marc silvestre');
    await page.waitForTimeout(1800);
    const multiCount = await page.locator('[data-debug-id^="event-card-"]').count();
    log('5. Filtres', 'Recherche "marc silvestre" → résultats filtrés', multiCount > 0, `count=${multiCount}`);

    // Reset
    await searchInput.fill('');
    await page.waitForTimeout(1800);
    const resetCount = await page.locator('[data-debug-id^="event-card-"]').count();
    log('5. Filtres', 'Effacer recherche → retour à tous les events', resetCount === initialCount, `${resetCount} === ${initialCount}`);
  }

  // Checkbox "Gratuit"
  const cbGratuit = page.locator('input[name="gratuit"]:visible').first();
  if (await cbGratuit.count() > 0) {
    await cbGratuit.check();
    await page.waitForTimeout(1800);
    const afterGratuit = await page.locator('[data-debug-id^="event-card-"]').count();
    log('5. Filtres', 'Checkbox "Gratuit" filtre', afterGratuit !== initialCount, `${initialCount} → ${afterGratuit}`);
    await cbGratuit.uncheck();
    await page.waitForTimeout(1500);
  }

  // Checkbox "Stage"
  const cbStage = page.locator('input[name="stage"]:visible').first();
  if (await cbStage.count() > 0) {
    await cbStage.check();
    await page.waitForTimeout(1800);
    const afterStage = await page.locator('[data-debug-id^="event-card-"]').count();
    log('5. Filtres', 'Checkbox "Stage" filtre', afterStage !== initialCount, `${initialCount} → ${afterStage}`);
    await cbStage.uncheck();
    await page.waitForTimeout(1500);
  }

  // Checkbox "En ligne"
  const cbEnLigne = page.locator('input[name="en_ligne"]:visible').first();
  if (await cbEnLigne.count() > 0) {
    await cbEnLigne.check();
    await page.waitForTimeout(1800);
    const afterEnLigne = await page.locator('[data-debug-id^="event-card-"]').count();
    log('5. Filtres', 'Checkbox "En ligne" filtre', afterEnLigne !== initialCount, `${initialCount} → ${afterEnLigne}`);
    await cbEnLigne.uncheck();
    await page.waitForTimeout(1500);
  }

  // Champ "Lieu" — le form submit via turbo-frame, on sniffe la requête
  const lieuInput = page.locator('input[name="lieu"]:visible').first();
  if (await lieuInput.count() > 0) {
    const reqPromise = page.waitForRequest(req => req.url().includes('lieu=Paris'), { timeout: 5000 }).catch(() => null);
    await lieuInput.fill('Paris');
    await page.evaluate(() => document.activeElement && document.activeElement.blur());
    const req = await reqPromise;
    await page.waitForTimeout(1000);
    log('5. Filtres', 'Champ "Lieu" déclenche filtre serveur', !!req, req ? req.url().split('?')[1].slice(0, 80) : 'pas de requête');
    await page.goto(BASE + '/evenements', { waitUntil: 'networkidle' });
  }

  // Section 6 — Modal (ouverture + fermeture)
  await page.goto(BASE + '/evenements', { waitUntil: 'networkidle' });
  const firstCard = page.locator('a[data-debug-id^="event-card-"]').first();
  if (await firstCard.count() > 0) {
    const href = await firstCard.getAttribute('href');
    log('6. Modal', 'Premier event a un lien /evenements/:slug', !!href, href);

    await firstCard.click();
    await page.waitForTimeout(1500);

    const modalFrame = await page.locator('turbo-frame#event_modal').innerHTML().catch(() => '');
    log('6. Modal', 'turbo-frame#event_modal rempli après clic', modalFrame.length > 200, `size=${modalFrame.length}`);

    const titleInModal = await page.locator('turbo-frame#event_modal h1, turbo-frame#event_modal h2, turbo-frame#event_modal h3').first().innerText().catch(() => '');
    log('6. Modal', 'Titre event dans la modal', titleInModal.length > 0, titleInModal.slice(0, 60));

    // Bouton × : <a href="/evenements" data-turbo-frame="_top"> qui recharge la page index
    const closeBtn = page.locator('turbo-frame#event_modal a[data-turbo-frame="_top"][href="/evenements"]').first();
    if (await closeBtn.count() > 0) {
      await closeBtn.click();
      await page.waitForLoadState('networkidle');
      const urlAfterClose = page.url();
      log('6. Modal', 'Bouton × navigue vers /evenements (ferme modal)', /\/evenements$/.test(urlAfterClose), urlAfterClose);
    } else {
      log('6. Modal', 'Bouton × ferme la modal', false, 'lien close introuvable');
    }

    // Alternative : clic overlay = data-action click->modal#close
    await page.goto(BASE + '/evenements', { waitUntil: 'networkidle' });
    const firstCard2 = page.locator('a[data-debug-id^="event-card-"]').first();
    await firstCard2.click();
    await page.waitForTimeout(1200);
    const overlay = page.locator('turbo-frame#event_modal [data-controller="modal"]').first();
    if (await overlay.count() > 0) {
      const box = await overlay.boundingBox();
      if (box) {
        // Clic en haut à gauche de l'overlay (hors du panel qui est centré)
        await page.mouse.click(box.x + 20, box.y + 20);
        await page.waitForTimeout(600);
        const modalAfter = await page.locator('turbo-frame#event_modal').innerHTML().catch(() => '');
        log('6. Modal', 'Clic overlay ferme la modal', modalAfter.length < 500, `size=${modalAfter.length}`);
      }
    }
  }

  // Section 6b — Infinite scroll
  await page.goto(BASE + '/evenements', { waitUntil: 'networkidle' });
  const beforeScroll = await page.locator('[data-debug-id^="event-card-"]').count();
  await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
  await page.waitForTimeout(2500);
  const afterScroll = await page.locator('[data-debug-id^="event-card-"]').count();
  log('6b. Infinite scroll', 'Scroll fin de page charge plus d\'events', afterScroll > beforeScroll, `${beforeScroll} → ${afterScroll}`);

  // Section 7 — Page Professeur + clics "Voir site" / "Voir stats"
  const profLink = page.locator('a[href^="/professeurs/"]').first();
  if (await profLink.count() > 0) {
    const profHref = (await profLink.getAttribute('href')).split('?')[0];
    await page.goto(BASE + profHref, { waitUntil: 'networkidle' });
    const profName = await page.locator('h1, h2').first().innerText().catch(() => '');
    log('7. Prof', 'Page prof — nom dans h1/h2', profName.length > 0, profName);

    // Bouton "Voir le site web"
    const siteBtn = page.locator('a:has-text("site web"), a:has-text("Site web"), a[href*="redirect_to_site"]').first();
    if (await siteBtn.count() > 0) {
      const siteHref = await siteBtn.getAttribute('href');
      log('7. Prof', 'Bouton "Voir site web" présent', !!siteHref, siteHref);
    }

    // Bouton "Voir les statistiques publiques"
    const statsBtn = page.locator(`a[href="${profHref}/stats"]`).first();
    if (await statsBtn.count() > 0) {
      await Promise.all([
        page.waitForURL(/\/stats$/, { timeout: 5000 }).catch(() => {}),
        statsBtn.click()
      ]);
      log('7. Prof', 'Clic "Voir stats" → /stats', /\/stats$/.test(page.url()), page.url());

      // Section 8 — Stats
      const statsNum = await page.locator('.stat-value, [class*="stat"]').count();
      log('8. Stats', 'Compteurs stats affichés (DaisyUI)', statsNum > 0, `count=${statsNum}`);
    }
  }

  // Section 8b — Proposants (liste + recherche + modal)
  const propResp = await page.goto(BASE + '/proposants', { waitUntil: 'networkidle' });
  log('8b. Proposants', 'GET /proposants', propResp.status() === 200, `HTTP ${propResp.status()}`);

  const propCards = await page.locator('a[data-debug-id^="proposant-card-"]').count();
  log('8b. Proposants', 'Cartes proposants affichées', propCards > 0, `count=${propCards}`);

  const searchProp = page.locator('form input[name="q"]:visible').first();
  if (await searchProp.count() > 0) {
    await searchProp.fill('silvestre');
    await page.waitForTimeout(1200);
    const filtered = await page.locator('a[data-debug-id^="proposant-card-"]').count();
    log('8b. Proposants', 'Recherche "silvestre" filtre la liste', filtered > 0 && filtered < propCards, `${propCards} → ${filtered}`);
    await searchProp.fill('');
    await page.waitForTimeout(1200);
  } else {
    log('8b. Proposants', 'Champ recherche présent', false);
  }

  // Modal proposant
  const firstPropCard = page.locator('a[data-debug-id^="proposant-card-"]').first();
  if (await firstPropCard.count() > 0) {
    await firstPropCard.click();
    await page.waitForTimeout(1500);
    const modalContent = await page.locator('turbo-frame#proposant_modal').innerHTML().catch(() => '');
    log('8b. Proposants', 'Modal proposant remplie au clic', modalContent.length > 200, `size=${modalContent.length}`);

    // Clic overlay → ferme
    const propOverlay = page.locator('turbo-frame#proposant_modal [data-controller="modal"]').first();
    if (await propOverlay.count() > 0) {
      const box = await propOverlay.boundingBox();
      if (box) {
        await page.mouse.click(box.x + 20, box.y + 20);
        await page.waitForTimeout(600);
        const after = await page.locator('turbo-frame#proposant_modal').innerHTML().catch(() => '');
        log('8b. Proposants', 'Clic overlay ferme la modal proposant', after.length < 500, `size=${after.length}`);
      }
    }
  }

  // Section 9 — Footer : clics sur liens
  await page.goto(BASE + '/', { waitUntil: 'networkidle' });
  const footerLinks = await page.locator('footer a[href^="/"]').all();
  let tested = 0, ok = 0;
  for (const link of footerLinks.slice(0, 5)) {
    const href = await link.getAttribute('href');
    if (!href || href === '/') continue;
    const resp = await page.request.get(BASE + href).catch(() => null);
    if (resp && resp.status() === 200) ok++;
    tested++;
  }
  log('9. Footer', `Liens footer retournent 200`, tested > 0 && ok === tested, `${ok}/${tested}`);

  // Section 10 — SEO
  await page.goto(BASE + '/evenements', { waitUntil: 'networkidle' });
  const metaDesc = await page.locator('meta[name="description"]').getAttribute('content').catch(() => '');
  log('10. SEO', 'Meta description présente', (metaDesc || '').length > 20, `len=${(metaDesc||'').length}`);
  const h1Count = await page.locator('h1').count();
  log('10. SEO', 'Exactement 1 h1 sur /evenements', h1Count === 1, `count=${h1Count}`);

  const sitemapResp = await page.goto(BASE + '/sitemap.xml').catch(() => null);
  if (sitemapResp) {
    const body = await sitemapResp.text();
    log('10. SEO', '/sitemap.xml contient <url>', body.includes('<url>'), `size=${body.length}`);
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
