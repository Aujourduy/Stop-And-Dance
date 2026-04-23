import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

// Cropper d'avatar pour les forms admin (Professor + ScrapedUrl).
//
// Usage dans ERB :
//   <div data-controller="avatar-cropper"
//        data-avatar-cropper-output-name-value="professor[photo]"
//        data-avatar-cropper-size-value="300">
//     <input type="file" data-avatar-cropper-target="input" accept="image/*" />
//     <div data-avatar-cropper-target="container" class="hidden"></div>
//     <canvas data-avatar-cropper-target="preview"></canvas>
//   </div>
//
// Au submit, on substitue le fichier original par un blob PNG carré cropé.
export default class extends Controller {
  static targets = ["input", "container", "preview"]
  static values = {
    outputName: String, // nom du champ file pour remplacer au submit
    size: { type: Number, default: 300 }
  }

  connect() {
    this.cropper = null
    this.croppedBlob = null

    // Intercepter le submit du form englobant pour substituer le fichier
    this.form = this.element.closest("form")
    if (this.form) {
      this.submitHandler = this.handleSubmit.bind(this)
      this.form.addEventListener("submit", this.submitHandler)
    }
  }

  disconnect() {
    if (this.form && this.submitHandler) {
      this.form.removeEventListener("submit", this.submitHandler)
    }
    this.destroyCropper()
  }

  // Appelé sur change du <input type="file">
  fileSelected(event) {
    const file = event.target.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => this.initCropper(e.target.result)
    reader.readAsDataURL(file)
  }

  initCropper(dataUrl) {
    this.destroyCropper()

    // Créer la UI cropper : barre d'actions + canvas avec image + sélection carrée
    this.containerTarget.classList.remove("hidden")
    this.containerTarget.innerHTML = `
      <div class="flex flex-wrap gap-2 p-2 bg-base-200 border-b">
        <button type="button" data-action="mirror-h" class="btn btn-sm btn-ghost" title="Miroir horizontal">↔</button>
        <button type="button" data-action="mirror-v" class="btn btn-sm btn-ghost" title="Miroir vertical">↕</button>
        <button type="button" data-action="rotate-left" class="btn btn-sm btn-ghost" title="Rotation 90° gauche">↺</button>
        <button type="button" data-action="rotate-right" class="btn btn-sm btn-ghost" title="Rotation 90° droite">↻</button>
        <button type="button" data-action="reset" class="btn btn-sm btn-ghost" title="Réinitialiser">⟲ reset</button>
      </div>
      <cropper-canvas background style="width: 100%; height: 400px;">
        <cropper-image src="${dataUrl}" alt="À cropper" rotatable scalable skewable translatable></cropper-image>
        <cropper-shade hidden></cropper-shade>
        <cropper-handle action="select" plain></cropper-handle>
        <cropper-selection initial-coverage="0.6" movable resizable aspect-ratio="1">
          <cropper-grid role="grid" bordered covered></cropper-grid>
          <cropper-crosshair centered></cropper-crosshair>
          <cropper-handle action="move" theme-color="rgba(255, 255, 255, 0.35)"></cropper-handle>
          <cropper-handle action="n-resize"></cropper-handle>
          <cropper-handle action="e-resize"></cropper-handle>
          <cropper-handle action="s-resize"></cropper-handle>
          <cropper-handle action="w-resize"></cropper-handle>
          <cropper-handle action="ne-resize"></cropper-handle>
          <cropper-handle action="nw-resize"></cropper-handle>
          <cropper-handle action="se-resize"></cropper-handle>
          <cropper-handle action="sw-resize"></cropper-handle>
        </cropper-selection>
      </cropper-canvas>
    `

    const cropperImage = this.containerTarget.querySelector("cropper-image")
    const selection = this.containerTarget.querySelector("cropper-selection")

    // Boutons de transformation (scale = scale relatif : -1 inverse)
    this.containerTarget.querySelectorAll("button[data-action]").forEach((btn) => {
      btn.addEventListener("click", () => {
        const action = btn.getAttribute("data-action")
        switch (action) {
          case "mirror-h": cropperImage.$scale(-1, 1); break
          case "mirror-v": cropperImage.$scale(1, -1); break
          case "rotate-left": cropperImage.$rotate("-90deg"); break
          case "rotate-right": cropperImage.$rotate("90deg"); break
          case "reset": cropperImage.$resetTransform(); cropperImage.$center("contain"); break
        }
        // Refresh preview après transform
        setTimeout(() => this.updatePreview(), 100)
      })
    })

    // Live preview
    this.updatePreview = this.debounce(async () => {
      try {
        const canvas = await selection.$toCanvas({
          width: this.sizeValue,
          height: this.sizeValue
        })
        const ctx = this.previewTarget.getContext("2d")
        this.previewTarget.width = this.sizeValue
        this.previewTarget.height = this.sizeValue
        ctx.drawImage(canvas, 0, 0)
      } catch (e) {
        console.warn("preview error", e)
      }
    }, 100)

    selection.addEventListener("change", () => this.updatePreview())
    // Première preview après load
    setTimeout(() => this.updatePreview(), 300)
  }

  // Au submit du form : génère le blob carré et remplace le fichier.
  // On intercepte le submit, on fait le crop async (toBlob → DataTransfer),
  // puis on re-submit avec requestSubmit() pour conserver le flow natif
  // (CSRF token, validators, Turbo Drive si activé, etc.).
  async handleSubmit(event) {
    // Si on a déjà généré le blob cropé, laisser passer ce submit-là
    if (this._croppedReady) {
      this._croppedReady = false
      return
    }
    const selection = this.containerTarget.querySelector("cropper-selection")
    if (!selection) return // Pas de cropper actif, laisser passer

    event.preventDefault() // on va resubmit après génération async

    try {
      const canvas = await selection.$toCanvas({
        width: this.sizeValue,
        height: this.sizeValue
      })
      canvas.toBlob((blob) => {
        if (blob) {
          // Substituer le fichier dans le FormData
          const file = new File([blob], "cropped.png", { type: "image/png" })
          const dt = new DataTransfer()
          dt.items.add(file)
          this.inputTarget.files = dt.files
        }
        this._croppedReady = true
        this.form.requestSubmit()
      }, "image/png")
    } catch (e) {
      console.error("crop error", e)
      this._croppedReady = true
      this.form.requestSubmit()
    }
  }

  destroyCropper() {
    if (this.containerTarget) {
      this.containerTarget.innerHTML = ""
      this.containerTarget.classList.add("hidden")
    }
  }

  debounce(fn, ms) {
    let t
    return (...args) => {
      clearTimeout(t)
      t = setTimeout(() => fn(...args), ms)
    }
  }
}
