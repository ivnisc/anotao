defmodule AnotaoWeb.Notas.IndexLive do
  use AnotaoWeb, :live_view

  alias Anotao.Notas
  alias Anotao.Utils.Rut

  @impl true
  def mount(%{"rut_usuario" => rut_usuario}, _session, socket) do
    # validar que el RUT sea válido
    unless Rut.is_valid?(rut_usuario) do
      raise Phoenix.Router.NoRouteError,
        conn: %Plug.Conn{},
        router: AnotaoWeb.Router
    end

    notas = Notas.list_notas_by_usuario(rut_usuario)

    # verificar que el usuario existe en la db (tiene al menos una nota)
    # solo usuarios que han usado el landing page tienen acceso
    if length(notas) == 0 do
      raise Phoenix.Router.NoRouteError,
        conn: %Plug.Conn{},
        router: AnotaoWeb.Router
    end

    {:ok,
     socket
     |> assign(:rut_usuario, rut_usuario)
     |> assign(:notas, notas)
     |> assign(:page_title, "Mis Notas")
     |> assign(:show_settings, false)
     |> assign(:show_confirm_delete, false)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Mis Notas")
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Nueva Nota")
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    nota = Notas.get_nota_by_slug!(socket.assigns.rut_usuario, id)
    {:ok, _} = Notas.delete_nota(nota)

    notas = Notas.list_notas_by_usuario(socket.assigns.rut_usuario)
    {:noreply, assign(socket, :notas, notas)}
  end

  def handle_event("toggle_settings", _params, socket) do
    {:noreply, assign(socket, :show_settings, !socket.assigns.show_settings)}
  end

  def handle_event("show_delete_confirm", _params, socket) do
    {:noreply, assign(socket, :show_confirm_delete, true)}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, :show_confirm_delete, false)}
  end

  def handle_event("delete_all_data", _params, socket) do
    # eliminar todas las notas del usuario
    socket.assigns.notas
    |> Enum.each(&Notas.delete_nota/1)

    {:noreply,
     socket
     |> assign(:notas, [])
     |> assign(:show_confirm_delete, false)
     |> assign(:show_settings, false)
     |> put_flash(:info, "Todos los datos han sido eliminados correctamente")
     |> push_navigate(to: "/")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl p-6">
      <div class="flex justify-between items-center mb-6">
        <div class="flex items-center gap-4">
          <h1 class="text-2xl font-bold">Notas</h1>
          <div class="relative">
            <button
              phx-click="toggle_settings"
              class="p-2 text-gray-400 hover:text-gray-600 transition-colors"
              title="Configuración"
            >
              <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path
                  fill-rule="evenodd"
                  d="M11.49 3.17c-.38-1.56-2.6-1.56-2.98 0a1.532 1.532 0 01-2.286.948c-1.372-.836-2.942.734-2.106 2.106.54.886.061 2.042-.947 2.287-1.561.379-1.561 2.6 0 2.978a1.532 1.532 0 01.947 2.287c-.836 1.372.734 2.942 2.106 2.106a1.532 1.532 0 012.287.947c.379 1.561 2.6 1.561 2.978 0a1.533 1.533 0 012.287-.947c1.372.836 2.942-.734 2.106-2.106a1.533 1.533 0 01.947-2.287c1.561-.379 1.561-2.6 0-2.978a1.532 1.532 0 01-.947-2.287c.836-1.372-.734-2.942-2.106-2.106a1.532 1.532 0 01-2.287-.947zM10 13a3 3 0 100-6 3 3 0 000 6z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>

            <div
              :if={@show_settings}
              class="absolute left-full top-0 ml-2 w-56 bg-white rounded-md shadow-lg border border-gray-200 z-10"
            >
              <button
                phx-click="show_delete_confirm"
                class="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 rounded-md"
              >
                Eliminar todos los datos
              </button>
            </div>
          </div>
        </div>
        <.link
          patch={~p"/#{@rut_usuario}/new"}
          class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
        >
          Nueva Nota
        </.link>
      </div>

      <div :if={@notas == []} class="text-center py-8">
        <p class="text-gray-500">No hay notas creadas</p>
        <.link patch={~p"/#{@rut_usuario}/new"} class="text-blue-500 hover:underline">
          Crear primera nota
        </.link>
      </div>

      <div class="grid gap-4">
        <div
          :for={nota <- @notas}
          class="border rounded-lg p-4 bg-white shadow hover:shadow-md transition-shadow"
        >
          <div class="flex justify-between items-start">
            <div class="flex-1">
              <h3 class="text-lg font-semibold mb-2">
                <.link
                  navigate={~p"/#{@rut_usuario}/#{nota.slug}"}
                  class="text-blue-600 hover:text-blue-800"
                >
                  {nota.titulo}
                </.link>
              </h3>
              <p class="text-gray-600 text-sm line-clamp-3">
                {String.slice(nota.contenido, 0, 150)}{if String.length(nota.contenido) > 150,
                  do: "..."}
              </p>
              <p class="text-xs text-gray-400 mt-2">
                Actualizada: {nota.updated_at
                |> DateTime.shift_zone!("America/Santiago")
                |> Calendar.strftime("%d/%m/%Y %H:%M")}
              </p>
            </div>
            <div class="flex gap-2 ml-4">
              <.link
                navigate={~p"/#{@rut_usuario}/#{nota.slug}/edit"}
                class="text-sm text-gray-500 hover:text-gray-700"
              >
                Editar
              </.link>
              <button
                phx-click="delete"
                phx-value-id={nota.slug}
                data-confirm="¿Eliminar esta nota?"
                class="text-sm text-red-500 hover:text-red-700"
              >
                Eliminar
              </button>
            </div>
          </div>
        </div>
      </div>
      
    <!-- modal de confirmación -->
      <div
        :if={@show_confirm_delete}
        class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50"
      >
        <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
          <div class="mt-3 text-center">
            <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100 mb-4">
              <svg class="h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L4.268 16.5c-.77.833.192 2.5 1.732 2.5z"
                />
              </svg>
            </div>
            <h3 class="text-lg font-medium text-gray-900">
              ¿Eliminar todos los datos?
            </h3>
            <div class="mt-2 px-7 py-3">
              <p class="text-sm text-gray-500">
                Esta acción eliminará permanentemente todas tus notas ({length(@notas)} notas).
                No podrás recuperar esta información.
              </p>
            </div>
            <div class="flex gap-4 px-4 py-3">
              <button
                phx-click="cancel_delete"
                class="flex-1 px-4 py-2 bg-gray-300 text-gray-800 text-base font-medium rounded-md shadow-sm hover:bg-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-300"
              >
                Cancelar
              </button>
              <button
                phx-click="delete_all_data"
                class="flex-1 px-4 py-2 bg-red-600 text-white text-base font-medium rounded-md shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500"
              >
                Eliminar todo
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
