defmodule BetterMe.Seeds do
  @moduledoc """
  Entry point for seeding. Delegates to per-domain seed modules.

  Dev:  mix run -e "BetterMe.Seeds.run()"  (also called by mix ecto.setup)
  Prod: BetterMe.Release.seed()
  """

  alias BetterMe.Seeds.{Habits, Ingredients, RoutineTemplates, Users}

  def run do
    Users.run()
    Habits.run()
    Ingredients.run()
    RoutineTemplates.run()
    IO.puts("\nDone.")
  end
end
