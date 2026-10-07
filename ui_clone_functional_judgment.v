module vui_evidence

pub struct UiCloneFunctionalJudgmentRow {
pub:
	visual_region              string
	visual_component           string
	functional_region          string
	functional_component       string
	equality_target            string
	visual_anchor_subject      string
	equalized_subject          string
	excluded_literal_subject   string
	clone_reasoning_mode       string
	visual_role                string
	functional_role            string
	atomic_parity_contract     string
	runtime_evidence_contract  string
	literal_copy_blocker       string
	visual_locus_rule          string
	functional_question        string
	expected_state_delta       string
	function_understood        bool
	visual_locus_understood    bool
	dynamic_text_masked        bool
	compare_literal_text       bool
	required_behavior_probes   []string
	behavior_evidence_required int
	behavior_evidence_passed   int
	behavior_evidence_failed   int
	behavior_evidence_missing  int
	evidence_classes           []string
	evidence_sources           []string
	matched_signal_ids         []string
	visual_only_rejected       bool
	nonblind_reasoning         bool
	coverage_percent           int
	verdict                    string
	decision_reason            string
	next_required_evidence     []string
	text_policy                string
}

pub struct UiCloneFunctionalJudgment {
pub:
	visual_profile                 string
	functional_profile             string
	clone_intent                   string
	mode                           string
	cross_profile                  bool
	ready                          bool
	blocker                        string
	blind_risk                     string
	functional_subject_explicit    bool
	visual_subject                 string
	functional_subject             string
	functional_coverage_percent    int
	row_count                      int
	understood_row_count           int
	certified_row_count            int
	pending_row_count              int
	failed_row_count               int
	visual_only_rejected_row_count int
	dynamic_text_masked_row_count  int
	behavior_evidence_required     int
	behavior_evidence_passed       int
	behavior_evidence_failed       int
	behavior_evidence_missing      int
	clone_claim_allowed            bool
	literal_text_can_certify       bool
	visual_only_can_certify        bool
	decision_rule                  string
	rows                           []UiCloneFunctionalJudgmentRow
}

pub fn ui_clone_functional_judgment(input UiCloneSubjectInput,
	signals []UiCloneRuntimeSignal) UiCloneFunctionalJudgment {
	ledger := ui_clone_functional_clone_evidence_ledger(input, signals)
	return ui_clone_functional_judgment_from_ledger(ledger)
}

pub fn ui_clone_functional_judgment_from_probe_evidence(input UiCloneSubjectInput,
	receipts []UiCloneBehaviorProbeEvidenceReceipt) UiCloneFunctionalJudgment {
	ledger := ui_clone_functional_clone_evidence_ledger_from_probe_evidence(input, receipts)
	return ui_clone_functional_judgment_from_ledger(ledger)
}

pub fn ui_clone_functional_judgment_from_ledger(ledger UiCloneFunctionalCloneEvidenceLedger) UiCloneFunctionalJudgment {
	mut rows := []UiCloneFunctionalJudgmentRow{}
	for row in ledger.rows {
		rows << ui_clone_functional_judgment_row(row)
	}
	coverage := ui_clone_functional_judgment_coverage(rows)
	allowed := ledger.ready && rows.len > 0 && coverage == 100
		&& ui_clone_functional_judgment_certified_count(rows) == rows.len
	return UiCloneFunctionalJudgment{
		visual_profile:                 ledger.visual_profile
		functional_profile:             ledger.functional_profile
		clone_intent:                   ledger.clone_intent
		mode:                           ledger.mode
		cross_profile:                  ledger.cross_profile
		ready:                          allowed
		blocker:                        ui_clone_functional_judgment_blocker(ledger, rows,
			coverage, allowed)
		blind_risk:                     ledger.blind_risk
		functional_subject_explicit:    ledger.functional_subject_explicit
		visual_subject:                 ledger.visual_subject
		functional_subject:             ledger.functional_subject
		functional_coverage_percent:    coverage
		row_count:                      rows.len
		understood_row_count:           ui_clone_functional_judgment_understood_count(rows)
		certified_row_count:            ui_clone_functional_judgment_certified_count(rows)
		pending_row_count:              ui_clone_functional_judgment_pending_count(rows)
		failed_row_count:               ui_clone_functional_judgment_failed_count(rows)
		visual_only_rejected_row_count: ui_clone_functional_judgment_visual_only_count(rows)
		dynamic_text_masked_row_count:  ui_clone_functional_judgment_masked_count(rows)
		behavior_evidence_required:     ui_clone_functional_judgment_required_count(rows)
		behavior_evidence_passed:       ui_clone_functional_judgment_passed_count(rows)
		behavior_evidence_failed:       ui_clone_functional_judgment_failed_probe_count(rows)
		behavior_evidence_missing:      ui_clone_functional_judgment_missing_probe_count(rows)
		clone_claim_allowed:            allowed
		literal_text_can_certify:       false
		visual_only_can_certify:        false
		decision_rule:                  ui_clone_functional_judgment_rule(ledger, rows, coverage,
			allowed)
		rows:                           rows
	}
}

