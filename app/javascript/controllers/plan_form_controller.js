import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="plan-form"
export default class extends Controller {
  static targets = ["photosSection"]

  connect() {
    this.togglePlanType()
  }

  togglePlanType() {
    const planTypeSelect = this.element.querySelector('select[name="plan[plan_type]"]')
    const isCustom = planTypeSelect.value === 'custom'
    
    if (this.hasPhotosSectionTarget) {
      this.photosSectionTarget.style.display = isCustom ? 'block' : 'none'
    }
  }
}