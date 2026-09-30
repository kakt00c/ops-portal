module ApiHelper
  # Backoffice clients authenticate with an ES256 JWT signed by their private key;
  # the portal only stores the public key, so tests generate a fresh pair.
  def api_client_with_key(client = clients(:pro_backoffice))
    key = OpenSSL::PKey::EC.generate("prime256v1")
    client.update!(api_token_public_key: key.public_to_pem)
    [ client, key ]
  end

  def api_token(client, key, sub: client.id, exp: 5.minutes.from_now.to_i, jti: SecureRandom.uuid)
    JWT.encode({ sub: sub, exp: exp, jti: jti }, key, "ES256")
  end

  def api_headers(token)
    { "Authorization" => "Bearer #{token}", "Accept" => "application/json" }
  end

  def with_zammad_client(mock, &block)
    TriageZammadEnvironment.stub(:client, mock, &block)
  end

  # schema: { key => Type | [Type, NilClass] | { nested } | [{ item schema }] }
  def assert_json_schema(schema, actual, path = "")
    assert_kind_of Hash, actual, "#{path} should be an object"
    assert_equal schema.keys.map(&:to_s).sort, actual.keys.sort, "#{path} keys"
    schema.each do |key, type|
      value = actual[key.to_s]
      here = "#{path}.#{key}"
      case type
      when Hash then assert_json_schema(type, value, here)
      when Array
        if type.first.is_a?(Hash)
          assert_kind_of Array, value, "#{here} should be an array"
          value.each_with_index { |item, i| assert_json_schema(type.first, item, "#{here}[#{i}]") }
        else
          assert type.any? { |t| t === value }, "#{here} should be one of #{type.inspect}, got #{value.inspect}"
        end
      else
        assert type === value, "#{here} should be #{type}, got #{value.inspect}"
      end
    end
  end
end
