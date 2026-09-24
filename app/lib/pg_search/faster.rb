module PgSearch
  module Faster
    extend ActiveSupport::Concern

    DISALLOWED_TSQUERY_CHARACTERS = /['?\\:]/

    class_methods do
      def fulltext_search(query, against:, unaccent_f: "unaccent")
        sanitized_terms = sanitize_terms(query)

        return none if sanitized_terms.empty?

        query_sql = sanitized_terms.map do
          "to_tsquery('simple', ''' ' || #{unaccent_f}(?) || ' ''')"
        end.join(" && ")

        where("#{fulltext_index_expression(against:, unaccent_f:)} @@ (#{query_sql})", *sanitized_terms)
      end

      def sanitize_terms(query)
        query.gsub(DISALLOWED_TSQUERY_CHARACTERS, " ").split.reject(&:empty?)
      end

      def fulltext_index_expression(against:, unaccent_f: "unaccent")
        expr = against.map do |column|
          "to_tsvector('simple', #{unaccent_f}(coalesce((#{table_name}.#{column})::text, '')))"
        end.join(" || ")

        "(#{expr})"
      end
    end
  end
end
