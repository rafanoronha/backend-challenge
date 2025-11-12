defmodule TokenService.JwtDecoderTest do
  use ExUnit.Case, async: true

  alias TokenService.JwtDecoder

  describe "decode/1 with valid tokens" do
    test "decodes a valid JWT from challenge case 1" do
      token =
        "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiQWRtaW4iLCJTZWVkIjoiNzg0MSIsIk5hbWUiOiJUb25pbmhvIEFyYXVqbyJ9.QY05sIjtrcJnP533kQNk8QXcaleJ1Q01jWY_ZzIZuAg"

      assert {:ok, claims} = JwtDecoder.decode(token)
      assert claims["Name"] == "Toninho Araujo"
      assert claims["Role"] == "Admin"
      assert claims["Seed"] == "7841"
    end

    test "decodes a valid JWT from challenge case 3" do
      token =
        "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiRXh0ZXJuYWwiLCJTZWVkIjoiODgwMzciLCJOYW1lIjoiTTRyaWEgT2xpdmlhIn0.6YD73XWZYQSSMDf6H0i3-kylz1-TY_Yt6h1cV2Ku-Qs"

      assert {:ok, claims} = JwtDecoder.decode(token)
      assert claims["Name"] == "M4ria Olivia"
      assert claims["Role"] == "External"
      assert claims["Seed"] == "88037"
    end

    test "decodes a valid JWT from challenge case 4" do
      token =
        "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiTWVtYmVyIiwiT3JnIjoiQlIiLCJTZWVkIjoiMTQ2MjciLCJOYW1lIjoiVmFsZGlyIEFyYW5oYSJ9.cmrXV_Flm5mfdpfNUVopY_I2zeJUy4EZ4i3Fea98zvY"

      assert {:ok, claims} = JwtDecoder.decode(token)
      assert claims["Name"] == "Valdir Aranha"
      assert claims["Role"] == "Member"
      assert claims["Org"] == "BR"
      assert claims["Seed"] == "14627"
    end

    test "decodes JWT with minimal claims" do
      token = "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiQWRtaW4ifQ.xxx"

      assert {:ok, claims} = JwtDecoder.decode(token)
      assert claims["Role"] == "Admin"
    end
  end

  describe "decode/1 with invalid tokens" do
    test "returns error for malformed JWT from challenge case 2" do
      token =
        "eyJhbGciOiJzI1NiJ9.dfsdfsfryJSr2xrIjoiQWRtaW4iLCJTZrkIjoiNzg0MSIsIk5hbrUiOiJUb25pbmhvIEFyYXVqbyJ9.QY05fsdfsIjtrcJnP533kQNk8QXcaleJ1Q01jWY_ZzIZuAg"

      assert {:error, :invalid_token} = JwtDecoder.decode(token)
    end

    test "returns error for completely invalid token" do
      assert {:error, :invalid_token} = JwtDecoder.decode("invalid")
    end

    test "returns error for empty string" do
      assert {:error, :invalid_token} = JwtDecoder.decode("")
    end

    test "returns error for token with only one part" do
      assert {:error, :invalid_token} = JwtDecoder.decode("onlyonepart")
    end

    test "returns error for token with only two parts" do
      assert {:error, :invalid_token} = JwtDecoder.decode("header.payload")
    end

    test "returns error for non-binary input (integer)" do
      assert {:error, :invalid_token} = JwtDecoder.decode(123)
    end

    test "returns error for non-binary input (nil)" do
      assert {:error, :invalid_token} = JwtDecoder.decode(nil)
    end

    test "returns error for non-binary input (map)" do
      assert {:error, :invalid_token} = JwtDecoder.decode(%{})
    end
  end
end
