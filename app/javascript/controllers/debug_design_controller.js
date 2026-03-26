import { Controller } from "@hotwired/stimulus"

// Mode debug design activable par Ctrl+Shift+D
// Affiche les infos CSS au hover (balise, classes, couleurs, police, dimensions)
// Actif uniquement en development
export default class extends Controller {
  static targets = ["banner", "tooltip"]

  connect() {
    this.active = false
    this.currentElement = null

    this.handleKeydown = this.handleKeydown.bind(this)
    this.handleMouseMove = this.handleMouseMove.bind(this)
    this.handleMouseOut = this.handleMouseOut.bind(this)

    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
    this.deactivate()
  }

  handleKeydown(event) {
    // Ctrl+Shift+D pour toggle
    if (event.ctrlKey && event.shiftKey && event.key === "D") {
      event.preventDefault()
      this.toggle()
    }
  }

  toggle() {
    if (this.active) {
      this.deactivate()
    } else {
      this.activate()
    }
  }

  activate() {
    this.active = true
    this.bannerTarget.classList.remove("hidden")

    // Ajouter les listeners pour le hover
    document.addEventListener("mouseover", this.handleMouseMove)
    document.addEventListener("mouseout", this.handleMouseOut)
  }

  deactivate() {
    this.active = false
    this.bannerTarget.classList.add("hidden")
    this.tooltipTarget.classList.add("hidden")

    // Retirer l'outline de l'élément courant
    if (this.currentElement) {
      this.currentElement.style.outline = ""
      this.currentElement = null
    }

    // Retirer les listeners
    document.removeEventListener("mouseover", this.handleMouseMove)
    document.removeEventListener("mouseout", this.handleMouseOut)
  }

  handleMouseMove(event) {
    const target = event.target

    // Ignorer le bandeau et l'infobulle eux-mêmes
    if (target === this.bannerTarget || target === this.tooltipTarget ||
        this.bannerTarget.contains(target) || this.tooltipTarget.contains(target)) {
      return
    }

    // Retirer l'outline de l'ancien élément
    if (this.currentElement && this.currentElement !== target) {
      this.currentElement.style.outline = ""
    }

    // Ajouter outline à l'élément courant
    this.currentElement = target
    target.style.outline = "2px solid #C2623F"

    // Générer identifiant unique pour l'élément
    const uniqueId = this.getUniqueIdentifier(target)

    // Récupérer les styles calculés
    const styles = window.getComputedStyle(target)
    const tagName = target.tagName.toLowerCase()
    const elementId = target.id ? `#${target.id}` : ""
    const classes = target.className || "(no classes)"

    // Texte de l'élément (tronqué si trop long)
    let textContent = target.textContent?.trim() || ""
    if (textContent.length > 100) {
      textContent = textContent.substring(0, 100) + "..."
    }
    // Échapper les caractères HTML
    textContent = textContent.replace(/</g, "&lt;").replace(/>/g, "&gt;")

    // Couleurs
    const bgColor = this.rgbToHex(styles.backgroundColor)
    const textColor = this.rgbToHex(styles.color)

    // Dimensions
    const width = Math.round(target.offsetWidth)
    const height = Math.round(target.offsetHeight)

    // Police
    const fontFamily = styles.fontFamily.split(",")[0].replace(/"/g, "")
    const fontSize = styles.fontSize
    const fontWeight = styles.fontWeight

    // Padding & Margin
    const padding = `${styles.paddingTop} ${styles.paddingRight} ${styles.paddingBottom} ${styles.paddingLeft}`
    const margin = `${styles.marginTop} ${styles.marginRight} ${styles.marginBottom} ${styles.marginLeft}`

    // Construire le contenu de l'infobulle
    const textDisplay = textContent ? `<div class="bg-white bg-opacity-20 p-2 rounded text-xs italic border-l-4 border-gray-700">"${textContent}"</div>` : ""
    const selector = `${tagName}${elementId}${classes ? '.' + classes.split(' ').join('.') : ''}`

    const info = `
      <div class="text-sm space-y-2">
        <div class="bg-gray-800 text-white p-3 rounded font-mono text-base font-bold mb-3 break-all">${uniqueId}</div>
        <div class="text-xs text-gray-700 mb-2">Sélecteur CSS complet :</div>
        <div class="font-medium text-sm mb-2">${selector}</div>
        ${textDisplay}
        <div><strong>BG:</strong> ${bgColor}</div>
        <div><strong>Text:</strong> ${textColor}</div>
        <div><strong>Font:</strong> ${fontFamily}, ${fontSize}, ${fontWeight}</div>
        <div><strong>Padding:</strong> ${padding}</div>
        <div><strong>Margin:</strong> ${margin}</div>
        <div><strong>Size:</strong> ${width}px × ${height}px</div>
      </div>
    `

    this.tooltipTarget.innerHTML = info
    this.tooltipTarget.classList.remove("hidden")
  }

  handleMouseOut(event) {
    const target = event.target

    // Ignorer si on survole le bandeau ou l'infobulle
    if (target === this.bannerTarget || target === this.tooltipTarget ||
        this.bannerTarget.contains(target) || this.tooltipTarget.contains(target)) {
      return
    }

    // Retirer l'outline
    if (this.currentElement) {
      this.currentElement.style.outline = ""
      this.currentElement = null
    }

    // Cacher l'infobulle
    this.tooltipTarget.classList.add("hidden")
  }

  // Générer un identifiant unique pour l'élément
  getUniqueIdentifier(element) {
    // Priorité 1 : ID HTML
    if (element.id) {
      return `#${element.id}`
    }

    // Priorité 2 : data-debug-id
    if (element.dataset.debugId) {
      return `[data-debug-id="${element.dataset.debugId}"]`
    }

    // Priorité 3 : data-testid
    if (element.dataset.testid) {
      return `[data-testid="${element.dataset.testid}"]`
    }

    // Priorité 4 : Générer un sélecteur CSS unique
    return this.generateCssPath(element)
  }

  // Générer un chemin CSS unique pour l'élément
  generateCssPath(element) {
    if (element.tagName === 'HTML') return 'html'
    if (element.tagName === 'BODY') return 'body'

    let path = []
    let current = element

    while (current && current.tagName !== 'HTML') {
      let selector = current.tagName.toLowerCase()

      // Ajouter l'ID si présent
      if (current.id) {
        selector += `#${current.id}`
        path.unshift(selector)
        break // Un ID est unique, on peut s'arrêter
      }

      // Ajouter nth-child si nécessaire pour différencier les frères
      if (current.parentElement) {
        const siblings = Array.from(current.parentElement.children)
        const sameTagSiblings = siblings.filter(s => s.tagName === current.tagName)

        if (sameTagSiblings.length > 1) {
          const index = sameTagSiblings.indexOf(current) + 1
          selector += `:nth-of-type(${index})`
        }
      }

      path.unshift(selector)
      current = current.parentElement

      // Limiter la profondeur à 5 niveaux pour la lisibilité
      if (path.length >= 5) break
    }

    return path.join(' > ')
  }

  // Utilitaire pour convertir rgb() en hex
  rgbToHex(rgb) {
    if (!rgb || rgb === "rgba(0, 0, 0, 0)") return "transparent"

    const result = rgb.match(/\d+/g)
    if (!result) return rgb

    const [r, g, b] = result
    const hex = "#" + [r, g, b].map(x => {
      const hex = parseInt(x).toString(16)
      return hex.length === 1 ? "0" + hex : hex
    }).join("")

    return `${hex} (${rgb})`
  }
}
