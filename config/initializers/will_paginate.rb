require 'lib/patches/will_paginate/admin_link_renderer'
WillPaginate::ViewHelpers.pagination_options[:renderer] = 'WillPaginate::AdminLinkRenderer'