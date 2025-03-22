class AddHistoryFetchColumnsToChannelEmail < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_email, :history_fetched, :boolean, default: false
    add_column :channel_email, :history_fetched_at, :datetime
    add_column :channel_email, :history_fetched_days, :integer
  end
end
