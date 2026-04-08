# Script for populating the database. Run with:
#
#     mix run priv/repo/seeds.exs
#
# Each seed file is idempotent — safe to re-run at any time.
# Add new seed files here as new domains are built.

Code.eval_file("priv/repo/seeds/users.exs")
Code.eval_file("priv/repo/seeds/habits.exs")
Code.eval_file("priv/repo/seeds/routine_template.exs")
Code.eval_file("priv/repo/seeds/ingredients.exs")
Code.eval_file("priv/repo/seeds/ingredients_proteins.exs")
Code.eval_file("priv/repo/seeds/ingredients_grains.exs")
Code.eval_file("priv/repo/seeds/ingredients_millets_pulses.exs")

IO.puts("\nDone. Login: divij@better.me / betterme2026!")
IO.puts("Check mailbox at /dev/mailbox for magic links.")
