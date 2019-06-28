class Endpoint < ApplicationRecord
  include TenancyConcern
  belongs_to :source

  has_one    :endpoint_availability
  has_many   :authentications, :as => :resource

  validates :role, :uniqueness => { :scope => :source_id }

  def base_url_path
    URI::Generic.build(:scheme => scheme, :host => host, :port => port, :path => path).to_s
  end
end
