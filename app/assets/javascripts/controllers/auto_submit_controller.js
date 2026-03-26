import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Auto-submit form when checkboxes change
    this.element.querySelectorAll('input[type="checkbox"]').forEach(checkbox => {
      checkbox.addEventListener('change', () => {
        this.element.requestSubmit()
      })
    })

    // Auto-submit form when date changes
    this.element.querySelector('input[type="date"]')?.addEventListener('change', () => {
      this.element.requestSubmit()
    })
  }
}
