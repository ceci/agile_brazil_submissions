# encoding: UTF-8
class Conference < ActiveRecord::Base
  has_many :tracks
  has_many :audience_levels
  has_many :session_types

  def self.current
    order('year desc').first
  end

  def to_param
    year.to_s
  end

  def in_submission_phase?
    now = DateTime.now
    self.submissions_open <= now && now <= self.submissions_deadline
  end

  def has_early_review?
    self.prereview_deadline.present?
  end

  def in_early_review_phase?
    return false unless has_early_review?
    now = DateTime.now
    self.presubmissions_deadline <= now && now <= self.prereview_deadline
  end

  def in_final_review_phase?
    now = DateTime.now
    self.submissions_deadline <= now && now <= self.review_deadline
  end

  def in_author_confirmation_phase?
    now = DateTime.now
    self.author_notification <= now && now <= self.author_confirmation
  end

  def in_voting_phase?
    return false if self.voting_deadline.blank?
    DateTime.now <= self.voting_deadline
  end

  DEADLINES = [
    :call_for_papers,
    :submissions_open,
    :presubmissions_deadline,
    :prereview_deadline,
    :submissions_deadline,
    # :review_deadline, # Internal deadline
    :author_notification,
    :author_confirmation
  ]

  def dates
    @dates ||= to_deadlines(DEADLINES)
  end

  def next_deadline(role)
    now = DateTime.now
    deadlines_for(role).select{|deadline| now < deadline.first}.first
  end

  private
  def deadlines_for(role)
    deadlines = case role.to_sym
    when :author
      [:presubmissions_deadline, :submissions_deadline, :author_notification, :author_confirmation]
    when :reviewer
      [:prereview_deadline, :review_deadline]
    when :organizer, :all
      DEADLINES
    end
    to_deadlines(deadlines)
  end

  def to_deadlines(deadlines)
    deadlines.map { |name| send(name) ? [send(name), name] : nil}.compact
  end
end
