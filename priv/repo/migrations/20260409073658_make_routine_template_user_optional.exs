defmodule BetterMe.Repo.Migrations.MakeRoutineTemplateUserOptional do
  use Ecto.Migration

  def change do
    alter table(:routine_templates) do
      modify :user_id, references(:users, on_delete: :nilify_all),
        null: true,
        from: references(:users, on_delete: :delete_all)
    end
  end
end
