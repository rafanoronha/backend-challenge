defmodule TokenService.Claims do
  @moduledoc """
  Embedded schema for JWT claims validation.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :Name, :string
    field :Role, :string
    field :Seed, :string
  end

  @doc """
  Creates a changeset for the given claims map.
  """
  def changeset(claims) do
    %__MODULE__{}
    |> cast(claims, [:Name, :Role, :Seed])
    |> validate_required([:Name, :Role, :Seed])
  end
end
