class SentEmail < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :campaign_update
  belongs_to :comment
  belongs_to :problem
  belongs_to :recipient_in_current_generation, :polymorphic => true,
                                               :foreign_key => :recipient_id,
                                               :foreign_type => :recipient_type
  # One of the possible recipient types for a sent_email is an operator contact, which exists
  # in data generations. Models belonging to previous generations will not appear in the
  # recipient_in_current_generation association due to their default scope which specifies the
  # current generation, so retrieve them from any generation, and then check for a successor
  def recipient
    if recipient_in_current_generation
      return recipient_in_current_generation
    end
    data_generation_models = FixMyTransport::DataGenerations.models_existing_in_data_generations
    if data_generation_models.include?(recipient_model_class)
      found_recipient = nil
      recipient_model_class.in_any_generation do
        found_recipient = recipient_model_class.find(recipient_id)
      end
      if found_recipient
        if found_recipient.in_current_data_generation?
          return found_recipient
        else
          successor = self.recipient_model_class.find_successor(found_recipient.id)
          return successor if successor
        end
      end
    end
    raise "No recipient for sent_email #{self.id}"
  end

  def recipient_model_class
    self.recipient_type.constantize
  end

  def recipient=(new_value)
    self.recipient_in_current_generation = new_value
  end

end
