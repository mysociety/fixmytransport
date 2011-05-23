ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(:standard => "%H:%M")
ActiveSupport::CoreExtensions::Date::Conversions::DATE_FORMATS.merge!(:standard => "%a, %d %b %Y")
ActiveSupport::CoreExtensions::Date::Conversions::DATE_FORMATS.merge!(:short => "%d %b %Y")