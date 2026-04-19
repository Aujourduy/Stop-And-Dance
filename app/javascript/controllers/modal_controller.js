import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  close() {
    this.element.remove()
    if (window.location.pathname.startsWith("/evenements/") && window.location.pathname !== "/evenements/") {
      history.replaceState({}, "", "/evenements")
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
