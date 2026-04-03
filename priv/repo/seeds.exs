# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias BetterMe.Accounts
alias BetterMe.Habits

# ---------------------------------------------------------------------------
# Users
# ---------------------------------------------------------------------------

users = [
  %{email: "divij@better.me", password: "betterme2026!"},
  %{email: "test@better.me", password: "betterme2026!"}
]

created_users =
  Enum.map(users, fn attrs ->
    case Accounts.register_user(attrs) do
      {:ok, user} ->
        IO.puts("Created user: #{user.email}")
        user

      {:error, _} ->
        IO.puts("Skipped (already exists): #{attrs.email}")
        Accounts.get_user_by_email(attrs.email)
    end
  end)

primary_user = hd(created_users)

# ---------------------------------------------------------------------------
# Habits + log history for primary user
# ---------------------------------------------------------------------------

habit_seeds = [
  %{
    name: "Morning run",
    category: :fitness,
    frequency: :daily,
    # logged every day for last 14 days
    log_days: Enum.to_list(0..13)
  },
  %{
    name: "Read 30 mins",
    category: :learning,
    frequency: :daily,
    # logged most days, missed a few
    log_days: [0, 1, 2, 4, 5, 6, 7, 9, 10, 11]
  },
  %{
    name: "Meditate",
    category: :health,
    frequency: :daily,
    # sporadic
    log_days: [0, 2, 5, 8, 12, 15, 20]
  },
  %{
    name: "No sugar",
    category: :health,
    frequency: :daily,
    # strong streak
    log_days: Enum.to_list(0..20)
  }
]

today = Date.utc_today()

Enum.each(habit_seeds, fn seed ->
  attrs = Map.take(seed, [:name, :category, :frequency])

  case Habits.create_habit(primary_user.id, attrs) do
    {:ok, habit} ->
      IO.puts("Created habit: #{habit.name}")

      Enum.each(seed.log_days, fn days_ago ->
        date = Date.add(today, -days_ago)

        case Habits.log_habit(habit.id, %{date: date, completed: true}) do
          {:ok, _} -> :ok
          {:error, _} -> :ok
        end
      end)

      IO.puts("  Logged #{length(seed.log_days)} days for #{habit.name}")

    {:error, changeset} ->
      IO.puts("Failed to create habit #{seed.name}: #{inspect(changeset.errors)}")
  end
end)

IO.puts("\nDone. Login at /users/log-in with divij@better.me")
IO.puts("Check mailbox at /dev/mailbox for the magic link.")

# ---------------------------------------------------------------------------
# Min-Max 5x Routine Template (Jeff Nippard)
# ---------------------------------------------------------------------------

alias BetterMe.Repo
alias BetterMe.Workouts.Schema.{RoutineTemplate, RoutineDay, RoutineExercise}

