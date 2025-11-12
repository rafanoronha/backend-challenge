defmodule TokenService.ClaimsTest do
  use ExUnit.Case, async: true

  alias TokenService.Claims

  describe "changeset/1 with valid claims" do
    test "accepts valid claims with all requirements met" do
      claims = %{
        "Name" => "Toninho Araujo",
        "Role" => "Admin",
        "Seed" => "7841"
      }

      changeset = Claims.changeset(claims)

      assert changeset.valid?
    end

    test "accepts Member role" do
      claims = %{"Name" => "John Doe", "Role" => "Member", "Seed" => "7"}

      changeset = Claims.changeset(claims)

      assert changeset.valid?
    end

    test "accepts External role" do
      claims = %{"Name" => "Jane Doe", "Role" => "External", "Seed" => "13"}

      changeset = Claims.changeset(claims)

      assert changeset.valid?
    end

    test "accepts name with 256 characters" do
      name = String.duplicate("a", 256)
      claims = %{"Name" => name, "Role" => "Admin", "Seed" => "2"}

      changeset = Claims.changeset(claims)

      assert changeset.valid?
    end

    test "accepts large prime numbers" do
      claims = %{"Name" => "Test", "Role" => "Admin", "Seed" => "88037"}

      changeset = Claims.changeset(claims)

      assert changeset.valid?
    end
  end

  describe "changeset/1 with invalid Name" do
    test "rejects name with numbers" do
      claims = %{"Name" => "M4ria Olivia", "Role" => "External", "Seed" => "7"}

      changeset = Claims.changeset(claims)

      refute changeset.valid?
      assert %{Name: ["cannot contain numbers"]} = errors_on(changeset)
    end

    test "rejects name longer than 256 characters" do
      name = String.duplicate("a", 257)
      claims = %{"Name" => name, "Role" => "Admin", "Seed" => "2"}

      changeset = Claims.changeset(claims)

      refute changeset.valid?
      assert %{Name: [_]} = errors_on(changeset)
    end

    test "rejects missing Name" do
      claims = %{"Role" => "Admin", "Seed" => "7"}

      changeset = Claims.changeset(claims)

      refute changeset.valid?
      assert %{Name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "changeset/1 with invalid Role" do
    test "rejects invalid role" do
      claims = %{"Name" => "John Doe", "Role" => "InvalidRole", "Seed" => "7"}

      changeset = Claims.changeset(claims)

      refute changeset.valid?
      assert %{Role: ["is invalid"]} = errors_on(changeset)
    end

    test "rejects missing Role" do
      claims = %{"Name" => "John Doe", "Seed" => "7"}

      changeset = Claims.changeset(claims)

      refute changeset.valid?
      assert %{Role: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "changeset/1 with invalid Seed" do
    test "rejects non-prime number" do
      claims = %{"Name" => "John Doe", "Role" => "Admin", "Seed" => "10"}

      changeset = Claims.changeset(claims)

      refute changeset.valid?
      assert %{Seed: ["must be a prime number"]} = errors_on(changeset)
    end

    test "rejects 1 as non-prime" do
      claims = %{"Name" => "John Doe", "Role" => "Admin", "Seed" => "1"}

      changeset = Claims.changeset(claims)

      refute changeset.valid?
      assert %{Seed: ["must be a valid integer"]} = errors_on(changeset)
    end

    test "rejects 0 as non-prime" do
      claims = %{"Name" => "John Doe", "Role" => "Admin", "Seed" => "0"}

      changeset = Claims.changeset(claims)

      refute changeset.valid?
      assert %{Seed: ["must be a valid integer"]} = errors_on(changeset)
    end

    test "rejects negative numbers" do
      claims = %{"Name" => "John Doe", "Role" => "Admin", "Seed" => "-5"}

      changeset = Claims.changeset(claims)

      refute changeset.valid?
      assert %{Seed: ["must be a valid integer"]} = errors_on(changeset)
    end

    test "rejects non-numeric seed" do
      claims = %{"Name" => "John Doe", "Role" => "Admin", "Seed" => "abc"}

      changeset = Claims.changeset(claims)

      refute changeset.valid?
      assert %{Seed: ["must be a valid integer"]} = errors_on(changeset)
    end

    test "rejects missing Seed" do
      claims = %{"Name" => "John Doe", "Role" => "Admin"}

      changeset = Claims.changeset(claims)

      refute changeset.valid?
      assert %{Seed: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "changeset/1 with wrong number of claims" do
    test "rejects more than 3 claims" do
      claims = %{
        "Name" => "Valdir Aranha",
        "Role" => "Member",
        "Org" => "BR",
        "Seed" => "14627"
      }

      changeset = Claims.changeset(claims)

      refute changeset.valid?
      assert %{base: ["must contain exactly 3 claims"]} = errors_on(changeset)
    end

    test "rejects less than 3 claims" do
      claims = %{"Name" => "John Doe", "Role" => "Admin"}

      changeset = Claims.changeset(claims)

      refute changeset.valid?
      # Will fail on both "exactly 3 claims" and "Seed can't be blank"
      errors = errors_on(changeset)
      assert errors[:base] || errors[:Seed]
    end
  end

  describe "prime number detection" do
    test "correctly identifies small primes" do
      primes = ["2", "3", "5", "7", "11", "13", "17", "19", "23"]

      for seed <- primes do
        claims = %{"Name" => "Test", "Role" => "Admin", "Seed" => seed}
        changeset = Claims.changeset(claims)
        assert changeset.valid?, "Expected #{seed} to be prime"
      end
    end

    test "correctly identifies non-primes" do
      non_primes = ["4", "6", "8", "9", "10", "12", "14", "15", "16"]

      for seed <- non_primes do
        claims = %{"Name" => "Test", "Role" => "Admin", "Seed" => seed}
        changeset = Claims.changeset(claims)
        refute changeset.valid?, "Expected #{seed} to be non-prime"
      end
    end
  end

  # Helper function to extract errors from changeset
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