fn ui_clone_functional_judgment_row(row UiCloneFunctionalCloneEvidenceRow) UiCloneFunctionalJudgmentRow {
	function_understood := row.functional_question.trim_space() != ''
		&& row.expected_state_delta.trim_space() != '' && row.required_behavior_probes.len > 0
	visual_locus_understood := row.visual_region.trim_space() != ''
		&& row.visual_component.trim_space() != '' && row.visual_locus_rule.trim_space() != ''
	dynamic_text_masked := row.runtime_data_policy.trim_space() != '' && !row.compare_literal_text
	coverage := ui_clone_functional_judgment_row_coverage(row, function_understood,
		visual_locus_understood, dynamic_text_masked)
	verdict := ui_clone_functional_judgment_row_verdict(row)
	return UiCloneFunctionalJudgmentRow{
		visual_region:              row.visual_region
		visual_component:           row.visual_component
		functional_region:          row.functional_region
		functional_component:       row.functional_component
		equality_target:            row.equality_target
		visual_anchor_subject:      ui_clone_functional_judgment_visual_anchor(row)
		equalized_subject:          ui_clone_functional_judgment_equalized_subject(row)
		excluded_literal_subject:   ui_clone_functional_judgment_excluded_literal(row)
		clone_reasoning_mode:       ui_clone_functional_judgment_reasoning_mode(row)
		visual_role:                ui_clone_functional_judgment_visual_role(row)
		functional_role:            ui_clone_functional_judgment_functional_role(row)
		atomic_parity_contract:     ui_clone_functional_judgment_atomic_contract(row)
		runtime_evidence_contract:  ui_clone_functional_judgment_runtime_contract(row)
		literal_copy_blocker:       ui_clone_functional_judgment_literal_blocker(row)
		visual_locus_rule:          row.visual_locus_rule
		functional_question:        row.functional_question
		expected_state_delta:       row.expected_state_delta
		function_understood:        function_understood
		visual_locus_understood:    visual_locus_understood
		dynamic_text_masked:        dynamic_text_masked
		compare_literal_text:       row.compare_literal_text
		required_behavior_probes:   row.required_behavior_probes
		behavior_evidence_required: row.required_behavior_probes.len
		behavior_evidence_passed:   row.behavior_probe_passed_count
		behavior_evidence_failed:   row.behavior_probe_failed_count
		behavior_evidence_missing:  row.behavior_probe_missing_count
		evidence_classes:           row.evidence_classes
		evidence_sources:           row.evidence_sources
		matched_signal_ids:         row.matched_signal_ids
		visual_only_rejected:       row.visual_only_blocked
		nonblind_reasoning:         row.nonblind_reasoning
		coverage_percent:           coverage
		verdict:                    verdict
		decision_reason:            ui_clone_functional_judgment_reason(row, verdict)
		next_required_evidence:     ui_clone_functional_judgment_next_evidence(row, verdict)
		text_policy:                ui_clone_functional_judgment_text_policy(row)
	}
}

fn ui_clone_functional_judgment_visual_anchor(row UiCloneFunctionalCloneEvidenceRow) string {
	return '${row.visual_component} stable geometry and affordance locus in ${row.visual_region}'
}

fn ui_clone_functional_judgment_equalized_subject(row UiCloneFunctionalCloneEvidenceRow) string {
	return '${row.functional_component} behavior and state deltas at ${row.visual_component} visual locus'
}

fn ui_clone_functional_judgment_excluded_literal(row UiCloneFunctionalCloneEvidenceRow) string {
	if row.compare_literal_text {
		return 'no literal exclusion for ${row.functional_component}'
	}
	return 'runtime labels, OCR text, copied content, and static screenshots for ${row.functional_component}'
}

fn ui_clone_functional_judgment_reasoning_mode(row UiCloneFunctionalCloneEvidenceRow) string {
	if row.compare_literal_text {
		return 'literal_structural_label_allowed'
	}
	return 'functional_behavior_over_literal_screen_text'
}

fn ui_clone_functional_judgment_visual_role(row UiCloneFunctionalCloneEvidenceRow) string {
	if row.visual_component == row.functional_component {
		return 'stable_visual_locus_and_behavior_owner'
	}
	return 'stable_visual_locus_for_${row.functional_component}'
}

