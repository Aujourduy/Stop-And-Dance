import { Controller } from "@hotwired/stimulus"

// Mode debug design activable par Ctrl+Shift+D
// Affiche les infos CSS au hover (balise, classes, couleurs, police, dimensions)
// Actif uniquement en development
export default class extends Controller {
  static targets = ["banner", "tooltip"]

  connect() {
    this.active = false
    this.currentElement = null
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    this.boundHandleMouseMove = this.handleMouseMove.bind(this)
    this.boundHandleMouseOut = this.handleMouseOut.bind(this)

    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
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
    document.addEventListener("mouseover", this.boundHandleMouseMove)
    document.addEventListener("mouseout", this.boundHandleMouseOut)

    console.log("Debug Design Mode: ACTIVATED")
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
    document.removeEventListener("mouseover", this.boundHandleMouseMove)
    document.removeEventListener("mouseout", this.boundHandleMouseOut)

    console.log("Debug Design Mode: DEACTIVATED")
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

    // Récupérer les styles calculés
    const styles = window.getComputedStyle(target)
    const tagName = target.tagName.toLowerCase()
    const classes = target.className || "(no classes)"

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
    const info = `
      <div class="text-xs space-y-1">
        <div class="font-bold text-terracotta">${tagName}.${classes}</div>
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

    // Positionner l'infobulle près du curseur
    this.tooltipTarget.style.left = `${event.pageX + 15}px`
    this.tooltipTarget.style.top = `${event.pageY + 15}px`
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
