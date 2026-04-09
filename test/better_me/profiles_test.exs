defmodule BetterMe.ProfilesTest do
  use BetterMe.DataCase, async: true

  alias BetterMe.Profiles.Schema.UserProfile

  import BetterMe.Factory

  defp valid_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        age: 30,
        weight_kg: 75.0,
        height_cm: 175.0,
        gender: :male,
        activity_level: :moderately_active,
        protein_pct: 30,
        carbs_pct: 40
      },
      overrides
    )
  end

  describe "UserProfile.changeset/2" do
    test "valid with all required fields" do
      user = insert(:user)
      cs = UserProfile.changeset(%UserProfile{}, Map.put(valid_attrs(), :user_id, user.id))
      assert cs.valid?
    end

    test "invalid without age" do
      user = insert(:user)

      cs =
        UserProfile.changeset(
          %UserProfile{},
          valid_attrs(%{age: nil}) |> Map.put(:user_id, user.id)
        )

      assert %{age: [_]} = errors_on(cs)
    end

    test "invalid when age is zero" do
      user = insert(:user)

      cs =
        UserProfile.changeset(
          %UserProfile{},
          valid_attrs(%{age: 0}) |> Map.put(:user_id, user.id)
        )

      assert %{age: [_]} = errors_on(cs)
    end

    test "invalid when age is 120 or above" do
      user = insert(:user)

      cs =
        UserProfile.changeset(
          %UserProfile{},
          valid_attrs(%{age: 120}) |> Map.put(:user_id, user.id)
        )

      assert %{age: [_]} = errors_on(cs)
    end

    test "invalid when weight_kg is zero or negative" do
      user = insert(:user)

      for w <- [0.0, -1.0] do
        cs =
          UserProfile.changeset(
            %UserProfile{},
            valid_attrs(%{weight_kg: w}) |> Map.put(:user_id, user.id)
          )

        assert %{weight_kg: [_]} = errors_on(cs), "expected invalid for weight_kg #{w}"
      end
    end

    test "invalid when height_cm is zero or negative" do
      user = insert(:user)

      for h <- [0.0, -1.0] do
        cs =
          UserProfile.changeset(
            %UserProfile{},
            valid_attrs(%{height_cm: h}) |> Map.put(:user_id, user.id)
          )

        assert %{height_cm: [_]} = errors_on(cs), "expected invalid for height_cm #{h}"
      end
    end

    test "invalid for unknown gender" do
      user = insert(:user)

      cs =
        UserProfile.changeset(
          %UserProfile{},
          valid_attrs(%{gender: :unknown}) |> Map.put(:user_id, user.id)
        )

      assert %{gender: [_]} = errors_on(cs)
    end

    test "valid for all genders" do
      user = insert(:user)

      for gender <- [:male, :female, :other] do
        cs =
          UserProfile.changeset(
            %UserProfile{},
            valid_attrs(%{gender: gender}) |> Map.put(:user_id, user.id)
          )

        assert cs.valid?, "expected valid for gender #{gender}"
      end
    end

    test "invalid for unknown activity_level" do
      user = insert(:user)

      cs =
        UserProfile.changeset(
          %UserProfile{},
          valid_attrs(%{activity_level: :couch_potato}) |> Map.put(:user_id, user.id)
        )

      assert %{activity_level: [_]} = errors_on(cs)
    end

    test "valid for all activity levels" do
      user = insert(:user)

      for level <- [:sedentary, :lightly_active, :moderately_active, :very_active, :extra_active] do
        cs =
          UserProfile.changeset(
            %UserProfile{},
            valid_attrs(%{activity_level: level}) |> Map.put(:user_id, user.id)
          )

        assert cs.valid?, "expected valid for activity_level #{level}"
      end
    end

    test "invalid when protein_pct is below 1" do
      user = insert(:user)

      cs =
        UserProfile.changeset(
          %UserProfile{},
          valid_attrs(%{protein_pct: 0}) |> Map.put(:user_id, user.id)
        )

      assert %{protein_pct: [_]} = errors_on(cs)
    end

    test "invalid when protein_pct exceeds 98" do
      user = insert(:user)

      cs =
        UserProfile.changeset(
          %UserProfile{},
          valid_attrs(%{protein_pct: 99}) |> Map.put(:user_id, user.id)
        )

      assert %{protein_pct: [_]} = errors_on(cs)
    end

    test "invalid when carbs_pct is below 1" do
      user = insert(:user)

      cs =
        UserProfile.changeset(
          %UserProfile{},
          valid_attrs(%{carbs_pct: 0}) |> Map.put(:user_id, user.id)
        )

      assert %{carbs_pct: [_]} = errors_on(cs)
    end

    test "invalid when protein + carbs leaves no room for fat" do
      user = insert(:user)

      cs =
        UserProfile.changeset(
          %UserProfile{},
          valid_attrs(%{protein_pct: 60, carbs_pct: 40}) |> Map.put(:user_id, user.id)
        )

      assert %{carbs_pct: [_]} = errors_on(cs)
    end

    test "valid when protein + carbs leaves at least 1% for fat" do
      user = insert(:user)

      cs =
        UserProfile.changeset(
          %UserProfile{},
          valid_attrs(%{protein_pct: 30, carbs_pct: 69}) |> Map.put(:user_id, user.id)
        )

      assert cs.valid?
    end
  end
end
