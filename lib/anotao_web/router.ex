defmodule AnotaoWeb.Router do
  use AnotaoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AnotaoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AnotaoWeb do
    pipe_through :browser

    # ruta raíz - página principal de acceso
    get "/", RedirectController, :index
    post "/acceder", RedirectController, :redirect_to_notas
    get "/politica-datos", PoliticaController, :index

    # rutas para notas por usuario
    live "/:rut_usuario", Notas.IndexLive, :index
    live "/:rut_usuario/new", Notas.ShowLive, :new
    live "/:rut_usuario/:slug", Notas.ShowLive, :show
    live "/:rut_usuario/:slug/edit", Notas.ShowLive, :edit
  end

  # Other scopes may use custom stacks.
  # Other scopes may use custom stacks.
  # scope "/api", AnotaoWeb do
  #   pipe_through :api
  # end
end