fn ui_clone_functional_judgment_functional_role(row UiCloneFunctionalCloneEvidenceRow) string {
	if row.visual_component == row.functional_component {
		return 'native_behavior_owner_at_same_locus'
	}
	return 'behavior_owner_mapped_to_${row.visual_component}_locus'
}

fn ui_clone_functional_judgment_atomic_contract(row UiCloneFunctionalCloneEvidenceRow) string {
	return '${row.visual_component} locates ${row.functional_component}; answer "${row.functional_question}" by proving "${row.expected_state_delta}" with probes: ${ui_clone_functional_judgment_probe_list(row.required_behavior_probes)}'
}

fn ui_clone_functional_judgment_runtime_contract(row UiCloneFunctionalCloneEvidenceRow) string {
	return 'accepted evidence: ${ui_clone_functional_judgment_kind_list(row.accepted_evidence_kinds)}; rejected evidence: ${ui_clone_functional_judgment_kind_list(row.rejected_evidence_kinds)}'
}

fn ui_clone_functional_judgment_literal_blocker(row UiCloneFunctionalCloneEvidenceRow) string {
	if row.compare_literal_text {
		return 'literal comparison is limited to stable structural labels for ${row.functional_component}'
	}
	return 'blocked: copied runtime labels, OCR text, and static screenshots cannot certify ${row.functional_component}'
}

fn ui_clone_functional_judgment_probe_list(items []string) string {
	if items.len == 0 {
		return 'no_behavior_probe_declared'
	}
	return items.join(', ')
}

fn ui_clone_functional_judgment_kind_list(items []string) string {
	if items.len == 0 {
		return 'none'
	}
	return items.join(', ')
}

fn ui_clone_functional_judgment_row_coverage(row UiCloneFunctionalCloneEvidenceRow,
	function_understood bool, visual_locus_understood bool, dynamic_text_masked bool) int {
	mut score := 0
	if function_understood {
		score += 25
	}
	if visual_locus_understood {
		score += 20
	}
	if dynamic_text_masked {
		score += 15
	}
	if row.required_behavior_probes.len > 0 {
		score += (row.behavior_probe_passed_count * 40) / row.required_behavior_probes.len
	}
	if row.visual_only_blocked || row.behavior_probe_failed_count > 0 {
		return ui_clone_functional_judgment_min(score, 60)
	}
	return ui_clone_functional_judgment_min(score, 100)
}

fn ui_clone_functional_judgment_row_verdict(row UiCloneFunctionalCloneEvidenceRow) string {
	if !row.nonblind_reasoning {
		return 'blind_row_blocked'
	}
	if row.visual_only_blocked {
		return 'visual_only_rejected'
	}
	if row.behavior_probe_failed_count > 0 {
		return 'failed_behavior'
	}
	if row.behavior_probe_missing_count > 0 {
		return 'pending_behavior'
	}
	if row.functional_certified {
		return 'functionally_equivalent'
	}
	return 'structural_only'
}

fn ui_clone_functional_judgment_reason(row UiCloneFunctionalCloneEvidenceRow,
	verdict string) string {
	return match verdict {
		'functionally_equivalent' {
			'accepted runtime evidence answered ${row.functional_component}: ${row.functional_question}'
		}
		'visual_only_rejected' {
			'visual/OCR similarity was rejected for ${row.functional_component}; functional clones need state-delta evidence'
		}
		'failed_behavior' {
			'one or more behavior receipts failed for ${row.functional_component}'
		}
		'pending_behavior' {
			'waiting for runtime evidence that answers ${row.functional_component}: ${row.functional_question}'
		}
		'blind_row_blocked' {
			'functional target or evidence question is not explicit for ${row.functional_component}'
		}
		else {
			'only structural evidence exists for ${row.functional_component}; behavior still owns certification'
		}
	}
}

fn ui_clone_functional_judgment_next_evidence(row UiCloneFunctionalCloneEvidenceRow,
	verdict string) []string {
	if verdict == 'functionally_equivalent' {
		return []string{}
	}
	if verdict == 'visual_only_rejected' {
		return [
			'replace screenshot/OCR mimic with command, action, state-delta, model mutation, or live-event receipt',
		]
	}
	if verdict == 'blind_row_blocked' {
		return [
			'declare the functional target subject and behavior question before scoring pixels',
		]
	}
	if row.required_behavior_probes.len > 0 {
		return [
			'provide accepted runtime evidence for probes: ${row.required_behavior_probes.join(', ')}',
		]
	}
	return [
		'provide role-specific runtime state delta for ${row.functional_component}',
	]
}

