module Mobility
  module Backend
=begin

Defines read and write methods that access the value at a key with value
+locale+ on a +translations+ hash.

=end
    module HashValued
      # @!group Backend Accessors
      #
      # @!macro backend_reader
      def read(locale, _ = {})
        translations[locale]
      end

      # @!macro backend_writer
      def write(locale, value, _ = {})
        translations[locale] = value
      end
      # @!endgroup
    end
  end
end
