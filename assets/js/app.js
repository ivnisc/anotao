// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {}

// función global para alternar entre modo texto y vista markdown
// usado desde el toggle de botones en el editor de notas
window.switchMode = function(mode) {
  const textArea = document.getElementById('nota-contenido');
  const preview = document.getElementById('markdown-preview');
  const textBtn = document.getElementById('text-mode');
  const previewBtn = document.getElementById('preview-mode');
  
  if (mode === 'text') {
    // mostrar textarea y ocultar preview
    textArea.classList.remove('hidden');
    preview.classList.add('hidden');
    
    // actualizar estilos de botones - texto activo
    textBtn.classList.add('bg-blue-500', 'text-white');
    textBtn.classList.remove('bg-gray-200', 'text-gray-700');
    previewBtn.classList.add('bg-gray-200', 'text-gray-700');
    previewBtn.classList.remove('bg-blue-500', 'text-white');
  } else {
    // modo preview - convertir markdown y mostrar resultado
    const content = textArea.value;
    
    // fallback: procesar markdown localmente con regex básicas
    // convierte sintaxis común de markdown a html
    const markdownText = content
      .replace(/^### (.*$)/gim, '<h3>$1</h3>')     // headers h3
      .replace(/^## (.*$)/gim, '<h2>$1</h2>')      // headers h2  
      .replace(/^# (.*$)/gim, '<h1>$1</h1>')       // headers h1
      .replace(/^\- (.*$)/gim, '<ul><li>$1</li></ul>') // listas
      .replace(/\*\*(.*?)\*\*/gim, '<strong>$1</strong>') // negrita
      .replace(/\*(.*?)\*/gim, '<em>$1</em>')      // cursiva
      .replace(/\n/gim, '<br>');                   // saltos de línea
    
    preview.innerHTML = markdownText;
    
    // mostrar preview y ocultar textarea
    textArea.classList.add('hidden');
    preview.classList.remove('hidden');
    
    // actualizar estilos de botones - preview activo
    previewBtn.classList.add('bg-blue-500', 'text-white');
    previewBtn.classList.remove('bg-gray-200', 'text-gray-700');
    textBtn.classList.add('bg-gray-200', 'text-gray-700');
    textBtn.classList.remove('bg-blue-500', 'text-white');
  }
}

// configuración del socket de liveview
// token csrf requerido para todas las comunicaciones con el servidor
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,           // fallback a long polling después de 2.5s
  params: {_csrf_token: csrfToken}    // token de seguridad en todos los requests
})

// barra de progreso para navegación liveview
// se muestra solo si la carga toma más de 120ms
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// conectar liveview si hay componentes en la página
liveSocket.connect()

// exponer socket en window para debugging en consola
// útil para habilitar logs o simular latencia en desarrollo
window.liveSocket = liveSocket

