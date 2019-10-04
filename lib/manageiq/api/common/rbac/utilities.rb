module ManageIQ
  module API
    module Common
      module RBAC
        module Utilities
          def validate_groups
            Service.call(RBACApiClient::GroupApi) do |api|
              uuids = SortedSet.new
              Service.paginate(api, :list_groups, {}).each { |group| uuids << group.uuid }
              missing = @group_uuids - uuids
              raise ManageIQ::API::Common::InvalidParameter, "The following group uuids are missing #{missing.to_a.join(",")}" unless missing.empty?
            end
          end

          def unique_name(resource_id, group_id)
            "#{@app_name}-#{@resource_name}-#{resource_id}-group-#{group_id}"
          end

          def parse_ids_from_name(name)
            @regexp ||= Regexp.new("#{@app_name}-#{@resource_name}-(?<resource_id>.*)-group-(?<group_uuid>.*)")
            result = @regexp.match(name)
            if result
              [result[:resource_id], result[:group_uuid]]
            end
          end
        end
      end
    end
  end
end
