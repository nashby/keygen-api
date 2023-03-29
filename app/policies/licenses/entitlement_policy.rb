# frozen_string_literal: true

module Licenses
  class EntitlementPolicy < ApplicationPolicy
    authorize :license

    def index?
      verify_permissions!('entitlement.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' | 'environment' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      in role: { name: 'user' } if license.user == bearer
        allow!
      in role: { name: 'license' } if license == bearer
        allow!
      else
        deny!
      end
    end

    def show?
      verify_permissions!('entitlement.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' | 'environment' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      in role: { name: 'user' } if license.user == bearer
        allow!
      in role: { name: 'license' } if license == bearer
        allow!
      else
        deny!
      end
    end

    def attach?
      verify_permissions!('license.entitlements.attach')
      verify_environment!

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'environment' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      else
        deny!
      end
    end

    def detach?
      verify_permissions!('license.entitlements.detach')
      verify_environment!

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'environment' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end
