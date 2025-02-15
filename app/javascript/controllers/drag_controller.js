import { Controller } from "@hotwired/stimulus"
import Sortable from 'sortablejs'

export default class extends Controller {
  static targets = ["container", "item"]

  connect() {
    if (!this.hasContainerTarget) return
    
    this.sortableInstances = []
    this.containerTargets.forEach(container => {
      this.sortableInstances.push(this.initializeSortable(container))
    })
  }

  initializeSortable(container) {
    return new Sortable(container, {
      animation: 150,
      draggable: "[data-drag-target='item']",
      handle: ".activity-content",
      group: {
        name: 'shared',
        pull: true,
        put: (to) => to.el.children.length < 7
      },
      onStart: (evt) => {
        evt.item.classList.add('scale-105', 'shadow-lg', 'bg-green-100', 'border-2', 'border-green-400')
      },
      onEnd: (evt) => {
        evt.item.classList.remove('scale-105', 'shadow-lg', 'bg-green-100', 'border-2', 'border-green-400')
        if (evt.to.children.length > 7) {
          evt.from.appendChild(evt.item)
          return
        }
        this.handleDragEnd(evt)
      }
    })
  }

  handleDragEnd(event) {
    const itemDate = event.item.dataset.date
    const newIndex = event.newIndex
    const weekContainer = event.to
    
    console.log(`Item from ${itemDate} moved to position ${newIndex} in week ${weekContainer.dataset.week}`)
  }
}