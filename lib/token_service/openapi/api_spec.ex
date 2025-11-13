defmodule TokenService.OpenApi.ApiSpec do
  @moduledoc """
  OpenAPI specification for the Token Service API.
  """

  alias OpenApiSpex.{
    Info,
    MediaType,
    OpenApi,
    Operation,
    PathItem,
    RequestBody,
    Response,
    Server
  }

  alias TokenService.OpenApi.Schemas.{ValidateRequest, ValidateResponse}
  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      servers: [
        %Server{
          url: "http://localhost:4000",
          description: "Local server"
        },
        %Server{
          url: "http://token-service-alb-793454956.us-east-1.elb.amazonaws.com",
          description: "Production server"
        }
      ],
      info: %Info{
        title: "Token Service API",
        version: "1.0.0",
        description: "Microsserviço HTTP para validação de tokens JWT"
      },
      paths: %{
        "/validate" => %PathItem{
          post: %Operation{
            summary: "Validate JWT Token",
            description: """
            Validates a JWT token according to business rules:
            - Must be a valid JWT
            - Must contain exactly 3 claims (Name, Role, Seed)
            - Name cannot contain numbers
            - Role must be one of: Admin, Member, External
            - Seed must be a prime number
            - Name maximum length: 256 characters
            """,
            operationId: "TokenService.validate",
            tags: ["Token Validation"],
            requestBody: %RequestBody{
              description: "JWT token to validate",
              required: true,
              content: %{
                "application/json" => %MediaType{
                  schema: ValidateRequest,
                  examples: %{
                    "valid_token" => %OpenApiSpex.Example{
                      summary: "Valid Token (Challenge Case 1)",
                      description: "A valid JWT with all claims meeting business rules",
                      value: %{
                        "token" =>
                          "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiQWRtaW4iLCJTZWVkIjoiNzg0MSIsIk5hbWUiOiJUb25pbmhvIEFyYXVqbyJ9.QY05sIjtrcJnP533kQNk8QXcaleJ1Q01jWY_ZzIZuAg"
                      }
                    },
                    "invalid_claims" => %OpenApiSpex.Example{
                      summary: "Invalid Token - Name with Numbers (Challenge Case 3)",
                      description:
                        "JWT is valid but Name claim contains numbers, violating business rules",
                      value: %{
                        "token" =>
                          "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiRXh0ZXJuYWwiLCJTZWVkIjoiODgwMzciLCJOYW1lIjoiTTRyaWEgT2xpdmlhIn0.6YD73XWZYQSSMDf6H0i3-kylz1-TY_Yt6h1cV2Ku-Qs"
                      }
                    },
                    "malformed_jwt" => %OpenApiSpex.Example{
                      summary: "Malformed JWT (Challenge Case 2)",
                      description: "Invalid JWT structure that cannot be decoded",
                      value: %{
                        "token" =>
                          "eyJhbGciOiJzI1NiJ9.dfsdfsfryJSr2xrIjoiQWRtaW4iLCJTZrkIjoiNzg0MSIsIk5hbrUiOiJUb25pbmhvIEFyYXVqbyJ9.QY05fsdfsIjtrcJnP533kQNk8QXcaleJ1Q01jWY_ZzIZuAg"
                      }
                    }
                  }
                }
              }
            },
            responses: %{
              200 => %Response{
                description: "Validation result",
                content: %{
                  "application/json" => %MediaType{
                    schema: ValidateResponse
                  }
                }
              }
            }
          }
        }
      }
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
