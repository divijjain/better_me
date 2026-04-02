defmodule BetterMe.Habits.Streak do
  @doc """
  Calculates the current streak from a list of completed log dates (most recent first).
  A streak is the number of consecutive days ending today or yesterday.
  """
  @spec calculate([Date.t()]) :: non_neg_integer()
  def calculate([]), do: 0

  def calculate(dates) do
    today = Date.utc_today()
    sorted = Enum.sort(dates, {:desc, Date})

    yesterday = Date.add(today, -1)
    most_recent = hd(sorted)

    if most_recent == today or most_recent == yesterday do
      count_consecutive(sorted, most_recent, 1)
    else
      0
    end
  end

  defp count_consecutive([_], _prev, count), do: count

  defp count_consecutive([_ | rest], prev, count) do
    expected = Date.add(prev, -1)

    case hd(rest) do
      ^expected -> count_consecutive(rest, expected, count + 1)
      _ -> count
    end
  end
end
