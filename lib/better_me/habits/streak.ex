defmodule BetterMe.Habits.Streak do
  @doc """
  Calculates the current streak from a list of completed log dates.
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

  @doc """
  Calculates the longest streak ever from a list of completed log dates.
  """
  @spec longest([Date.t()]) :: non_neg_integer()
  def longest([]), do: 0

  def longest(dates) do
    dates
    |> Enum.sort({:asc, Date})
    |> Enum.chunk_while([], &chunk_consecutive/2, &{:cont, &1, []})
    |> Enum.map(&length/1)
    |> Enum.max(fn -> 0 end)
  end

  defp count_consecutive([_], _prev, count), do: count

  defp count_consecutive([_ | rest], prev, count) do
    expected = Date.add(prev, -1)

    case hd(rest) do
      ^expected -> count_consecutive(rest, expected, count + 1)
      _ -> count
    end
  end

  defp chunk_consecutive(date, []) do
    {:cont, [date]}
  end

  defp chunk_consecutive(date, [prev | _] = acc) do
    if Date.diff(date, prev) == 1 do
      {:cont, [date | acc]}
    else
      {:cont, acc, [date]}
    end
  end
end
