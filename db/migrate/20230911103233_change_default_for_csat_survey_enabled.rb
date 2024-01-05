class ChangeDefaultForCsatSurveyEnabled < ActiveRecord::Migration[7.0]
  def change
    change_column_default :inboxes, :csat_survey_enabled, from: false, to: true
  end
end
