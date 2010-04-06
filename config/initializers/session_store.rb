# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_fixmytransport_session',
  :secret      => '72bfeecefa25d2381d18872bcde2b713cd9d8938b30d1e2f3f67d50792722d2d198dcd56b91f68fdb3ab273198b2775fe788c884db29e41cee837c07438ba00f'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
