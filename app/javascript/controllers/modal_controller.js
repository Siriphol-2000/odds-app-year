import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  show(event) {
    const dialog = document.getElementById(event.params.dialog);
    dialog.showModal();
  }

  close() {
    const dialog = this.element;
    dialog.close();
  }
}