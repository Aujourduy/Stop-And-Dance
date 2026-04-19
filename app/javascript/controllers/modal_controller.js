import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  close() {
    this.element.remove()
    const path = window.location.pathname
    const collections = [ "/evenements", "/proposants" ]
    const base = collections.find(c => path.startsWith(c + "/"))
    if (base && path !== base + "/") {
      history.replaceState({}, "", base)
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