min_max_days = [
  %{
    name: "Upper 1",
    position: 1,
    exercises: [
      %{
        name: "Barbell Incline Press",
        working_sets: 2,
        rep_range: "6-8",
        notes: "30° or 45° bench. Pause 1 sec at bottom.",
        substitution_1: "Smith Machine Incline Press",
        substitution_2: "DB Incline Press",
        position: 1
      },
      %{
        name: "Pec Deck",
        working_sets: 2,
        rep_range: "6-8",
        notes: "Pause 1 sec at bottom.",
        substitution_1: "DB Flye",
        substitution_2: "Cable Flye",
        position: 2
      },
      %{
        name: "Incline DB Y-Raise",
        working_sets: 2,
        rep_range: "8-10",
        notes: "30° incline bench. Lift up and out in a Y shape.",
        substitution_1: "Cable Y-Raise",
        substitution_2: "Machine Lateral Raise",
        position: 3
      },
      %{
        name: "Pull-Up (Wide Grip)",
        working_sets: 2,
        rep_range: "6-8",
        notes: "Control the negative. Full ROM!",
        substitution_1: "Lat Pulldown (Wide Grip)",
        substitution_2: "1-Arm Cable Pulldown",
        position: 4
      },
      %{
        name: "Kelso Shrug",
        working_sets: 2,
        rep_range: "6-8",
        notes: "Pause 1 sec at top. Let shoulder blades peel apart on way down.",
        substitution_1: "Seated Cable Kelso Shrug",
        substitution_2: "Incline DB Kelso Shrug",
        position: 5
      },
      %{
        name: "EZ-Bar Preacher Curl",
        working_sets: 2,
        rep_range: "6-8",
        notes: "Triceps pinned to pad. Smooth controlled reps.",
        substitution_1: "Machine Preacher Curl",
        substitution_2: "DB Preacher Curl",
        position: 6
      },
      %{
        name: "Triceps Pressdown",
        working_sets: 2,
        rep_range: "6-8",
        notes: "Rope or bar attachment.",
        substitution_1: "Close-Grip Bench Press",
        substitution_2: "Smith Machine JM Press",
        position: 7
      },
      %{
        name: "Dragon Flag",
        working_sets: 2,
        rep_range: "6-8",
        notes: "Keep body rigid throughout the ROM.",
        substitution_1: "Bent-Knee Dragon Flag",
        substitution_2: "Lying Leg Raise",
        position: 8
      }
    ]
  },
  %{
    name: "Lower 1",
    position: 2,
    exercises: [
      %{
        name: "Lying Leg Curl",
        working_sets: 2,
        rep_range: "6-8",
        notes: "Biggest stretch at bottom. Don't let butt pop up.",
        substitution_1: "Seated Leg Curl",
        substitution_2: "Nordic Ham Curl",
        position: 1
      },
      %{
        name: "Squat (Your Choice)",
        working_sets: 2,
        rep_range: "6-8",
        notes: "Back squat, front squat, hack squat, belt squat, or smith squat.",
        substitution_1: nil,
        substitution_2: nil,
        position: 2
      },
      %{
        name: "Smith Machine Lunge",
        working_sets: 1,
        rep_range: "6-8",
        notes: "Minimize contribution from back leg!",
        substitution_1: "DB Lunge",
        substitution_2: "Barbell Lunge",
        position: 3
      },
      %{
        name: "Leg Extension",
        working_sets: 2,
        rep_range: "6-8",
        notes: "Seat back as far as possible. Grab handles hard to pull butt down.",
        substitution_1: "Reverse Nordic",
        substitution_2: "Sissy Squat",
        position: 4
      },
      %{
        name: "Machine Hip Abduction",
        working_sets: 1,
        rep_range: "6-8",
        notes: "Use foam pads outside knees if possible for greater ROM.",
        substitution_1: "Cable Hip Abduction",
        substitution_2: "Standing Plate Abduction",
        position: 5
      },
      %{
        name: "Standing Calf Raise",
        working_sets: 2,
        rep_range: "6-8",
        notes: "1-2 sec pause at bottom. Roll ankle on balls of feet.",
        substitution_1: "Leg Press Calf Press",
        substitution_2: "Donkey Calf Raise",
        position: 6
      }
    ]
  },
  %{
    name: "Upper 2",
    position: 3,
    exercises: [
      %{
        name: "Close-Grip Lat Pulldown",
        working_sets: 2,
        rep_range: "8-10",
        notes: "Lean back 15°. Drive elbows down, squeeze shoulder blades.",
        substitution_1: "Close-Grip Pull-Up",
        substitution_2: "1-Arm Cable Pulldown",
        position: 1
      },
      %{
        name: "Chest-Supported T-Bar Row",
        working_sets: 2,
        rep_range: "8-10",
        notes: "Elbows at 45°. Squeeze shoulder blades hard at top.",
        substitution_1: "Chest-Supported Machine Row",
        substitution_2: "Chest-Supported DB Row",
        position: 2
      },
      %{
        name: "Machine Shrug",
        working_sets: 1,
        rep_range: "6-8",
        notes: "Shrug up to ears. Use straps if possible.",
        substitution_1: "Barbell Shrug",
        substitution_2: "Cable Shrug-In",
        position: 3
      },
      %{
        name: "Machine Chest Press",
        working_sets: 2,
        rep_range: "8-10",
        notes: "1 sec pause at bottom maintaining pec tension.",
        substitution_1: "Smith Machine Bench Press",
        substitution_2: "DB Bench Press",
        position: 4
      },
      %{
        name: "High-Cable Lateral Raise",
        working_sets: 2,
        rep_range: "8-10",
        notes: "Cable at hip height. Hand past midline at bottom for stretch.",
        substitution_1: "DB Lateral Raise",
        substitution_2: "Machine Lateral Raise",
        position: 5
      },
      %{
        name: "1-Arm Reverse Pec Deck",
        working_sets: 1,
        rep_range: "8-10",
        notes: "Sweep weight out in largest semi-circle possible.",
        substitution_1: "Lying Reverse DB Flye",
        substitution_2: "Reverse Cable Crossover",
        position: 6
      },
      %{
        name: "Cable Crunch",
        working_sets: 2,
        rep_range: "6-8",
        notes: "Round lower back as you crunch. Mind-muscle with abs.",
        substitution_1: "Weighted Crunch",
        substitution_2: "Machine Crunch",
        position: 7
      }
    ]
  },
  %{
    name: "Lower 2",
    position: 4,
    exercises: [
      %{
        name: "Leg Extension",
        working_sets: 2,
        rep_range: "8-10",
        notes: "Seat back as far as possible. Grab handles hard to pull butt down.",
        substitution_1: "Reverse Nordic",
        substitution_2: "Sissy Squat",
        position: 1
      },
      %{
        name: "Barbell RDL",
        working_sets: 2,
        rep_range: "6-8",
        notes: "Glutes back, bar straight down over mid-foot. Deep stretch, neutral spine.",
        substitution_1: "DB RDL",
        substitution_2: "Seated Cable Deadlift",
        position: 2
      },
      %{
        name: "Machine Hip Thrust",
        working_sets: 2,
        rep_range: "6-8",
        notes: "Squeeze glutes hard at top. Control the negative.",
        substitution_1: "Barbell Hip Thrust",
        substitution_2: "45° Hyperextension",
        position: 3
      },
      %{
        name: "Leg Press",
        working_sets: 1,
        rep_range: "6-8",
        notes: "Feet lower for quad focus. As deep as possible without back rounding.",
        substitution_1: "Smith Machine Squat",
        substitution_2: "Barbell Squat",
        position: 4
      },
      %{
        name: "Standing Calf Raise",
        working_sets: 2,
        rep_range: "8-10",
        notes: "1-2 sec pause at bottom. Roll ankle on balls of feet.",
        substitution_1: "Leg Press Calf Press",
        substitution_2: "Donkey Calf Raise",
        position: 5
      }
    ]
  },
  %{
    name: "Arms/Delts",
    position: 5,
    exercises: [
      %{
        name: "Bayesian Cable Curl",
        working_sets: 2,
        rep_range: "6-8",
        notes: "Lean forward at top. Control negative for deep stretch.",
        substitution_1: "Incline DB Curl",
        substitution_2: "Standing DB Curl",
        position: 1
      },
      %{
        name: "Overhead Cable Triceps Extension",
        working_sets: 2,
        rep_range: "8-10",
        notes: "Deep stretch on triceps throughout the negative.",
        substitution_1: "Overhead DB Triceps Extension",
        substitution_2: "Skull Crusher",
        position: 2
      },
      %{
        name: "Modified Zottman Curl",
        working_sets: 1,
        rep_range: "8-10",
        notes: "Hammer curl up, supinated (palms up) on the way down.",
        substitution_1: "DB Hammer Curl",
        substitution_2: "Preacher Hammer Curl",
        position: 3
      },
      %{
        name: "Cable Triceps Kickback",
        working_sets: 2,
        rep_range: "8-10",
        notes: "Upper arm behind torso throughout ROM.",
        substitution_1: "Seated Dip Machine",
        substitution_2: "Close-Grip Dip",
        position: 4
      },
      %{
        name: "DB Wrist Curl",
        working_sets: 2,
        rep_range: "8-10",
        notes: "Smooth, controlled reps.",
        substitution_1: "Cable Wrist Curl",
        substitution_2: nil,
        position: 5
      },
      %{
        name: "DB Wrist Extension",
        working_sets: 2,
        rep_range: "8-10",
        notes: "Smooth, controlled reps.",
        substitution_1: "Cable Wrist Extension",
        substitution_2: nil,
        position: 6
      },
      %{
        name: "Alternating DB Curl",
        working_sets: 1,
        rep_range: "6-8",
        notes: "Slow, controlled reps!",
        substitution_1: "Barbell Curl",
        substitution_2: "EZ-Bar Curl",
        position: 7
      },
      %{
        name: "Machine Lateral Raise",
        working_sets: 2,
        rep_range: "8-10",
        notes: "Squeeze side delt to move the weight.",
        substitution_1: "High-Cable Lateral Raise",
        substitution_2: "DB Lateral Raise",
        position: 8
      }
    ]
  }
]

existing_template =
  Repo.get_by(RoutineTemplate, name: "Min-Max 5x", user_id: primary_user.id)

if is_nil(existing_template) do
  {:ok, template} =
    %RoutineTemplate{user_id: primary_user.id}
    |> RoutineTemplate.changeset(%{name: "Min-Max 5x"})
    |> Repo.insert()

  IO.puts("\nCreated routine template: #{template.name}")

  Enum.each(min_max_days, fn day_data ->
    {:ok, day} =
      %RoutineDay{routine_template_id: template.id}
      |> RoutineDay.changeset(%{name: day_data.name, position: day_data.position})
      |> Repo.insert()

    IO.puts("  Day #{day.position}: #{day.name}")

    Enum.each(day_data.exercises, fn ex ->
      {:ok, _} =
        %RoutineExercise{routine_day_id: day.id}
        |> RoutineExercise.changeset(ex)
        |> Repo.insert()
    end)

    IO.puts("    #{length(day_data.exercises)} exercises seeded")
  end)
else
  IO.puts("\nSkipped: Min-Max 5x routine already exists")
end
