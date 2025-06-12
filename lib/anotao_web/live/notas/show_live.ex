defmodule AnotaoWeb.Notas.ShowLive do
  use AnotaoWeb, :live_view

  alias Anotao.Notas
  alias Anotao.Notas.Nota
  alias Anotao.Utils.Rut

  @impl true
  def mount(%{"rut_usuario" => rut_usuario} = params, _session, socket) do
    # validar que el RUT sea válido
    unless Rut.is_valid?(rut_usuario) do
      raise Phoenix.Router.NoRouteError,
        conn: %Plug.Conn{},
        router: AnotaoWeb.Router
    end

    notas = Notas.list_notas_by_usuario(rut_usuario)

    case Map.get(params, "slug") do
      nil ->
        # nueva nota - verificar que el usuario existe en la db
        if length(notas) == 0 do
          raise Phoenix.Router.NoRouteError,
            conn: %Plug.Conn{},
            router: AnotaoWeb.Router
        end

        nota = %Nota{titulo: "", contenido: "", rut_usuario: rut_usuario}

        {:ok,
         socket
         |> assign(:rut_usuario, rut_usuario)
         |> assign(:slug, nil)
         |> assign(:nota, nota)
         |> assign(:changeset, Notas.change_nota(nota))
         |> assign(:editing, true)
         |> assign(:saving, false)}

      slug ->
        # nota existente - verificar que el usuario existe en la db
        if length(notas) == 0 do
          raise Phoenix.Router.NoRouteError,
            conn: %Plug.Conn{},
            router: AnotaoWeb.Router
        end

        nota =
          case Notas.get_nota_by_slug!(rut_usuario, slug) do
            nil -> %Nota{titulo: "", contenido: "", rut_usuario: rut_usuario}
            nota -> nota
          end

        {:ok,
         socket
         |> assign(:rut_usuario, rut_usuario)
         |> assign(:slug, slug)
         |> assign(:nota, nota)
         |> assign(:changeset, Notas.change_nota(nota))
         |> assign(:editing, false)
         |> assign(:saving, false)}
    end
  rescue
    Ecto.NoResultsError ->
      # nota no encontrada
      nota = %Nota{titulo: "", contenido: "", rut_usuario: rut_usuario}

      {:ok,
       socket
       |> assign(:rut_usuario, rut_usuario)
       |> assign(:slug, Map.get(params, "slug"))
       |> assign(:nota, nota)
       |> assign(:changeset, Notas.change_nota(nota))
       |> assign(:editing, true)
       |> assign(:saving, false)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, socket.assigns.nota.titulo)
    |> assign(:editing, false)
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, "Editando: #{socket.assigns.nota.titulo}")
    |> assign(:editing, true)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Nueva Nota")
    |> assign(:editing, true)
  end

  @impl true
  def handle_event("edit", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing, true)
     |> push_patch(to: ~p"/#{socket.assigns.rut_usuario}/#{socket.assigns.slug}/edit")}
  end

  def handle_event("cancel", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing, false)
     |> assign(:changeset, Notas.change_nota(socket.assigns.nota))}
  end

  def handle_event("validate", %{"nota" => nota_params}, socket) do
    changeset =
      socket.assigns.nota
      |> Notas.change_nota(nota_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"nota" => nota_params}, socket) do
    IO.inspect(nota_params, label: "NOTA PARAMS")
    IO.inspect(socket.assigns.live_action, label: "LIVE ACTION")
    save_nota(socket, socket.assigns.live_action, nota_params)
  end

  # autosave cada 2 segundos mientras escribe
  def handle_event("autosave", %{"nota" => nota_params}, socket) do
    if socket.assigns.nota.id do
      case Notas.update_nota(socket.assigns.nota, nota_params) do
        {:ok, nota} ->
          {:noreply,
           socket
           |> assign(:nota, nota)
           |> assign(:saving, false)}

        {:error, changeset} ->
          {:noreply, assign(socket, :changeset, changeset)}
      end
    else
      {:noreply, socket}
    end
  end

  defp save_nota(socket, :edit, nota_params) do
    IO.inspect(socket.assigns.nota, label: "NOTA ORIGINAL")

    case Notas.update_nota(socket.assigns.nota, nota_params) do
      {:ok, nota} ->
        IO.inspect(nota, label: "NOTA ACTUALIZADA")

        {:noreply,
         socket
         |> assign(:nota, nota)
         |> assign(:editing, false)
         |> assign(:changeset, Notas.change_nota(nota))
         |> put_flash(:info, "Nota actualizada correctamente")}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset, label: "ERROR CHANGESET")
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_nota(socket, :new, nota_params) do
    case Notas.create_nota(nota_params) do
      {:ok, nota} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/#{socket.assigns.rut_usuario}/#{nota.slug}")
         |> put_flash(:info, "Nota creada correctamente")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  # helper para obtener valor del changeset
  defp input_value(changeset, field) do
    Ecto.Changeset.get_field(changeset, field) || ""
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl p-6">
      <!-- header con navegación -->
      <div class="flex justify-between items-center mb-6">
        <.link navigate={~p"/#{@rut_usuario}"} class="text-blue-500 hover:text-blue-700">
          ← Volver a mis notas
        </.link>

        <div :if={not @editing and @nota.id} class="flex gap-2">
          <button
            phx-click="edit"
            class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          >
            Editar
          </button>
        </div>
      </div>
      
    <!-- modo visualización -->
      <div :if={not @editing and @nota.id} class="max-w-none">
        <h1 class="text-3xl font-bold mb-4">{@nota.titulo}</h1>
        <div class="markdown-content">
          {raw(Earmark.as_html!(@nota.contenido))}
          <style>
            .markdown-content h1 { font-size: 2rem; font-weight: bold; margin: 1rem 0; }
            .markdown-content h2 { font-size: 1.5rem; font-weight: bold; margin: 1rem 0; }
            .markdown-content h3 { font-size: 1.25rem; font-weight: bold; margin: 1rem 0; }
            .markdown-content ul { margin: 0.5rem 0; padding-left: 1.5rem; }
            .markdown-content li { list-style-type: disc; margin: 0.25rem 0; }
            .markdown-content strong { font-weight: bold; }
            .markdown-content em { font-style: italic; }
            .markdown-content p { margin: 0.5rem 0; line-height: 1.6; }
          </style>
        </div>
        <p class="text-sm text-gray-400 mt-8">
          Última actualización: {@nota.updated_at
          |> DateTime.shift_zone!("America/Santiago")
          |> Calendar.strftime("%d/%m/%Y %H:%M")}
        </p>
      </div>
      
    <!-- modo edición -->
      <div :if={@editing}>
        <.form for={@changeset} phx-change="validate" phx-submit="save" class="space-y-6">
          <div>
            <label class="block text-sm font-semibold leading-6 text-zinc-800">
              Título
            </label>
            <input
              type="text"
              name="nota[titulo]"
              value={input_value(@changeset, :titulo)}
              placeholder="Título de la nota"
              maxlength="50"
              class="w-full text-2xl font-bold border-0 border-b-2 border-gray-200 focus:border-blue-500 bg-transparent"
            />
          </div>

          <div>
            <div class="flex justify-between items-center mb-2">
              <label class="block text-sm font-semibold leading-6 text-zinc-800">
                Contenido
              </label>
              <div class="flex gap-2">
                <button
                  type="submit"
                  class="px-3 py-1 text-xs bg-green-500 text-white hover:bg-green-600 transition-colors rounded border border-green-500"
                >
                  Guardar
                </button>
                <button
                  type="button"
                  phx-click="cancel"
                  class="px-3 py-1 text-xs bg-gray-200 text-gray-700 hover:bg-gray-300 transition-colors rounded border border-gray-300"
                >
                  Cancelar
                </button>
                <div class="flex rounded-md overflow-hidden border border-gray-300 ml-4">
                  <button
                    type="button"
                    id="text-mode"
                    class="px-3 py-1 text-xs bg-blue-500 text-white hover:bg-blue-600 transition-colors"
                    onclick="switchMode('text')"
                  >
                    Texto
                  </button>
                  <button
                    type="button"
                    id="preview-mode"
                    class="px-3 py-1 text-xs bg-gray-200 text-gray-700 hover:bg-gray-300 transition-colors"
                    onclick="switchMode('preview')"
                  >
                    Vista MD
                  </button>
                </div>
              </div>
            </div>
            <div class="relative">
              <textarea
                id="nota-contenido"
                name="nota[contenido]"
                placeholder="Escribe tu nota aquí... (soporta Markdown)"
                rows="20"
                class="w-full border-0 bg-transparent resize-none focus:ring-0 focus:border-transparent"
                phx-hook="Autosave"
              >{input_value(@changeset, :contenido)}</textarea>
              <div
                id="markdown-preview"
                class="w-full border-0 bg-transparent resize-none hidden markdown-preview-content"
                style="min-height: 480px; padding: 12px;"
              >
              </div>
            </div>
          </div>

          <input type="hidden" name="nota[rut_usuario]" value={@rut_usuario} />

          <div :if={@saving} class="text-sm text-gray-500 mt-4">
            Guardando...
          </div>
        </.form>
      </div>
    </div>

    <style>
      .markdown-preview-content h1 { font-size: 2rem !important; font-weight: bold !important; margin: 1rem 0 !important; }
      .markdown-preview-content h2 { font-size: 1.5rem !important; font-weight: bold !important; margin: 1rem 0 !important; }
      .markdown-preview-content h3 { font-size: 1.25rem !important; font-weight: bold !important; margin: 1rem 0 !important; }
      .markdown-preview-content ul { margin: 0.5rem 0 !important; padding-left: 1.5rem !important; }
      .markdown-preview-content li { list-style-type: disc !important; margin: 0.25rem 0 !important; }
      .markdown-preview-content strong { font-weight: bold !important; }
      .markdown-preview-content em { font-style: italic !important; }
      .markdown-preview-content p { margin: 0.5rem 0 !important; line-height: 1.6 !important; }
    </style>
    """
  end
end
