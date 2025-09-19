import { Controller } from "@hotwired/stimulus"
import Sortable from 'sortablejs'

export default class extends Controller {
  static targets = ["container", "item"]

  connect() {
    console.log('Drag controller connected')
    
    if (this.hasContainerTarget) {
      this.containerTargets.forEach(container => {
        this.initializeSortable(container)
      })
    }
  }

  initializeSortable(container) {
    console.log('Initializing sortable for:', container)
    
    return new Sortable(container, {
      animation: 150,
      draggable: '[data-drag-target="item"]',
      handle: '.cursor-grab',
      delay: 100,
      delayOnTouchOnly: true,
      touchStartThreshold: 5,
      forceFallback: true,
      fallbackClass: 'opacity-50',
      onStart: (evt) => {
        console.log('Drag started')
        evt.item.classList.add('scale-105', 'shadow-lg', 'ring-2', 'ring-blue-400')
      },
      onEnd: (evt) => {
        console.log('Drag ended')
        evt.item.classList.remove('scale-105', 'shadow-lg', 'ring-2', 'ring-blue-400')
      }
    })
  }
}