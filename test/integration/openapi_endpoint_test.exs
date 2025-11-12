defmodule TokenService.Integration.OpenApiEndpointTest do
  use ExUnit.Case
  import Plug.Test
  import Plug.Conn

  alias TokenService.Router

  @opts Router.init([])

  describe "GET /api/openapi" do
    @tag :integration
    test "returns OpenAPI spec in JSON format" do
      conn =
        conn(:get, "/api/openapi")
        |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]

      spec = Jason.decode!(conn.resp_body)
      assert spec["openapi"] == "3.0.0"
      assert spec["info"]["title"] == "Token Service API"
      assert spec["info"]["version"] == "1.0.0"
    end

    @tag :integration
    test "includes /validate endpoint in paths" do
      conn =
        conn(:get, "/api/openapi")
        |> Router.call(@opts)

      spec = Jason.decode!(conn.resp_body)
      assert Map.has_key?(spec["paths"], "/validate")
      assert Map.has_key?(spec["paths"]["/validate"], "post")
    end

    @tag :integration
    test "includes schemas for ValidateRequest and ValidateResponse" do
      conn =
        conn(:get, "/api/openapi")
        |> Router.call(@opts)

      spec = Jason.decode!(conn.resp_body)
      assert Map.has_key?(spec["components"]["schemas"], "ValidateRequest")
      assert Map.has_key?(spec["components"]["schemas"], "ValidateResponse")
    end

    @tag :integration
    test "includes three request examples" do
      conn =
        conn(:get, "/api/openapi")
        |> Router.call(@opts)

      spec = Jason.decode!(conn.resp_body)

      examples =
        spec["paths"]["/validate"]["post"]["requestBody"]["content"]["application/json"][
          "examples"
        ]

      assert Map.has_key?(examples, "valid_token")
      assert Map.has_key?(examples, "invalid_claims")
      assert Map.has_key?(examples, "malformed_jwt")

      assert examples["valid_token"]["summary"] == "Valid Token (Challenge Case 1)"

      assert examples["invalid_claims"]["summary"] ==
               "Invalid Token - Name with Numbers (Challenge Case 3)"

      assert examples["malformed_jwt"]["summary"] == "Malformed JWT (Challenge Case 2)"
    end
  end

  describe "GET /api/swagger" do
    @tag :integration
    test "returns Swagger UI HTML page" do
      conn =
        conn(:get, "/api/swagger")
        |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]
      assert conn.resp_body =~ "swagger-ui"
      assert conn.resp_body =~ "/api/openapi"
    end
  end
end
