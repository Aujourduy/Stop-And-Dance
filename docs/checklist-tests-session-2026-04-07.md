# Checklist Tests — Session 2026-04-05 → 2026-04-07

Cocher chaque item après validation manuelle sur téléphone et/ou desktop.

**MAJ 2026-04-19 :** Items automatisables cochés par `script/ux-audit.js` (Playwright headless, 37/37 ✅). Les items nécessitant interaction humaine (zoom pinch, gestures, rendu visuel fin) restent à cocher manuellement.

---

## 1. Mobile — Affichage général

- [x] Pas de scroll horizontal sur la page d'accueil *(Playwright 2026-04-19)*
- [x] Pas de scroll horizontal sur la page agenda (/evenements) *(Playwright 2026-04-19)*
- [x] Pas de scroll horizontal sur /a-propos *(Playwright 2026-04-19)*
- [x] Pas de scroll horizontal sur /contact *(Playwright 2026-04-19)*
- [x] Pas de scroll horizontal sur /proposants *(Playwright 2026-04-19)*
- [ ] Le zoom pinch est bien désactivé (pas de zoom possible)

## 2. Mobile — Navigation

- [x] Menu burger s'ouvre correctement *(Playwright 2026-04-19)*
- [x] Menu burger contient : Accueil, Agenda, Newsletter, Proposants *(Playwright 2026-04-19 — "Liens"/"Admin" non testés)*
- [ ] Lien "Agenda" dans le burger mène bien à /evenements
- [ ] Lien "Admin" dans le burger mène bien à /admin (popup login)
- [ ] Fermeture du burger (bouton × ou clic overlay)

## 3. Page d'accueil

- [x] Hero affiché (titre "Stop & Dance") *(Playwright 2026-04-19 — couleur terracotta non vérifiée)*
- [ ] 6 boutons DaisyUI affichés en grille (AGENDA, PUBLIER ATELIERS, etc.)
- [x] Bouton AGENDA mène à /evenements *(Playwright 2026-04-19)*
- [ ] Footer : 3 colonnes (Navigation, Légal, Newsletter)
- [x] Formulaire newsletter visible dans le footer *(Playwright 2026-04-19)*

## 4. Page Agenda (/evenements)

- [x] Titre "Agenda complet : Ateliers (X) et Stages (Y)" affiché *(Playwright 2026-04-19)*
- [x] Jours en français capitalisés (ex: Dimanche 5 Avril 2026) *(Playwright 2026-04-19)*
- [ ] Cartes événements pleine largeur sur mobile (bord à bord)
- [x] Badges DaisyUI : "Atelier" (pas Workshop), "Présentiel" *(Playwright 2026-04-19)*
- [ ] Prix réduit au format compact : 20,00€/16,00€
- [ ] Prix "Gratuit" en vert *(texte "Gratuit" détecté, couleur verte non vérifiée)*
- [x] Infinite scroll fonctionne (30 → 60 events au scroll bas de page) *(Playwright 2026-04-19)*
- [ ] Bouton "Filtrez l'agenda" visible en bas à droite sur mobile

## 5. Filtres agenda

- [ ] Ouvrir panneau filtres (bouton "Filtrez l'agenda" sur mobile)
- [x] Champ "Recherche" visible *(Playwright 2026-04-19 — desktop)*
- [x] Taper "paris" → résultats *(Playwright 2026-04-19)*
- [x] Taper "xxxxyyyzzzz" → 0 résultats *(Playwright 2026-04-19)*
- [x] Effacer le champ → retour à tous les events *(Playwright 2026-04-19)*
- [ ] Taper "marc rennes" → filtre AND (events avec marc ET rennes)
- [ ] Checkbox "Gratuit" filtre correctement
- [ ] Checkbox "Stage" filtre correctement
- [ ] Checkbox "En ligne" filtre correctement
- [ ] Date picker filtre correctement
- [ ] Champ "Lieu" filtre correctement
- [ ] Fermer le panneau filtres (bouton × sur mobile)

## 6. Modal événement

