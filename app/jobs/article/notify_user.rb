class Article::NotifyUser < ApplicationJob
  queue_as :default

  def perform(article)
    Account.find_each do |account|
      account.users.each do |user|
        user.notifications.create(
          notification_type: 'article_creation',
          account: account,
          primary_actor: article
        )
      end
    end
  end
end
