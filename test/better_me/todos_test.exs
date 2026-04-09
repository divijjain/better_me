defmodule BetterMe.TodosTest do
  use BetterMe.DataCase, async: true

  alias BetterMe.Todos
  alias BetterMe.Todos.Schema.Todo

  import BetterMe.Factory

  setup do
    %{user: insert(:user)}
  end

  describe "create_todo/2" do
    test "creates todo with valid attrs", %{user: user} do
      assert {:ok, todo} =
               Todos.create_todo(user.id, %{title: "Buy groceries", category: :personal})

      assert todo.title == "Buy groceries"
      assert todo.category == :personal
      assert todo.priority == :medium
      assert todo.completed == false
      assert todo.user_id == user.id
    end

    test "returns error when title is missing", %{user: user} do
      assert {:error, changeset} = Todos.create_todo(user.id, %{category: :work})
      assert %{title: [_]} = errors_on(changeset)
    end

    test "returns error when category is missing", %{user: user} do
      assert {:error, changeset} = Todos.create_todo(user.id, %{title: "Do something"})
      assert %{category: [_]} = errors_on(changeset)
    end

    test "returns error for invalid category", %{user: user} do
      assert {:error, changeset} =
               Todos.create_todo(user.id, %{title: "Do something", category: :invalid})

      assert %{category: [_]} = errors_on(changeset)
    end

    test "allows setting priority and due_date", %{user: user} do
      due = ~D[2026-12-31]

      assert {:ok, todo} =
               Todos.create_todo(user.id, %{
                 title: "Ship it",
                 category: :work,
                 priority: :high,
                 due_date: due
               })

      assert todo.priority == :high
      assert todo.due_date == due
    end
  end

  describe "list_todos/1" do
    test "returns incomplete todos by default", %{user: user} do
      todo = insert(:todo, user: user)
      todos = Todos.list_todos(user.id)
      assert Enum.any?(todos, &(&1.id == todo.id))
    end

    test "does not return completed todos by default", %{user: user} do
      todo = insert(:todo, user: user)
      {:ok, completed} = Todos.complete_todo(todo)
      todos = Todos.list_todos(user.id)
      refute Enum.any?(todos, &(&1.id == completed.id))
    end

    test "does not return todos from other users", %{user: user} do
      insert(:todo, user: insert(:user))
      todos = Todos.list_todos(user.id)
      assert Enum.all?(todos, &(&1.user_id == user.id))
    end
  end

  describe "get_todo/2" do
    test "returns {:ok, todo} for valid owner", %{user: user} do
      todo = insert(:todo, user: user)
      assert {:ok, found} = Todos.get_todo(todo.id, user.id)
      assert found.id == todo.id
    end

    test "returns {:error, :not_found} for wrong user", %{user: user} do
      todo = insert(:todo, user: insert(:user))
      assert {:error, :not_found} = Todos.get_todo(todo.id, user.id)
    end

    test "returns {:error, :not_found} for nonexistent id", %{user: user} do
      assert {:error, :not_found} = Todos.get_todo(0, user.id)
    end
  end

  describe "update_todo/2" do
    test "updates title and category", %{user: user} do
      todo = insert(:todo, user: user)
      assert {:ok, updated} = Todos.update_todo(todo, %{title: "Updated", category: :health})
      assert updated.title == "Updated"
      assert updated.category == :health
    end
  end

  describe "complete_todo/1" do
    test "marks todo as completed", %{user: user} do
      todo = insert(:todo, user: user)
      assert {:ok, completed} = Todos.complete_todo(todo)
      assert completed.completed == true
    end
  end

  describe "delete_todo/1" do
    test "deletes the todo", %{user: user} do
      todo = insert(:todo, user: user)
      assert {:ok, _} = Todos.delete_todo(todo)
      assert {:error, :not_found} = Todos.get_todo(todo.id, user.id)
    end
  end

  describe "change_todo/2" do
    test "returns a changeset", %{user: user} do
      todo = insert(:todo, user: user)
      assert %Ecto.Changeset{} = Todos.change_todo(todo, %{title: "Changed"})
    end
  end

  # ---------------------------------------------------------------------------
  # Changesets
  # ---------------------------------------------------------------------------

  describe "Todo.create_changeset/2" do
    test "invalid when title exceeds 200 chars" do
      user = insert(:user)

      cs =
        Todo.create_changeset(%Todo{}, %{
          title: String.duplicate("a", 201),
          category: :personal,
          user_id: user.id
        })

      assert %{title: [_]} = errors_on(cs)
    end

    test "invalid for unknown category" do
      user = insert(:user)
      cs = Todo.create_changeset(%Todo{}, %{title: "Task", category: :invalid, user_id: user.id})
      assert %{category: [_]} = errors_on(cs)
    end

    test "valid for all categories" do
      user = insert(:user)

      for cat <- [:work, :personal, :health, :learning, :misc] do
        cs = Todo.create_changeset(%Todo{}, %{title: "Task", category: cat, user_id: user.id})
        assert cs.valid?, "expected valid for category #{cat}"
      end
    end

    test "invalid for unknown priority" do
      user = insert(:user)

      cs =
        Todo.create_changeset(%Todo{}, %{
          title: "Task",
          category: :work,
          user_id: user.id,
          priority: :critical
        })

      assert %{priority: [_]} = errors_on(cs)
    end

    test "valid for all priorities" do
      user = insert(:user)

      for p <- [:low, :medium, :high] do
        cs =
          Todo.create_changeset(%Todo{}, %{
            title: "Task",
            category: :work,
            user_id: user.id,
            priority: p
          })

        assert cs.valid?, "expected valid for priority #{p}"
      end
    end

    test "defaults priority to :medium and completed to false" do
      user = insert(:user)
      cs = Todo.create_changeset(%Todo{}, %{title: "Task", category: :work, user_id: user.id})
      assert Ecto.Changeset.get_field(cs, :priority) == :medium
      assert Ecto.Changeset.get_field(cs, :completed) == false
    end
  end

  describe "Todo.update_changeset/2" do
    test "invalid when title is cleared" do
      todo = insert(:todo)
      cs = Todo.update_changeset(todo, %{title: nil})
      assert %{title: [_]} = errors_on(cs)
    end
  end
end
