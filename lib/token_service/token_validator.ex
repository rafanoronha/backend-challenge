defmodule TokenService.TokenValidator do
  @moduledoc """
  Validates JWT tokens by decoding and checking claims against business rules.
  """

  require Logger

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
         %Ecto.Changeset{valid?: true} <- Claims.changeset(claims) do
      Logger.debug("Token validation succeeded",
        validation_result: "success",
        claims_count: map_size(claims)
      )

      true
    else
      {:error, :invalid_token} ->
        Logger.debug("Token validation failed: invalid or malformed JWT",
          validation_result: "failed",
          reason: "invalid_jwt"
        )

        false

      %Ecto.Changeset{valid?: false} = changeset ->
        errors = format_changeset_errors(changeset)

        Logger.debug("Token validation failed: #{errors}",
          validation_result: "failed",
          reason: "invalid_claims",
          errors: errors
        )

        false
    end
  end

  defp format_changeset_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
    |> Enum.map(fn {field, messages} -> "#{field}: #{Enum.join(messages, ", ")}" end)
    |> Enum.join("; ")
  end
end
