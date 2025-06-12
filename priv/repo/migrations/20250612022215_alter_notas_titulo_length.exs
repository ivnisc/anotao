defmodule Anotao.Repo.Migrations.AlterNotasTituloLength do
  use Ecto.Migration

  def change do
    alter table(:notas) do
      modify :titulo, :string, size: 50
    end
  end
end
