class Admin::AdminController < ApplicationController
  protect_from_forgery
  layout "admin" 
  skip_before_filter :require_beta_password
end