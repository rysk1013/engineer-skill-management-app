#!/usr/bin/env bash

set -euo pipefail

readonly TASKS_DIR="backlog/tasks"
readonly CANONICAL_BRANCH="dev"

TEMP_DIR=""

declare -a SYNC_TASK_FILES=()

log_info() {
  printf '[INFO] %s\n' "$*"
}

log_warn() {
  printf '[WARN] %s\n' "$*" >&2
}

log_error() {
  printf '[ERROR] %s\n' "$*" >&2
}

die() {
  log_error "$*"
  exit 1
}

cleanup() {
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}

require_command() {
  local command_name="$1"

  command -v "$command_name" >/dev/null 2>&1 \
    || die "Required command not found: ${command_name}"
}

is_zero_sha() {
  local sha="$1"

  [[ "$sha" =~ ^0+$ ]]
}

resolve_diff_base() {
  local merge_base

  if ! is_zero_sha "$BEFORE_SHA"; then
    printf '%s' "$BEFORE_SHA"
    return 0
  fi

  log_info "Initial branch push detected" >&2

  git rev-parse --verify "origin/${CANONICAL_BRANCH}" \
    >/dev/null 2>&1 \
    || die "Remote canonical branch not found: origin/${CANONICAL_BRANCH}"

  merge_base="$(
    git merge-base \
      "origin/${CANONICAL_BRANCH}" \
      "$AFTER_SHA"
  )"

  [[ -n "$merge_base" ]] \
    || die "Failed to determine merge base with origin/${CANONICAL_BRANCH}"

  log_info "Using merge base with origin/${CANONICAL_BRANCH}: ${merge_base}" >&2

  printf '%s' "$merge_base"
}


collect_tasks() {
  find "$TASKS_DIR" \
    -maxdepth 1 \
    -type f \
    -name '*.md' \
    -print0 |
    sort -z
}

collect_changed_tasks() {
  local status
  local old_file
  local new_file
  local diff_base

  diff_base="$(resolve_diff_base)"

  while IFS= read -r -d '' status; do
    case "$status" in
      A | M)
        IFS= read -r -d '' old_file

        printf '%s\0' "$old_file"
        ;;

      D)
        IFS= read -r -d '' old_file

        log_warn "Deleted task file detected; corresponding GitHub Issue will not be modified: ${old_file}"
        ;;

      R*)
        IFS= read -r -d '' old_file
        IFS= read -r -d '' new_file

        printf '%s\0' "$new_file"
        ;;

      *)
        die "Unsupported Git change status: ${status}"
        ;;
    esac
  done < <(
    git diff \
      --name-status \
      --find-renames \
      -z \
      "$diff_base" \
      "$AFTER_SHA" \
      -- "$TASKS_DIR"
  )
}

extract_frontmatter() {
  local task_file="$1"

  awk '
    NR == 1 && $0 == "---" {
      in_frontmatter = 1
      next
    }

    in_frontmatter && $0 == "---" {
      exit
    }

    in_frontmatter {
      print
    }
  ' "$task_file"
}

extract_task_body() {
  local task_file="$1"

  awk '
    NR == 1 && $0 == "---" {
      in_frontmatter = 1
      next
    }

    in_frontmatter && $0 == "---" {
      in_frontmatter = 0
      next
    }

    !in_frontmatter {
      print
    }
  ' "$task_file"
}

get_array_display_value() {
  local task_file="$1"
  local expression="$2"
  local value

  value="$(
    extract_frontmatter "$task_file" |
      yq -r "${expression} | join(\", \")"
  )"

  if [[ -z "$value" ]]; then
    printf 'None'
  else
    printf '%s' "$value"
  fi
}

get_frontmatter_value() {
  local task_file="$1"
  local expression="$2"

  extract_frontmatter "$task_file" |
    yq -r "$expression"
}

get_status_label() {
  local status="$1"

  case "$status" in
    "To Do")
      printf 'status:todo'
      ;;

    "In Progress")
      printf 'status:in-progress'
      ;;

    "Done")
      printf 'status:done'
      ;;

    *)
      die "Unsupported status: ${status}"
      ;;
  esac
}

