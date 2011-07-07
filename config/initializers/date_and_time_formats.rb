ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(:standard => "%H:%M")
ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(:standard_with_date => "%H:%M %d %b %Y")
ActiveSupport::CoreExtensions::Date::Conversions::DATE_FORMATS.merge!(:standard => "%a, %d %b %Y")
ActiveSupport::CoreExtensions::Date::Conversions::DATE_FORMATS.merge!(:short => "%d %b %Y")