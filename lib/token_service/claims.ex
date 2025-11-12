defmodule TokenService.Claims do
  @moduledoc """
  Embedded schema for JWT claims validation.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @valid_roles ["Admin", "Member", "External"]

  @primary_key false
  embedded_schema do
    field :Name, :string
    field :Role, :string
    field :Seed, :string
  end

  @doc """
  Creates a changeset for the given claims map.

  ## Examples

      iex> claims = %{"Name" => "John Doe", "Role" => "Admin", "Seed" => "7"}
      iex> changeset = TokenService.Claims.changeset(claims)
      iex> changeset.valid?
      true

      iex> claims = %{"Name" => "J0hn", "Role" => "Admin", "Seed" => "7"}
      iex> changeset = TokenService.Claims.changeset(claims)
      iex> changeset.valid?
      false

      iex> claims = %{"Name" => "Test", "Role" => "Invalid", "Seed" => "10"}
      iex> changeset = TokenService.Claims.changeset(claims)
      iex> changeset.valid?
      false

  """
  def changeset(claims) do
    %__MODULE__{}
    |> cast(claims, [:Name, :Role, :Seed])
    |> validate_required([:Name, :Role, :Seed])
    |> validate_exactly_three_claims(claims)
    |> validate_name_no_numbers()
    |> validate_role()
    |> validate_seed_is_prime()
    |> validate_length(:Name, max: 256)
  end

  defp validate_exactly_three_claims(changeset, claims) do
    if map_size(claims) == 3 do
      changeset
    else
      add_error(changeset, :base, "must contain exactly 3 claims")
    end
  end

  defp validate_name_no_numbers(changeset) do
    validate_change(changeset, :Name, fn :Name, name ->
      if String.match?(name, ~r/\d/) do
        [Name: "cannot contain numbers"]
      else
        []
      end
    end)
  end

  defp validate_role(changeset) do
    validate_inclusion(changeset, :Role, @valid_roles)
  end

  defp validate_seed_is_prime(changeset) do
    validate_change(changeset, :Seed, fn :Seed, seed_str ->
      case Integer.parse(seed_str) do
        {seed, ""} when seed > 1 ->
          if prime?(seed) do
            []
          else
            [Seed: "must be a prime number"]
          end

        _ ->
          [Seed: "must be a valid integer"]
      end
    end)
  end

  defp prime?(n) when n < 2, do: false
  defp prime?(2), do: true
  defp prime?(n) when rem(n, 2) == 0, do: false

  defp prime?(n) do
    limit = :math.sqrt(n) |> trunc()

    Enum.all?(3..limit//2, fn divisor ->
      rem(n, divisor) != 0
    end)
  end
end