validate_environment() {
  require_command git
  require_command gh
  require_command yq

  [[ -d "$TASKS_DIR" ]] \
    || die "Backlog tasks directory not found: ${TASKS_DIR}"

  [[ -n "${SYNC_MODE:-}" ]] \
    || die "SYNC_MODE is required"

  case "$SYNC_MODE" in
    changed | full)
      ;;

    *)
      die "Unsupported sync mode: ${SYNC_MODE}"
      ;;
  esac

  if [[ "$SYNC_MODE" == "changed" ]]; then
    [[ -n "${BEFORE_SHA:-}" ]] \
      || die "BEFORE_SHA is required when SYNC_MODE=changed"

    [[ -n "${AFTER_SHA:-}" ]] \
      || die "AFTER_SHA is required when SYNC_MODE=changed"

    git cat-file -e "${AFTER_SHA}^{commit}" 2>/dev/null \
      || die "AFTER_SHA is not a valid commit: ${AFTER_SHA}"

    if ! is_zero_sha "$BEFORE_SHA"; then
      git cat-file -e "${BEFORE_SHA}^{commit}" 2>/dev/null \
        || die "BEFORE_SHA is not a valid commit: ${BEFORE_SHA}"
    fi
  fi

  [[ -n "${GH_TOKEN:-}" ]] \
    || die "GH_TOKEN is required"

  [[ -n "${GH_REPO:-}" ]] \
    || die "GH_REPO is required"
}

validate_task() {
  local task_file="$1"
  local task_id
  local title
  local status
  local priority
  local labels_type
  local assignee_type
  local dependencies_type
  local created_date

  task_id="$(get_frontmatter_value "$task_file" '.id')"
  title="$(get_frontmatter_value "$task_file" '.title')"
  status="$(get_frontmatter_value "$task_file" '.status')"
  priority="$(get_frontmatter_value "$task_file" '.priority')"
  labels_type="$(get_frontmatter_value "$task_file" '.labels | type')"
  assignee_type="$(get_frontmatter_value "$task_file" '.assignee | type')"
  dependencies_type="$(get_frontmatter_value "$task_file" '.dependencies | type')"
  created_date="$(get_frontmatter_value "$task_file" '.created_date')"

  [[ -n "$task_id" && "$task_id" != "null" ]] \
    || die "${task_file}: id is required"

  [[ "$task_id" =~ ^TASK-[0-9]+$ ]] \
    || die "${task_id}: invalid task ID"

  [[ -n "$title" && "$title" != "null" ]] \
    || die "${task_id}: title is required"

  case "$status" in
    "To Do" | "In Progress" | "Done")
      ;;
    *)
      die "${task_id}: unsupported status: ${status}"
      ;;
  esac

  case "$priority" in
    high | medium | low)
      ;;
    *)
      die "${task_id}: unsupported priority: ${priority}"
      ;;
  esac

  [[ "$labels_type" == "!!seq" ]] \
    || die "${task_id}: labels must be an array"

  [[ "$assignee_type" == "!!seq" ]] \
    || die "${task_id}: assignee must be an array"

  [[ "$dependencies_type" == "!!seq" ]] \
    || die "${task_id}: dependencies must be an array"

  [[ -n "$created_date" && "$created_date" != "null" ]] \
    || die "${task_id}: created_date is required"
}

validate_duplicate_task_ids() {
  local task_file
  local task_id
  local existing_task_id
  local -a task_ids=()

  while IFS= read -r -d '' task_file; do
    task_id="$(get_frontmatter_value "$task_file" '.id')"

    for existing_task_id in "${task_ids[@]}"; do
      if [[ "$existing_task_id" == "$task_id" ]]; then
        die "Duplicate task ID detected: ${task_id}"
      fi
    done

    task_ids+=("$task_id")
  done < <(collect_tasks)
}

validate_sync_tasks() {
  local task_file

  for task_file in "${SYNC_TASK_FILES[@]}"; do
    [[ -f "$task_file" ]] \
      || die "Task file not found: ${task_file}"

    validate_task "$task_file"
  done

  log_info "Validated ${#SYNC_TASK_FILES[@]} task(s) for synchronization"
}

resolve_sync_tasks() {
  local task_file

  SYNC_TASK_FILES=()

  case "$SYNC_MODE" in
    full)
      while IFS= read -r -d '' task_file; do
        SYNC_TASK_FILES+=("$task_file")
      done < <(collect_tasks)
      ;;

    changed)
      while IFS= read -r -d '' task_file; do
        SYNC_TASK_FILES+=("$task_file")
      done < <(collect_changed_tasks)
      ;;
  esac

  log_info "Resolved ${#SYNC_TASK_FILES[@]} task(s) for synchronization"
}

build_issue_marker() {
  local task_id="$1"

  printf '<!-- backlog-task-id: %s -->' "$task_id"
}

build_issue_title() {
  local task_file="$1"
  local task_id
  local title

  task_id="$(get_frontmatter_value "$task_file" '.id')"
  title="$(get_frontmatter_value "$task_file" '.title')"

  printf '[%s] %s' "$task_id" "$title"
}

