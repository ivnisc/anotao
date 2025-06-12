defmodule Anotao.Notas do
  @moduledoc """
  contexto para manejo de notas de usuarios
  """

  import Ecto.Query, warn: false
  alias Anotao.Repo
  alias Anotao.Notas.Nota

  @doc """
  lista todas las notas de un usuario por rut
  """
  def list_notas_by_usuario(rut_usuario) do
    Nota
    |> where([n], n.rut_usuario == ^rut_usuario)
    |> order_by([n], desc: n.updated_at)
    |> Repo.all()
  end

  @doc """
  obtiene una nota específica por slug y rut de usuario
  """
  def get_nota_by_slug!(rut_usuario, slug) do
    Nota
    |> where([n], n.rut_usuario == ^rut_usuario and n.slug == ^slug)
    |> Repo.one!()
  end

  @doc """
  crea una nueva nota
  """
  def create_nota(attrs \\ %{}) do
    %Nota{}
    |> Nota.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  actualiza una nota existente
  """
  def update_nota(%Nota{} = nota, attrs) do
    nota
    |> Nota.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  elimina una nota
  """
  def delete_nota(%Nota{} = nota) do
    Repo.delete(nota)
  end

  @doc """
  crea changeset para nota sin persistir
  """
  def change_nota(%Nota{} = nota, attrs \\ %{}) do
    Nota.changeset(nota, attrs)
  end

  @doc """
  verifica si existe una nota con slug específico para un usuario
  """
  def nota_exists?(rut_usuario, slug) do
    Nota
    |> where([n], n.rut_usuario == ^rut_usuario and n.slug == ^slug)
    |> Repo.exists?()
  end
end