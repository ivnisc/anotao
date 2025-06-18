defmodule AnotaoWeb.RedirectHTML do
  @moduledoc """
  renderizado HTML para la página principal de acceso por RUT
  """

  use AnotaoWeb, :html

  embed_templates "redirect_html/*"
end