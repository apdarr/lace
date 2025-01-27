import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "wrapper"]

  edit(event) {
    if (this.contentTarget.getAttribute("contenteditable") === "true") {
      this.wrapperTarget.classList.add('bg-green-50')
      this.contentTarget.focus()
    }
  }

  save(event) {
    if (this.contentTarget.getAttribute("contenteditable") === "true") {
      this.wrapperTarget.classList.remove('bg-green-50')
      const content = this.contentTarget.innerText
      const date = this.element.dataset.date
      console.log(`Saving content for ${date}: ${content}`)
    }
  }
}
