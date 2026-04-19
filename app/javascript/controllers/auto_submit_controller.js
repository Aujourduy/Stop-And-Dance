import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { debounce: { type: Number, default: 0 } }

  submit(event) {
    const delay = this.debounceValue || (event?.type === "input" ? 300 : 0)

    clearTimeout(this.timer)
    this.timer = setTimeout(() => {
      this.element.requestSubmit()
    }, delay)
  }
}
