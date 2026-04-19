import { Controller } from "@hotwired/stimulus"

// Affiche le bouton "up" après un scroll de 400px et remonte en smooth au clic
export default class extends Controller {
  static values = { threshold: { type: Number, default: 400 } }

  connect() {
    this.onScroll = this.onScroll.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  onScroll() {
    const visible = window.scrollY > this.thresholdValue
    this.element.classList.toggle("opacity-0", !visible)
    this.element.classList.toggle("pointer-events-none", !visible)
  }

  top(event) {
    event.preventDefault()
    window.scrollTo({ top: 0, behavior: "smooth" })
  }
}
