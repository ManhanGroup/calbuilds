require 'csv'
require 'zip'
class Development < ApplicationRecord
  has_many :edits
  belongs_to :user
  include PgSearch
  pg_search_scope :search_by_name_and_location, against: [:name, :municipality, :address], using: { tsearch: { any_word: true } }
  validates :name, :status, :address, :zip_code, :hu,
            :commsf, :desc, presence: true
  validates_inclusion_of :rdv, :asofright, :clusteros, :phased, :stalled, :mixed_use,
                         :headqtrs, :ovr55, in: [true, false]
  with_options if: :projected?, presence: true do |projected|
    projected.validates :yrcomp_est
  end
  with_options if: :proposed?, presence: true do |proposed|
    proposed.validates :yrcomp_est
    proposed.validates :singfamhu
    proposed.validates :smmultifam
    proposed.validates :lgmultifam
    proposed.validates :onsitepark
    proposed.validates :park_type
  end
  with_options if: :groundbroken?, presence: :true do |groundbroken|
    groundbroken.validates :year_compl
    groundbroken.validates :singfamhu
    groundbroken.validates :smmultifam
    groundbroken.validates :lgmultifam
    groundbroken.validates :units_1bd
    groundbroken.validates :units_2bd
    groundbroken.validates :units_3bd
    groundbroken.validates :affrd_unit
    groundbroken.validates :aff_u30
    groundbroken.validates :aff_30_50
    groundbroken.validates :aff_50_80
    groundbroken.validates :aff_80p
    groundbroken.validates :gqpop
    groundbroken.validates :ret_sqft
    groundbroken.validates :ofcmd_sqft
    groundbroken.validates :indmf_sqft
    groundbroken.validates :whs_sqft
    groundbroken.validates :rnd_sqft
    groundbroken.validates :ei_sqft
    groundbroken.validates :other_sqft
    groundbroken.validates :hotel_sqft
    groundbroken.validates :hotelrms
    groundbroken.validates :onsitepark
    groundbroken.validates :park_type
    groundbroken.validates :publicsqft
  end

  after_save :update_rpa
  after_save :update_county

  def self.to_csv
    attributes = self.column_names
    CSV.generate(headers: true) do |csv|
      csv << self.column_names
      all.each do |development|
        csv << attributes.map{ |attr| development.send(attr) }
      end
    end
  end

  def self.to_shp(sql)
    database = Rails.configuration.database_configuration[Rails.env]
    file_name = "export-#{Time.now.to_i}"
    arguments = []
    arguments << "-f #{Rails.root.join('public', file_name)}"
    arguments << "-h #{database['host']}" if database['host']
    arguments << "-u #{database['username']}" if database['username']
    arguments << "-P #{database['password']}" if database['password']
    arguments << database['database']
    arguments << %("#{sql}") # %Q["SELECT * FROM developments;"]

    `pgsql2shp #{arguments.join(" ")}`

    zip(file_name)
  end

  private

  def self.zip(file_name)
    Zip::File.open(Rails.root.join('public', "#{file_name}.zip").to_s, Zip::File::CREATE) do |zipfile|
      zipfile.add("#{file_name}.shp", Rails.root.join('public', "#{file_name}.shp"))
      zipfile.add("#{file_name}.shx", Rails.root.join('public', "#{file_name}.shx"))
      zipfile.add("#{file_name}.dbf", Rails.root.join('public', "#{file_name}.dbf"))
      zipfile.add("#{file_name}.cpg", Rails.root.join('public', "#{file_name}.cpg"))
    end
    return file_name
  end

  def projected?
    status == 'projected'
  end

  def proposed?
    status == 'proposed'
  end

  def groundbroken?
    status == ('in_construction' || 'completed')
  end

  def update_rpa
    return if rpa_poly_id.present?
    rpa_query = <<~SQL
      SELECT objectid
      FROM
        (SELECT objectid, ST_TRANSFORM(rpa_poly.shape, 4326) as shape FROM rpa_poly) rpa,
        (SELECT id, name, point FROM developments) development
        WHERE ST_Intersects(point, rpa.shape)
        AND id = #{id};
    SQL
    self.update(rpa_poly_id: ActiveRecord::Base.connection.exec_query(rpa_query).to_hash[0]['objectid'])
  end

  def update_county
    return if counties_polym_id.present?
    counties_query = <<~SQL
      SELECT objectid
      FROM
        (SELECT objectid, ST_TRANSFORM(counties_polym.shape, 4326) as shape FROM counties_polym) county,
        (SELECT id, name, point FROM developments) development
        WHERE ST_Intersects(point, county.shape)
        AND id = #{id};
    SQL
    self.update(counties_polym_id: ActiveRecord::Base.connection.exec_query(counties_query).to_hash[0]['objectid'])
  end

  def update_municipality
    return if ma_municipalities_id.present?
    municipalities_query = <<~SQL
      SELECT objectid
      FROM
        (SELECT objectid, ST_TRANSFORM(ma_municipalities.shape, 4326) as shape FROM ma_municipalities) municipality,
        (SELECT id, name, point FROM developments) development
        WHERE ST_Intersects(point, county.shape)
        AND id = #{id};
    SQL
    self.update(ma_municipalities_id: ActiveRecord::Base.connection.exec_query(municipalities_query).to_hash[0]['objectid'])
  end
end
