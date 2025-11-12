defmodule TokenService.JwtDecoder do
  @moduledoc """
  Decodes JWT tokens and extracts claims without signature verification.
  """

  @doc """
  Decodes a JWT token and returns the claims.

  ## Examples

      iex> TokenService.JwtDecoder.decode("eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiQWRtaW4ifQ.xxx")
      {:ok, %{"Role" => "Admin"}}

      iex> TokenService.JwtDecoder.decode("invalid")
      {:error, :invalid_token}
  """
  def decode(token) when is_binary(token) do
    case Joken.peek_claims(token) do
      {:ok, claims} -> {:ok, claims}
      {:error, _reason} -> {:error, :invalid_token}
    end
  rescue
    _ -> {:error, :invalid_token}
  end

  def decode(_), do: {:error, :invalid_token}
end
