module ManageIQ
  module API
    module Common
      module OpenApi
        class Docs
          class ComponentCollection < Hash
            attr_reader :doc

            def initialize(doc, category)
              @doc = doc
              @category = category
            end

            def [](name)
              super || load_definition(name)
            end

            def load_definition(name)
              raw_definition = @doc.content.fetch_path(*@category.split("/"), name)
              raise ArgumentError, "Failed to find definition for #{name}" unless raw_definition.kind_of?(Hash)

              definition = substitute_regexes(raw_definition)
              definition = substitute_references(definition)
              self[name] = OpenApi::Docs::ObjectDefinition.new.replace(definition)
            end

            private

            def substitute_references(object)
              if object.kind_of?(Array)
                object.collect { |i| substitute_references(i) }
              elsif object.kind_of?(Hash)
                return fetch_ref_value(object["$ref"]) if object.keys == ["$ref"]
                object.each { |k, v| object[k] = substitute_references(v) }
              else
                object
              end
            end

            def fetch_ref_value(ref_path)
              ref_paths = ref_path.split("/")
              property = ref_paths.last
              section  = ref_paths[1..-2]
              public_send(:[], property)
            end

            def substitute_regexes(object)
              if object.kind_of?(Array)
                object.collect { |i| substitute_regexes(i) }
              elsif object.kind_of?(Hash)
                object.each_with_object({}) do |(k, v), o|
                  o[k] = k == "pattern" ? regexp_from_pattern(v) : substitute_regexes(v)
                end
              else
                object
              end
            end

            def regexp_from_pattern(pattern)
              Regexp.new(pattern)
            end
          end
        end
      end
    end
  end
end
