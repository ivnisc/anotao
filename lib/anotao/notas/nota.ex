defmodule Anotao.Notas.Nota do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notas" do
    field :titulo, :string
    field :contenido, :string
    field :slug, :string
    field :rut_usuario, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  changeset para validar y procesar datos de nota
  """
  def changeset(nota, attrs) do
    nota
    |> cast(attrs, [:titulo, :contenido, :rut_usuario])
    |> validate_required([:titulo, :contenido, :rut_usuario])
    |> validate_length(:titulo, max: 50)
    |> generate_slug()
    |> unique_constraint([:slug, :rut_usuario])
  end

  # genera slug automáticamente desde el título
  defp generate_slug(changeset) do
    case get_change(changeset, :titulo) do
      nil -> changeset
      titulo -> put_change(changeset, :slug, Anotao.Utils.Slug.generate(titulo))
    end
  end
end