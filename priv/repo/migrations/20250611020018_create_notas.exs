defmodule Anotao.Repo.Migrations.CreateNotas do
  use Ecto.Migration

  def change do
    create table(:notas) do
      add :titulo, :string, null: false
      add :contenido, :text, null: false
      add :slug, :string, null: false
      add :rut_usuario, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:notas, [:slug, :rut_usuario])
    create index(:notas, [:rut_usuario])
  end
end
