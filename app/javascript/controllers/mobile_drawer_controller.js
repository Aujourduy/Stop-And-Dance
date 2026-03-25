import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "panel"]

  toggle() {
    this.overlayTarget.classList.toggle("hidden")
    this.panelTarget.classList.toggle("hidden")
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    this.panelTarget.classList.add("hidden")
  }
}