fn ui_clone_functional_judgment_text_policy(row UiCloneFunctionalCloneEvidenceRow) string {
	if row.compare_literal_text {
		return 'literal labels may be compared for this surface'
	}
	if row.runtime_data_policy.trim_space() == '' {
		return 'text cannot certify behavior; use runtime evidence'
	}
	return 'runtime text is data and must be masked: ${row.runtime_data_policy}'
}

fn ui_clone_functional_judgment_blocker(ledger UiCloneFunctionalCloneEvidenceLedger,
	rows []UiCloneFunctionalJudgmentRow, coverage int, allowed bool) string {
	if allowed {
		return ''
	}
	if ledger.blocker != '' {
		return ledger.blocker
	}
	if rows.len == 0 {
		return 'functional_clone_judgment_has_no_rows'
	}
	if ui_clone_functional_judgment_visual_only_count(rows) > 0 {
		return 'functional_clone_judgment_contains_visual_only_evidence'
	}
	if ui_clone_functional_judgment_failed_count(rows) > 0 {
		return 'functional_clone_judgment_has_failed_behavior'
	}
	if ui_clone_functional_judgment_pending_count(rows) > 0 {
		return 'functional_clone_judgment_has_pending_behavior'
	}
	if coverage < 100 {
		return 'functional_clone_judgment_incomplete_coverage'
	}
	return 'functional_clone_judgment_not_certified'
}

fn ui_clone_functional_judgment_rule(ledger UiCloneFunctionalCloneEvidenceLedger,
	rows []UiCloneFunctionalJudgmentRow, coverage int, allowed bool) string {
	if allowed {
		return 'functional clone allowed: every surface has visual locus, dynamic data policy, and accepted runtime behavior evidence'
	}
	blocker := ui_clone_functional_judgment_blocker(ledger, rows, coverage, allowed)
	return 'blocked: ${blocker}; visual similarity is only a locator, not proof of cloned functionality'
}

fn ui_clone_functional_judgment_coverage(rows []UiCloneFunctionalJudgmentRow) int {
	if rows.len == 0 {
		return 0
	}
	mut total := 0
	for row in rows {
		total += row.coverage_percent
	}
	return total / rows.len
}

fn ui_clone_functional_judgment_understood_count(rows []UiCloneFunctionalJudgmentRow) int {
	mut count := 0
	for row in rows {
		if row.function_understood && row.visual_locus_understood && row.dynamic_text_masked {
			count++
		}
	}
	return count
}

fn ui_clone_functional_judgment_certified_count(rows []UiCloneFunctionalJudgmentRow) int {
	mut count := 0
	for row in rows {
		if row.verdict == 'functionally_equivalent' {
			count++
		}
	}
	return count
}

fn ui_clone_functional_judgment_pending_count(rows []UiCloneFunctionalJudgmentRow) int {
	mut count := 0
	for row in rows {
		if row.verdict == 'pending_behavior' || row.verdict == 'structural_only'
			|| row.verdict == 'blind_row_blocked' {
			count++
		}
	}
	return count
}

fn ui_clone_functional_judgment_failed_count(rows []UiCloneFunctionalJudgmentRow) int {
	mut count := 0
	for row in rows {
		if row.verdict == 'failed_behavior' || row.verdict == 'visual_only_rejected' {
			count++
		}
	}
	return count
}

fn ui_clone_functional_judgment_visual_only_count(rows []UiCloneFunctionalJudgmentRow) int {
	mut count := 0
	for row in rows {
		if row.visual_only_rejected {
			count++
		}
	}
	return count
}

fn ui_clone_functional_judgment_masked_count(rows []UiCloneFunctionalJudgmentRow) int {
	mut count := 0
	for row in rows {
		if row.dynamic_text_masked {
			count++
		}
	}
	return count
}

fn ui_clone_functional_judgment_required_count(rows []UiCloneFunctionalJudgmentRow) int {
	mut count := 0
	for row in rows {
		count += row.behavior_evidence_required
	}
	return count
}

fn ui_clone_functional_judgment_passed_count(rows []UiCloneFunctionalJudgmentRow) int {
	mut count := 0
	for row in rows {
		count += row.behavior_evidence_passed
	}
	return count
}

fn ui_clone_functional_judgment_failed_probe_count(rows []UiCloneFunctionalJudgmentRow) int {
	mut count := 0
	for row in rows {
		count += row.behavior_evidence_failed
	}
	return count
}

fn ui_clone_functional_judgment_missing_probe_count(rows []UiCloneFunctionalJudgmentRow) int {
	mut count := 0
	for row in rows {
		count += row.behavior_evidence_missing
	}
	return count
}

fn ui_clone_functional_judgment_min(a int, b int) int {
	if a < b {
		return a
	}
	return b
}
