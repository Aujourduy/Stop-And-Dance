import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "panel"]

  connect() {
    // Listen for Esc key to close drawer
    this.escapeHandler = this.handleEscape.bind(this)
  }

  toggle() {
    const isHidden = this.overlayTarget.classList.contains("hidden")

    this.overlayTarget.classList.toggle("hidden")
    this.panelTarget.classList.toggle("hidden")

    // Update aria-hidden for accessibility
    this.panelTarget.setAttribute("aria-hidden", !isHidden)
    this.overlayTarget.setAttribute("aria-hidden", !isHidden)

    // Add/remove Esc key listener
    if (isHidden) {
      document.addEventListener("keydown", this.escapeHandler)
    } else {
      document.removeEventListener("keydown", this.escapeHandler)
    }
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    this.panelTarget.classList.add("hidden")

    // Update aria-hidden
    this.panelTarget.setAttribute("aria-hidden", "true")
    this.overlayTarget.setAttribute("aria-hidden", "true")

    // Remove Esc key listener
    document.removeEventListener("keydown", this.escapeHandler)
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  disconnect() {
    // Cleanup listener when controller is removed
    document.removeEventListener("keydown", this.escapeHandler)
  }
}