find_issue_numbers() {
  local task_id="$1"
  local marker

  marker="$(build_issue_marker "$task_id")"

  gh issue list \
    --repo "$GH_REPO" \
    --state all \
    --limit 1000 \
    --json number,body \
    --jq ".[] | select(.body != null and (.body | contains(\"${marker}\"))) | .number"
}

generate_issue_body() {
  local task_file="$1"
  local output_file="$2"

  local task_id
  local status
  local priority
  local assignee
  local dependencies
  local created_date
  local milestone

  task_id="$(get_frontmatter_value "$task_file" '.id')"
  status="$(get_frontmatter_value "$task_file" '.status')"
  priority="$(get_frontmatter_value "$task_file" '.priority')"
  created_date="$(get_frontmatter_value "$task_file" '.created_date')"

  assignee="$(get_array_display_value "$task_file" '.assignee')"
  dependencies="$(get_array_display_value "$task_file" '.dependencies')"

  milestone="$(get_frontmatter_value "$task_file" '.milestone')"
  if [[ -z "$milestone" || "$milestone" == "null" ]]; then
    milestone="None"
  fi

  {
    printf '## Metadata\n\n'
    printf '| Field | Value |\n'
    printf '| --- | --- |\n'
    printf '| Task ID | %s |\n' "$task_id"
    printf '| Status | %s |\n' "$status"
    printf '| Priority | %s |\n' "$priority"
    printf '| Milestone | %s |\n' "$milestone"
    printf '| Assignee | %s |\n' "$assignee"
    printf '| Dependencies | %s |\n' "$dependencies"
    printf '| Created | %s |\n' "$created_date"
    printf '\n'

    extract_task_body "$task_file"

    printf '\n---\n\n'
    printf '<!-- backlog-task-id: %s -->\n\n' "$task_id"
    printf '> This issue is synchronized from Backlog.md.\n'
    printf '> Update task information in Backlog.md instead of editing this issue directly.\n'
  } >"$output_file"
}

create_issue() {
  local task_file="$1"
  local task_id
  local issue_title
  local body_file
  local issue_url
  local issue_number

  task_id="$(get_frontmatter_value "$task_file" '.id')"
  issue_title="$(build_issue_title "$task_file")"
  body_file="${TEMP_DIR}/${task_id}-body.md"

  generate_issue_body "$task_file" "$body_file"

  issue_url="$(
    gh issue create \
      --repo "$GH_REPO" \
      --title "$issue_title" \
      --body-file "$body_file"
  )"

  issue_number="${issue_url##*/}"

  [[ "$issue_number" =~ ^[0-9]+$ ]] \
    || die "${task_id}: Failed to determine created Issue number"

  log_info "${task_id}: Created GitHub Issue #${issue_number}" >&2

  printf '%s' "$issue_number"
}

update_issue() {
  local task_file="$1"
  local issue_number="$2"

  local task_id
  local issue_title
  local body_file

  task_id="$(get_frontmatter_value "$task_file" '.id')"
  issue_title="$(build_issue_title "$task_file")"
  body_file="${TEMP_DIR}/${task_id}-body.md"

  generate_issue_body "$task_file" "$body_file"

  gh issue edit "$issue_number" \
    --repo "$GH_REPO" \
    --title "$issue_title" \
    --body-file "$body_file" \
    >/dev/null

  log_info "${task_id}: Updated GitHub Issue #${issue_number}"
}

collect_issue_labels() {
  local task_file="$1"
  local status
  local priority
  local label

  status="$(get_frontmatter_value "$task_file" '.status')"
  priority="$(get_frontmatter_value "$task_file" '.priority')"

  printf 'backlog\0'
  printf 'priority:%s\0' "$priority"
  printf '%s\0' "$(get_status_label "$status")"

  while IFS= read -r label; do
    [[ -n "$label" ]] || continue
    printf '%s\0' "$label"
  done < <(
    extract_frontmatter "$task_file" |
      yq -r '.labels[]'
  )
}

ensure_label_exists() {
  local label="$1"

  if gh label list \
    --repo "$GH_REPO" \
    --limit 1000 \
    --json name \
    --jq '.[].name' |
    grep -Fxq "$label"; then
    return 0
  fi

  gh label create "$label" \
    --repo "$GH_REPO" \
    >/dev/null

  log_info "Created GitHub label: ${label}"
}

ensure_issue_labels_exist() {
  local task_file="$1"
  local label

  while IFS= read -r -d '' label; do
    ensure_label_exists "$label"
  done < <(collect_issue_labels "$task_file")
}

