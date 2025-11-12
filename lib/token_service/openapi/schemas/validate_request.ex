defmodule TokenService.OpenApi.Schemas.ValidateRequest do
  @moduledoc """
  Schema for JWT validation request.
  """

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ValidateRequest",
    description: "Request body for token validation",
    type: :object,
    properties: %{
      token: %Schema{
        type: :string,
        description: "JWT token string to validate",
        example:
          "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiQWRtaW4iLCJTZWVkIjoiNzg0MSIsIk5hbWUiOiJUb25pbmhvIEFyYXVqbyJ9.QY05sIjtrcJnP533kQNk8QXcaleJ1Q01jWY_ZzIZuAg"
      }
    },
    required: [:token],
    example: %{
      "token" =>
        "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiQWRtaW4iLCJTZWVkIjoiNzg0MSIsIk5hbWUiOiJUb25pbmhvIEFyYXVqbyJ9.QY05sIjtrcJnP533kQNk8QXcaleJ1Q01jWY_ZzIZuAg"
    }
  })
end
