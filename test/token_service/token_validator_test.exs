defmodule TokenService.TokenValidatorTest do
  use ExUnit.Case, async: true

  alias TokenService.TokenValidator

  describe "validate/1 with valid tokens" do
    test "returns true for challenge case 1 - valid token" do
      token =
        "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiQWRtaW4iLCJTZWVkIjoiNzg0MSIsIk5hbWUiOiJUb25pbmhvIEFyYXVqbyJ9.QY05sIjtrcJnP533kQNk8QXcaleJ1Q01jWY_ZzIZuAg"

      assert TokenValidator.validate(token) == true
    end

    test "returns true for token with Member role and prime seed" do
      # Name: "Valdir Aranha", Role: "Member", Seed: "7" (prime)
      token =
        "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiTWVtYmVyIiwiU2VlZCI6IjciLCJOYW1lIjoiVmFsZGlyIEFyYW5oYSJ9.xxx"

      assert TokenValidator.validate(token) == true
    end

    test "returns true for token with External role" do
      # Name: "Jane Doe", Role: "External", Seed: "13" (prime)
      token =
        "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiRXh0ZXJuYWwiLCJTZWVkIjoiMTMiLCJOYW1lIjoiSmFuZSBEb2UifQ.xxx"

      assert TokenValidator.validate(token) == true
    end
  end

  describe "validate/1 with invalid tokens" do
    test "returns false for challenge case 2 - malformed JWT" do
      token =
        "eyJhbGciOiJzI1NiJ9.dfsdfsfryJSr2xrIjoiQWRtaW4iLCJTZrkIjoiNzg0MSIsIk5hbrUiOiJUb25pbmhvIEFyYXVqbyJ9.QY05fsdfsIjtrcJnP533kQNk8QXcaleJ1Q01jWY_ZzIZuAg"

      assert TokenValidator.validate(token) == false
    end

    test "returns false for challenge case 3 - Name with numbers" do
      token =
        "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiRXh0ZXJuYWwiLCJTZWVkIjoiODgwMzciLCJOYW1lIjoiTTRyaWEgT2xpdmlhIn0.6YD73XWZYQSSMDf6H0i3-kylz1-TY_Yt6h1cV2Ku-Qs"

      assert TokenValidator.validate(token) == false
    end

    test "returns false for challenge case 4 - more than 3 claims" do
      token =
        "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiTWVtYmVyIiwiT3JnIjoiQlIiLCJTZWVkIjoiMTQ2MjciLCJOYW1lIjoiVmFsZGlyIEFyYW5oYSJ9.cmrXV_Flm5mfdpfNUVopY_I2zeJUy4EZ4i3Fea98zvY"

      assert TokenValidator.validate(token) == false
    end

    test "returns false for token with invalid role" do
      # Role: "SuperAdmin" (not in allowed list)
      token =
        "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiU3VwZXJBZG1pbiIsIlNlZWQiOiI3IiwiTmFtZSI6IkpvaG4gRG9lIn0.xxx"

      assert TokenValidator.validate(token) == false
    end

    test "returns false for token with non-prime seed" do
      # Seed: "10" (not prime)
      token =
        "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiQWRtaW4iLCJTZWVkIjoiMTAiLCJOYW1lIjoiSm9obiBEb2UifQ.xxx"

      assert TokenValidator.validate(token) == false
    end

    test "returns false for token with Name longer than 256 characters" do
      long_name = String.duplicate("a", 257)

      claims = %{
        "Name" => long_name,
        "Role" => "Admin",
        "Seed" => "7"
      }

      payload = Jason.encode!(claims)
      token = "eyJhbGciOiJIUzI1NiJ9.#{Base.url_encode64(payload, padding: false)}.xxx"

      assert TokenValidator.validate(token) == false
    end

    test "returns false for completely invalid token string" do
      assert TokenValidator.validate("invalid") == false
    end

    test "returns false for empty token" do
      assert TokenValidator.validate("") == false
    end

    test "returns false for token with missing claims" do
      # Only Role and Seed, missing Name
      token = "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiQWRtaW4iLCJTZWVkIjoiNyJ9.xxx"

      assert TokenValidator.validate(token) == false
    end
  end

  describe "validate/1 edge cases" do
    test "returns false for non-string input" do
      assert TokenValidator.validate(nil) == false
      assert TokenValidator.validate(123) == false
      assert TokenValidator.validate(%{}) == false
    end
  end
end
