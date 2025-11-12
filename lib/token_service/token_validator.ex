defmodule TokenService.TokenValidator do
  @moduledoc """
  Validates JWT tokens by decoding and checking claims against business rules.
  """

  alias TokenService.{JwtDecoder, Claims}

  @doc """
  Validates a JWT token string.

  Returns `true` if the token is valid and all claims meet requirements.
  Returns `false` otherwise.

  ## Examples

      iex> TokenService.TokenValidator.validate("eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiQWRtaW4iLCJTZWVkIjoiNyIsIk5hbWUiOiJKb2huIERvZSJ9.xxx")
      true

      iex> TokenService.TokenValidator.validate("invalid")
      false

  """
  def validate(token) do
    with {:ok, claims} <- JwtDecoder.decode(token),
         changeset <- Claims.changeset(claims),
         true <- changeset.valid? do
      true
    else
      _ -> false
    end
  end
end
