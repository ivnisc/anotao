defmodule AnotaoWeb.PoliticaController do
  use AnotaoWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end