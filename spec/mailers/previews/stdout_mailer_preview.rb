# frozen_string_literal: true

class StdoutMailerPreview < ActionMailer::Preview
  def issue_0
    StdoutMailer.issue_zero(subscriber: User.first)
  end

  def issue_1
    StdoutMailer.issue_one(subscriber: User.first)
  end

  def issue_2
    StdoutMailer.issue_two(subscriber: User.first)
  end

  def issue_3
    StdoutMailer.issue_three(subscriber: User.first)
  end
end
