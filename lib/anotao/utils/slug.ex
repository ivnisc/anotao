defmodule Anotao.Utils.Slug do
  @moduledoc """
  utilidades para generar slugs desde texto
  """

  @doc """
  genera un slug url-friendly desde texto en español
  """
  def generate(texto) do
    texto
    |> String.downcase()
    |> String.replace(~r/[áàäâ]/, "a")
    |> String.replace(~r/[éèëê]/, "e")
    |> String.replace(~r/[íìïî]/, "i")
    |> String.replace(~r/[óòöô]/, "o")
    |> String.replace(~r/[úùüû]/, "u")
    |> String.replace(~r/[ñ]/, "n")
    |> String.replace(~r/[ç]/, "c")
    |> String.replace(~r/[^\w\s-]/, "")  # elimina caracteres especiales
    |> String.replace(~r/\s+/, "-")      # espacios a guiones
    |> String.replace(~r/-+/, "-")       # múltiples guiones a uno
    |> String.trim("-")                  # elimina guiones al inicio/final
    |> case do
      "" -> "nota-#{:os.system_time(:millisecond)}"  # fallback si queda vacío
      slug -> slug
    end
  end
end