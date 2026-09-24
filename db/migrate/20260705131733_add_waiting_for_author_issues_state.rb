class AddWaitingForAuthorIssuesState < ActiveRecord::Migration[8.1]
  def up
    Issues::State.find_or_initialize_by(key: "waiting_for_author").tap do |state|
      state.name = "Čaká na autora"
    end.save!
  end

  def down
    Issues::State.find_by(key: "waiting_for_author")&.destroy
  end
end