- [x] Cliquer sur une carte événement ouvre la modal *(Playwright 2026-04-19 — turbo-frame#event_modal rempli)*
- [x] Modal affiche le titre *(Playwright 2026-04-19 — autres champs non vérifiés)*
- [ ] Bouton fermeture (×) fonctionne
- [ ] Description affichée
- [ ] Tags/Pratiques affichés si présents
- [ ] Lien "Voir le site du prof" si disponible

## 7. Page Professeur (/professeurs/:id)

- [ ] Avatar ou placeholder avec initiale affiché
- [ ] Nom du professeur affiché
- [ ] Bio affichée
- [ ] Bouton "Voir le site web" si disponible
- [ ] Bouton "Voir les statistiques publiques"
- [ ] Liste "Prochains ateliers et stages" affichée

## 8. Page Stats Professeur (/professeurs/:id/stats)

- [ ] Compteurs affichés (consultations + clics sortants)
- [ ] Design DaisyUI stats
- [ ] Section "À propos de ces statistiques" (alert info)
- [ ] Champ "Partager ce lien" avec bouton Copier

## 9. Newsletter

- [ ] Formulaire newsletter dans la sidebar desktop (page agenda)
- [ ] Formulaire newsletter dans le footer
- [ ] Soumettre email valide → message succès
- [ ] Soumettre email déjà inscrit → message "déjà inscrite"
- [ ] Soumettre email invalide → message erreur

## 10. Design DaisyUI — Cohérence visuelle

- [ ] Couleurs terracotta (boutons, liens, titres) cohérentes partout
- [ ] Fond beige sur toutes les pages
- [ ] Navbar/footer fond noir sur mobile et desktop
- [ ] Badges arrondis avec couleurs distinctes
- [ ] Inputs/checkboxes avec style DaisyUI dans les filtres
- [ ] Flash messages avec style alert DaisyUI

## 11. Desktop

- [ ] Navbar desktop visible (cachée sur mobile)
- [ ] Sidebar filtres visible à droite sur la page agenda
- [ ] Cartes événements avec coins arrondis
- [ ] Footer 3 colonnes bien alignées
- [ ] Page professeur : layout horizontal (avatar à gauche, bio à droite)

## 12. Admin

- [ ] /admin accessible avec login HTTP Basic (admin / change_me_in_production)
- [ ] Dashboard ScrapedUrls affiché
- [ ] Page détails URL : bouton "Crawler le site" visible (violet)
- [ ] Page détails URL : dropdown modèle LLM fonctionnel
- [ ] /admin/site_crawls : liste des crawls affichée
- [ ] /admin/site_crawls/:id : détail pages crawlées avec verdicts ✅/❌/⚠️
- [ ] /admin/settings : champ "Modèle OpenRouter par défaut" visible
- [ ] /admin/professors : liste avec filtres Tous / À vérifier

## 13. Crawler de sites (branche exploration-site-prof)

⚠️ **Prérequis :** être sur la branche `exploration-site-prof` (`git checkout exploration-site-prof`)

- [ ] Clé API OpenRouter configurée dans `.env` (`OPENROUTER_API_KEY=...`)
- [ ] Serveur redémarré après ajout de la clé
- [ ] Lancer crawl depuis /admin/scraped_urls/:id → bouton "Crawler le site"
- [ ] Le crawl passe en statut "running" puis "completed"
- [ ] /admin/site_crawls/:id affiche les pages trouvées
- [ ] Pages classées ✅ (oui) correspondent à des pages avec ateliers/dates
- [ ] Pages classées ❌ (non) correspondent à des pages sans ateliers (contact, about, PDFs)
- [ ] Des ScrapedUrl ont été auto-créées pour les pages ✅
- [ ] Les ScrapedUrl auto-créées ont hérité le(s) professor(s) de l'URL racine
- [ ] Les ScrapedUrl auto-créées ont hérité le flag `use_browser` de l'URL racine
- [ ] Limite 100 pages max respectée
- [ ] Pas de pages hors domaine crawlées
- [ ] Logs dans `log/scraping.log` (events site_crawl_started, site_crawl_completed)

### Test crawl site réel

- [ ] **Wilberforce** (https://www.bodyvoiceandbeing.com/) : ~25 pages, ~14 OUI attendus
- [ ] **Silvestre** (https://www.marcsilvestre.com/agenda-cours-stages-1) : ~12 pages, ~6 OUI attendus
- [ ] Page JS-only détectée automatiquement (texte visible < 500 chars → fallback Playwright)
- [ ] Rate limit OpenRouter géré (retry sans crash)

### Re-crawl automatique

- [ ] Activer `auto_recrawl` sur une ScrapedUrl (console : `ScrapedUrl.find(X).update!(auto_recrawl: true)`)
- [ ] `SiteCrawlDispatchJob.perform_now` → vérifie hash racine → enqueue ou skip

---

**Date :** 2026-04-07
**Validé par :** _______________
