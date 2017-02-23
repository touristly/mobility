module Mobility
  module Backend
    class ActiveRecord::Jsonb::QueryMethods < ActiveRecord::QueryMethods
      def initialize(attributes, **options)
        super
        attributes_extractor = @attributes_extractor

        define_method :where! do |opts, *rest|
          if i18n_keys = attributes_extractor.call(opts)
            locale = Mobility.locale
            opts = opts.with_indifferent_access

            result = i18n_keys.inject(all) do |scope, attr|
              value = opts.delete(attr)
              if value.nil?
                scope.where.not("#{table_name}.#{attr} ? :locale", locale: locale)
              else
                scope.where!("#{table_name}.#{attr} @> (?)::jsonb", { locale => value }.to_json)
              end
            end
            result = result.where!(opts, *rest) if opts.present?
            result
          else
            super(opts, *rest)
          end
        end
      end

      def extended(relation)
        super
        attributes_extractor = @attributes_extractor
        m = relation.model.arel_table

        mod = Module.new do
          define_method :not do |opts, *rest|
            if i18n_keys = attributes_extractor.call(opts)
              locale = Arel::Nodes.build_quoted(Mobility.locale.to_s)
              opts = opts.with_indifferent_access
              infix = Arel::Nodes::InfixOperation

              query = i18n_keys.inject(nil) { |ops, attr|
                column = m[attr.to_sym]
                has_key = infix.new(:'?', column, locale)
                predicate = Arel::Nodes.build_quoted({ Mobility.locale => opts.delete(attr) }.to_json)
                not_eq_value = infix.new(:'@>', m[attr.to_sym], predicate).not
                op = has_key.and(not_eq_value)
                ops ? ops.and(op) : op
              }

              super(opts, *rest).where(query)
            else
              super(opts, *rest)
            end
          end
        end
        relation.model.mobility_where_chain.prepend(mod)
      end
    end
  end
end
