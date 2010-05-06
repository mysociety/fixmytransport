require 'xml'

class Parsers::NptgParser

  def initialize
  end
  
  def csv_options
    { :quote_char => '"', 
      :col_sep => ",", 
      :row_sep =>:auto, 
      :return_headers => false,
      :headers => :first_row,
      :encoding => 'N' }
  end
  
  def convert_encoding filepath
    Iconv.iconv('utf-8', 'ISO_8859-1', File.read(filepath)).join
  end

  def parse_regions filepath
    csv_data = convert_encoding(filepath)
     FasterCSV.parse(csv_data, csv_options) do |row|
       next if row['Modification'] == 'del'
       yield Region.new(:code =>                  row['RegionCode'],
                        :name =>                  row['RegionName'], 
                        :creation_datetime =>     row["CreationDateTime"],
                        :modification_datetime => row["ModificationDateTime"],
                        :revision_number =>       row["RevisionNumber"],
                        :modification =>          row["Modification"])
     end
  end
  
  def parse_admin_areas filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      next if row['Modification'] == 'del'
      region = Region.find_by_code(row['RegionCode'])
      yield AdminArea.new(:code =>                  row['AdministrativeAreaCode'],
                          :atco_code =>             row['AtcoAreaCode'], 
                          :name =>                  row['AreaName'], 
                          :short_name =>            row['ShortName'], 
                          :country =>               row['Country'], 
                          :region =>                region, 
                          :national =>              row['National'], 
                          :contact_email =>         row["ContactEmail"],
                          :contact_telephone =>     row["ContactTelephone"],
                          :creation_datetime =>     row["CreationDateTime"],
                          :modification_datetime => row["ModificationDateTime"],
                          :revision_number =>       row["RevisionNumber"],
                          :modification =>          row["Modification"])
    end
  end
  
  
  def parse_districts filepath
    csv_data = convert_encoding(filepath)
     FasterCSV.parse(csv_data, csv_options) do |row|
       next if row['Modification'] == 'del'
       admin_area = AdminArea.find_by_code(row['AdministrativeAreaCode'])
       yield District.new(:code =>                  row['DistrictCode'],
                          :name =>                  row['DistrictName'], 
                          :admin_area =>            admin_area, 
                          :creation_datetime =>     row["CreationDateTime"],
                          :modification_datetime => row["ModificationDateTime"],
                          :revision_number =>       row["RevisionNumber"],
                          :modification =>          row["Modification"])
     end
  end
  
  def parse_localities filepath
    csv_data = convert_encoding(filepath)
    spatial_extensions = MySociety::Config.getbool('USE_SPATIAL_EXTENSIONS', false) 
    FasterCSV.parse(csv_data, csv_options) do |row|
      next if row['Modification'] == 'del'
      if spatial_extensions
        coords = Point.from_x_y(row['Easting'], row['Northing'], BRITISH_NATIONAL_GRID)
      else
        coords = nil
      end
      admin_area = AdminArea.find_by_code(row['AdministrativeAreaCode'])
      district = District.find_by_code(row['NptgDistrictCode'])
      yield Locality.new(:code                      => row['NptgLocalityCode'],
                         :name                      => row['LocalityName'], 
                         :short_name                => row['ShortName'], 
                         :qualifier_name            => row['QualifierName'], 
                         :qualifier_locality        => row['QualifierLocalityRef'], 
                         :qualifier_district        => row['QualifierDistrictRef'], 
                         :admin_area                => admin_area, 
                         :district                  => district, 
                         :source_locality_type      => row['SourceLocalityType'], 
                         :grid_type                 => row['GridType'], 
                         :easting                   => row['Easting'],
                         :northing                  => row['Northing'],
                         :coords                    => coords,
                         :creation_datetime         => row['CreationDateTime'],
                         :modification_datetime     => row['ModificationDateTime'],
                         :revision_number           => row['RevisionNumber'],
                         :modification              => row['Modification'])
    end
  end
  
  def parse_locality_hierarchy filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      next if row['Modification'] == 'del'
      ancestor = Locality.find_by_code(row['ParentNptgLocalityCode'])
      descendant = Locality.find_by_code(row['ChildNptgLocalityCode'])
      yield LocalityLink.build_edge(ancestor, descendant)
    end
  end
  
  def parse_locality_alternative_names filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      next if row['Modification'] == 'del'
      locality = Locality.find_by_code(row['NptgLocalityCode'])
      yield AlternativeName.new(:name                  => row['LocalityName'],
                                :locality              => locality, 
                                :short_name            => row['ShortName'], 
                                :qualifier_name        => row['QualifierName'], 
                                :qualifier_locality    => row['QualifierLocalityRef'], 
                                :qualifier_district    => row['QualifierDistrictRef'],   
                                :creation_datetime     => row['CreationDateTime'],
                                :modification_datetime => row['ModificationDateTime'],
                                :revision_number       => row['RevisionNumber'],
                                :modification          => row['Modification'])
    end
  end
end