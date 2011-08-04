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
       yield Region.new(:code =>                  (row['RegionCode'] or row['Traveline Region ID']),
                        :name =>                  (row['RegionName'] or row['Region Name']),
                        :creation_datetime =>     (row["CreationDateTime"] or row['Date of Issue']),
                        :modification_datetime => row["ModificationDateTime"],
                        :revision_number =>       (row["RevisionNumber"] or row['Issue Version']),
                        :modification =>          row["Modification"])
     end
  end

  def parse_admin_areas filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      region = Region.find_by_code((row['RegionCode'] or row['Traveline Region ID']))
      yield AdminArea.new(:code =>                  (row['AdministrativeAreaCode'] or row['Admin Area ID']),
                          :atco_code =>             (row['AtcoAreaCode'] or row['ATCO Code']),
                          :name =>                  (row['AreaName'] or row['Admin Area Name']),
                          :short_name =>            row['ShortName'],
                          :country =>               row['Country'],
                          :region =>                region,
                          :national =>              row['National'],
                          :creation_datetime =>     (row["CreationDateTime"] or row['Date of Issue']),
                          :modification_datetime => row["ModificationDateTime"],
                          :revision_number =>       (row["RevisionNumber"] or row['Issue Version']),
                          :modification =>          row["Modification"])
    end
  end


  def parse_districts filepath
    csv_data = convert_encoding(filepath)
     FasterCSV.parse(csv_data, csv_options) do |row|
       admin_area = AdminArea.find_by_code(row['AdministrativeAreaCode'])
       yield District.new(:code =>                  (row['DistrictCode'] or row['District ID']),
                          :name =>                  (row['DistrictName'] or row['District Name']),
                          :admin_area =>            admin_area,
                          :creation_datetime =>     (row["CreationDateTime"] or row['Date of Issue']),
                          :modification_datetime => row["ModificationDateTime"],
                          :revision_number =>       (row["RevisionNumber"] or row['Issue Version']),
                          :modification =>          row["Modification"])
     end
  end

  def parse_localities filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      admin_area = AdminArea.find_by_code((row['AdministrativeAreaCode'] or row['Admin Area ID']))
      district = District.find_by_code((row['NptgDistrictCode'] or row['District ID']))
      coords = Point.from_x_y(row['Easting'], row['Northing'], BRITISH_NATIONAL_GRID)
      yield Locality.new(:code                      => (row['NptgLocalityCode'] or row['National Gazetteer ID']),
                         :name                      => (row['LocalityName'] or row['Locality Name']),
                         :short_name                => row['ShortName'],
                         :qualifier_name            => row['QualifierName'],
                         :admin_area                => admin_area,
                         :district                  => district,
                         :source_locality_type      => (row['SourceLocalityType'] or row['LocalityType']),
                         :grid_type                 => row['GridType'],
                         :easting                   => row['Easting'],
                         :northing                  => row['Northing'],
                         :coords                    => coords,
                         :creation_datetime         => (row["CreationDateTime"] or row['Date of Issue']),
                         :modification_datetime     => (row['ModificationDateTime'] or row['Date of Last Change']),
                         :revision_number           => (row["RevisionNumber"] or row['Issue Version']),
                         :modification              => row['Modification'])
    end
  end

  def parse_locality_hierarchy filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      ancestor = Locality.find_by_code((row['ParentNptgLocalityCode'] or row['Parent ID']))
      descendant = Locality.find_by_code((row['ChildNptgLocalityCode'] or row['Child ID']))
      yield LocalityLink.build_edge(ancestor, descendant)
    end
  end

  def parse_locality_alternative_names filepath
    csv_data = convert_encoding(filepath)
    FasterCSV.parse(csv_data, csv_options) do |row|
      locality = Locality.find_by_code((row['NptgLocalityCode'] or row['Primary ID']))
      alternative_locality = Locality.find_by_code(row['Alternate ID'])
      yield AlternativeName.new(:alternative_locality    => alternative_locality,
                                :locality                => locality,
                                :creation_datetime       => (row['CreationDateTime'] or row['Date of Issue']),
                                :modification_datetime   => (row['ModificationDateTime'] or row['Date of Last Change']),
                                :revision_number         => (row['RevisionNumber'] or row['Issue Version']) ,
                                :modification            => row['Modification'])
    end
  end
end