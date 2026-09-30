# Testing guide

How we decide what to test and at which level. New features should follow this
so coverage stays meaningful instead of just high.

Run everything with `bin/rails test:all`. Coverage is measured by
SimpleCov on every run and written to `coverage/index.html`. Running `test`
and `test:system` separately merges into one report.

## Levels

### User-facing flows: system tests (`test/system`)

Anything a citizen or a responsible subject does in the browser is covered end
to end with Capybara: log in, click, fill, submit, assert what the page shows
and what changed in the database. This is the primary place for controller
logic. We do not write separate controller tests for HTML controllers; the
system test already exercises them and a controller test would duplicate it.

A system test asserts:
- what the user sees (text, buttons that appear or disappear, error messages),
- the resulting state (issue state, records created),
- that side-effect jobs were enqueued (`assert_enqueued_with`), not what they do.

### APIs and webhooks: integration tests (`test/controllers`)

JSON APIs and inbound webhooks have no browser, so they are tested with
`ActionDispatch::IntegrationTest`. For an API endpoint we assert the response
status and that the body matches the expected schema (keys and value types),
not just that it is `200`. For a webhook we assert authentication failures and
that the right job was enqueued with the right arguments.

Endpoints that only redirect (the legacy URL redirects) are tested here too,
with `assert_redirected_to` on the exact target and `assert_response
:not_found` where the source record is missing. A system test would only
prove that the browser followed the redirect to a page other tests already
cover, and it cannot assert the status code.

### Models: unit tests (`test/models`)

Test our own logic, not the framework. Skip plain `validates :x, presence:
true`. Do test:
- conditional validations (`if:`, `unless:`, `on:` contexts),
- conditional callbacks and what they enqueue,
- query methods, scopes and predicates with branching (`resolved?`,
  `editable_by?`, `should_create_resolution_process?`),
- anything with a computation.

### Jobs: unit tests (`test/jobs`)

Each job has its own test file that performs it and asserts the outcome. The
caller (model callback, controller, another job) only asserts the job was
enqueued with the expected arguments. That keeps the job's behaviour tested in
exactly one place.

A job that sends mail is no different: it asserts the delivery was enqueued
with `assert_enqueued_email_with` / `assert_no_enqueued_emails` (include
`ActionMailer::TestHelper`), it does not mock the mailer. What the mail
contains is the mailer test's job.

### Mailers: (`test/mailers`)

Each mail method renders once: recipients, subject, key body content, and the
unsubscribe headers where they apply.

## External services

We never call Zammad, Discourse, Gemini, Nominatim or Overpass from tests.
`WebMock` blocks all outbound HTTP (`test_helper.rb`). Stub the exact request
with `stub_request` and a JSON fixture under `test/fixtures/files/webmock/`,
then assert the request was made with `assert_requested` when the request
itself is the point of the test.

## Conventions

- Fixtures live in `test/fixtures`. Prefer adding a fixture over building
  records inline when more than one test needs it.
- Keep a test focused on one flow. Several short tests beat one long one.
- Text assertions use the Slovak strings the user actually sees.
- Login helpers: `login_as` / `login` (password, citizens) and
  `login_via_magic_link` (responsible subjects) in `test/test_helpers/auth_helper.rb`.
