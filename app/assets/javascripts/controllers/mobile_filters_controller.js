import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "panel"]

  open() {
    this.overlayTarget.classList.remove("hidden")
    this.panelTarget.classList.remove("hidden")
    // Prevent body scroll when overlay open
    document.body.style.overflow = "hidden"
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    this.panelTarget.classList.add("hidden")
    // Restore body scroll
    document.body.style.overflow = ""
  }
}
