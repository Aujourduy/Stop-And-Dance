import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  close() {
    // Trigger mobile-filters controller close method
    const mobileFiltersController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="mobile-filters"]'),
      "mobile-filters"
    )
    mobileFiltersController?.close()
  }
}
