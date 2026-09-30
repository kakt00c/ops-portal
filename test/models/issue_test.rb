require "test_helper"

class IssueTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "is invalid without a municipality" do
    issue = Issue.new(title: "Test issue title", description: "Test issue description that is long enough", category: issues_categories(:one), state: issues_states(:waiting))
    assert_not issue.valid?
    assert_includes issue.errors[:municipality], "musí existovať"
  end

  test "is valid with a municipality" do
    issue = Issue.new(title: "Test issue title", description: "Test issue description that is long enough", category: issues_categories(:one), state: issues_states(:waiting), municipality: municipalities(:trencin), photos: [ active_storage_blobs(:issue_photo) ])
    assert issue.valid?
  end

  test "requires a photo unless imported or a praise" do
    issue = issues(:one)
    issue.photos = []
    assert_not issue.valid?
    assert_includes issue.errors[:photos], "sú povinné. Nahrajte aspoň jednu."

    issue.imported_at = Time.current
    assert issue.valid?

    praise = issues(:praise_waiting)
    assert_empty praise.photos
    assert praise.valid?
  end

  # visibility and editability

  test "issues in private states are visible only to their author" do
    issue = issues(:resolved_private)
    assert_not issue.viewable_by?(users(:two))
    assert_not issue.viewable_by?(AnonymousUser.new)

    issue.update_columns(author_id: users(:two).id)
    assert issue.viewable_by?(users(:two))
  end

  test "only the author can edit and only while the issue is waiting" do
    issue = issues(:one) # waiting, author users(:one)
    assert issue.editable_by?(users(:one))
    assert_not issue.editable_by?(users(:two))

    issue.update_columns(state_id: issues_states(:in_progress).id)
    assert_not issue.reload.editable_by?(users(:one))
  end

  test "state predicates" do
    issue = issues(:one)
    assert_not issue.resolved?
    assert_not issue.duplicate?
    assert_not issue.archived?

    issue.state = issues_states(:resolved_private)
    assert issue.resolved?

    issue.state = issues_states(:duplicate)
    assert issue.duplicate?
  end

  test "issue is archived when its municipality or responsible subject is archived" do
    issue = issues(:legacy1)
    assert_not issue.archived?

    issue.responsible_subject = responsible_subjects(:archived)
    assert issue.archived?

    issue.responsible_subject = responsible_subjects(:one)
    issue.municipality.archived = true
    assert issue.archived?
  end

  test "resolution process should be created only once for an issue sent to a responsible subject" do
    issue = issues(:without_triage_external_id)
    issue.state = issues_states(:sent_to_responsible)
    assert issue.should_create_resolution_process?

    issue.responsible_subject = nil
    assert_not issue.should_create_resolution_process?

    issue.responsible_subject = responsible_subjects(:one)
    issue.resolution_external_id = 99
    assert_not issue.should_create_resolution_process?, "already in resolution process"

    praise = issues(:praise_waiting)
    praise.state = issues_states(:sent_to_responsible)
    praise.responsible_subject = responsible_subjects(:one)
    assert_not praise.should_create_resolution_process?
  end

  test "rejection note is created in triage only when the state changed to rejected" do
    issue = issues(:one)
    issue.update!(state: issues_states(:rejected))
    assert issue.should_create_rejection_note_in_triage?

    issue.update!(title: "Changed title only")
    assert_not issue.should_create_rejection_note_in_triage?

    praise = issues(:praise_waiting)
    praise.update!(state: issues_states(:rejected))
    assert_not praise.should_create_rejection_note_in_triage?
  end

  # notifications (after_update :notify_subscribers)

  test "state change enqueues state changed notification" do
    issue = issues(:one)
    from = issue.state_id
    to = issues_states(:resolved).id

    assert_enqueued_with(job: Notifications::PublishIssueStateChangedJob, args: [ issue, { state_id_change: [ from, to ] } ]) do
      issue.update!(state_id: to)
    end
  end

  test "entering resolution process enqueues accepted notification" do
    issue = issues(:without_triage_external_id)

    assert_enqueued_with(job: Notifications::PublishIssueAcceptedJob, args: [ issue ]) do
      issue.update!(resolution_external_id: 77)
    end
  end

  test "change without state or resolution process change enqueues nothing" do
    assert_no_enqueued_jobs do
      issues(:one).update!(title: "Changed title only")
    end
  end

  test "praise accepted from waiting enqueues accepted notification" do
    praise = issues(:praise_waiting)

    assert_enqueued_with(job: Notifications::PublishIssueAcceptedJob, args: [ praise ]) do
      praise.update!(state: issues_states(:resolved))
    end
  end

  test "praise rejected from waiting enqueues state changed notification" do
    praise = issues(:praise_waiting)

    assert_enqueued_with(job: Notifications::PublishIssueStateChangedJob) do
      praise.update!(state: issues_states(:rejected))
    end
  end

  test "praise state change not from waiting enqueues nothing" do
    praise = issues(:praise_published) # in_progress

    assert_no_enqueued_jobs do
      praise.update!(state: issues_states(:resolved))
    end
  end
end