collect_current_issue_labels() {
  local issue_number="$1"

  gh issue view "$issue_number" \
    --repo "$GH_REPO" \
    --json labels \
    --jq '.labels[].name'
}

sync_issue_labels() {
  local task_file="$1"
  local issue_number="$2"

  local label
  local -a desired_labels=()
  local -a current_labels=()

  while IFS= read -r -d '' label; do
    desired_labels+=("$label")
  done < <(collect_issue_labels "$task_file")

  while IFS= read -r label; do
    [[ -n "$label" ]] || continue
    current_labels+=("$label")
  done < <(collect_current_issue_labels "$issue_number")

  for label in "${current_labels[@]}"; do
    if ! printf '%s\n' "${desired_labels[@]}" | grep -Fxq "$label"; then
      gh issue edit "$issue_number" \
        --repo "$GH_REPO" \
        --remove-label "$label" \
        >/dev/null
    fi
  done

  for label in "${desired_labels[@]}"; do
    if ! printf '%s\n' "${current_labels[@]:-}" | grep -Fxq "$label"; then
      gh issue edit "$issue_number" \
        --repo "$GH_REPO" \
        --add-label "$label" \
        >/dev/null
    fi
  done
}

get_issue_state() {
  local issue_number="$1"

  gh issue view "$issue_number" \
    --repo "$GH_REPO" \
    --json state \
    --jq '.state'
}

get_expected_issue_state() {
  local status="$1"

  case "$status" in
    "To Do" | "In Progress")
      printf 'OPEN'
      ;;

    "Done")
      printf 'CLOSED'
      ;;

    *)
      die "Unsupported status: ${status}"
      ;;
  esac
}

sync_issue_state() {
  local task_file="$1"
  local issue_number="$2"

  local task_id
  local status
  local current_state
  local expected_state

  task_id="$(get_frontmatter_value "$task_file" '.id')"
  status="$(get_frontmatter_value "$task_file" '.status')"

  current_state="$(get_issue_state "$issue_number")"
  expected_state="$(get_expected_issue_state "$status")"

  if [[ "$current_state" == "$expected_state" ]]; then
    log_info "${task_id}: Issue state already ${expected_state}"
    return 0
  fi

  case "$expected_state" in
    OPEN)
      gh issue reopen "$issue_number" \
        --repo "$GH_REPO" \
        >/dev/null

      log_info "${task_id}: Reopened GitHub Issue #${issue_number}"
      ;;

    CLOSED)
      gh issue close "$issue_number" \
        --repo "$GH_REPO" \
        >/dev/null

      log_info "${task_id}: Closed GitHub Issue #${issue_number}"
      ;;

    *)
      die "${task_id}: Unsupported expected Issue state: ${expected_state}"
      ;;
  esac
}

sync_task() {
  local task_file="$1"
  local task_id
  local issue_number
  local issue_count

  task_id="$(get_frontmatter_value "$task_file" '.id')"

  issue_number=""
  issue_count=0

  while IFS= read -r number; do
    [[ -n "$number" ]] || continue

    issue_number="$number"
    ((issue_count += 1))
  done < <(find_issue_numbers "$task_id")

  case "$issue_count" in
    0)
      ensure_issue_labels_exist "$task_file"
      issue_number="$(create_issue "$task_file")"
      ;;

    1)
      log_info "${task_id}: Existing GitHub Issue #${issue_number} found"

      ensure_issue_labels_exist "$task_file"
      update_issue "$task_file" "$issue_number"
      ;;

    *)
      die "${task_id}: Multiple GitHub Issues found"
      ;;
  esac

  sync_issue_labels "$task_file" "$issue_number"

  log_info "${task_id}: Labels synchronized"

  sync_issue_state "$task_file" "$issue_number"
}

sync_tasks() {
  local task_file

  for task_file in "${SYNC_TASK_FILES[@]}"; do
    sync_task "$task_file"
  done
}

main() {
  log_info "Starting Backlog → GitHub Issues synchronization"

  TEMP_DIR="$(mktemp -d)"
  trap cleanup EXIT

  validate_environment

  log_info "Sync mode: ${SYNC_MODE}"
  log_info "Environment validation passed"

  resolve_sync_tasks

  if ((${#SYNC_TASK_FILES[@]} == 0)); then
    log_info "No backlog tasks to synchronize"
    return 0
  fi

  validate_sync_tasks
  validate_duplicate_task_ids

  log_info "Validation passed"

  sync_tasks

  log_info "Synchronization completed"
}

main "$@"
