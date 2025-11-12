defmodule TokenService.OpenApi.Schemas.ValidateResponse do
  @moduledoc """
  Schema for JWT validation response.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ValidateResponse",
    description: "Response indicating if the token is valid",
    type: :object,
    properties: %{
      valid: %Schema{
        type: :boolean,
        description: "Whether the token is valid according to business rules"
      }
    },
    required: [:valid],
    example: %{
      "valid" => true
    }
  })
end
