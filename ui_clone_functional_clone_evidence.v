module vui_evidence

pub struct UiCloneFunctionalCloneEvidenceRow {
pub:
	visual_region                string
	visual_component             string
	functional_region            string
	functional_component         string
	equality_target              string
	visual_locus_rule            string
	functional_question          string
	expected_state_delta         string
	compare_geometry             bool
	compare_literal_text         bool
	runtime_data_policy          string
	required_behavior_probes     []string
	accepted_evidence_kinds      []string
	rejected_evidence_kinds      []string
	behavior_probe_passed_count  int
	behavior_probe_failed_count  int
	behavior_probe_missing_count int
	evidence_classes             []string
	evidence_sources             []string
	matched_signal_ids           []string
	nonblind_reasoning           bool
	visual_only_blocked          bool
	functional_certified         bool
	certification_status         string
	certification_rule           string
}

pub struct UiCloneFunctionalCloneEvidenceLedger {
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
	visual_authority               string
	functional_authority           string
	visual_locus_count             int
	functional_question_count      int
	runtime_data_mask_count        int
	behavior_probe_count           int
	behavior_probe_passed_count    int
	behavior_probe_failed_count    int
	behavior_probe_missing_count   int
	visual_only_blocked_count      int
	functional_certified_row_count int
	functional_parity_candidate    bool
	literal_text_can_certify       bool
	visual_only_can_certify        bool
	certification_rule             string
	rows                           []UiCloneFunctionalCloneEvidenceRow
}

pub fn ui_clone_functional_clone_evidence_ledger(input UiCloneSubjectInput,
	signals []UiCloneRuntimeSignal) UiCloneFunctionalCloneEvidenceLedger {
	resolution := ui_clone_subject_resolution(input)
	mut receipts := []UiCloneBehaviorProbeEvidenceReceipt{}
	for policy in ui_clone_behavior_probe_policies(resolution.functional_profile,
		resolution.clone_intent) {
		receipts << UiCloneBehaviorProbeEvidenceReceipt{
			affordance: policy.affordance
			evidence:   ui_clone_runtime_evidence_for_probe(policy, signals)
		}
	}
	return ui_clone_functional_clone_evidence_ledger_from_probe_evidence(input, receipts)
}

pub fn ui_clone_functional_clone_evidence_ledger_from_probe_evidence(input UiCloneSubjectInput,
	receipts []UiCloneBehaviorProbeEvidenceReceipt) UiCloneFunctionalCloneEvidenceLedger {
	brief := ui_clone_nonblind_reasoning_brief(input)
	mut rows := []UiCloneFunctionalCloneEvidenceRow{}
	for row in brief.rows {
		rows << ui_clone_functional_clone_evidence_row(row, receipts)
	}
	candidate := brief.ready && rows.len > 0
		&& ui_clone_functional_clone_certified_count(rows) == rows.len
	return UiCloneFunctionalCloneEvidenceLedger{
		visual_profile:                 brief.visual_profile
		functional_profile:             brief.functional_profile
		clone_intent:                   brief.clone_intent
		mode:                           brief.mode
		cross_profile:                  brief.cross_profile
		ready:                          brief.ready && candidate
		blocker:                        ui_clone_functional_clone_evidence_blocker(brief, rows)
		blind_risk:                     brief.blind_risk
		functional_subject_explicit:    brief.functional_subject_explicit
		visual_subject:                 brief.visual_subject
		functional_subject:             brief.functional_subject
		visual_authority:               brief.visual_authority
		functional_authority:           brief.functional_authority
		visual_locus_count:             rows.len
		functional_question_count:      brief.functional_question_count
		runtime_data_mask_count:        brief.runtime_data_mask_count
		behavior_probe_count:           ui_clone_functional_clone_probe_count(rows)
		behavior_probe_passed_count:    ui_clone_functional_clone_passed_count(rows)
		behavior_probe_failed_count:    ui_clone_functional_clone_failed_count(rows)
		behavior_probe_missing_count:   ui_clone_functional_clone_missing_count(rows)
		visual_only_blocked_count:      ui_clone_functional_clone_visual_only_count(rows)
		functional_certified_row_count: ui_clone_functional_clone_certified_count(rows)
		functional_parity_candidate:    candidate
		literal_text_can_certify:       false
		visual_only_can_certify:        false
		certification_rule:             ui_clone_functional_clone_evidence_rule(brief, candidate)
		rows:                           rows
	}
}

fn ui_clone_functional_clone_evidence_row(row UiCloneNonblindReasoningBriefRow,
	receipts []UiCloneBehaviorProbeEvidenceReceipt) UiCloneFunctionalCloneEvidenceRow {
	mut passed := 0
	mut failed := 0
	mut missing := 0
	mut visual_only := false
	mut classes := []string{}
	mut sources := []string{}
	mut signal_ids := []string{}
	for affordance in row.behavior_probe_affordances {
		evidence := ui_clone_semantic_evidence_for_affordance(receipts, affordance)
		if !evidence.found {
			missing++
			continue
		}
		ui_clone_append_unique(mut classes, evidence.semantic_class)
		ui_clone_append_unique(mut sources, evidence.source)
		ui_clone_append_unique(mut signal_ids, evidence.matched_signal_id)
		if evidence.ok {
			passed++
		} else {
			failed++
			if evidence.semantic_class == 'visual_mimic' {
				visual_only = true
			}
		}
	}
	status := ui_clone_functional_clone_evidence_status(row, passed, failed, missing, visual_only)
	return UiCloneFunctionalCloneEvidenceRow{
		visual_region:                row.visual_region
		visual_component:             row.visual_component
		functional_region:            row.functional_region
		functional_component:         row.functional_component
		equality_target:              ui_clone_functional_clone_equality_target(row)
		visual_locus_rule:            ui_clone_functional_clone_visual_locus_rule(row)
		functional_question:          row.functional_question
		expected_state_delta:         row.expected_state_delta
		compare_geometry:             row.compare_geometry
		compare_literal_text:         false
		runtime_data_policy:          row.runtime_data_policy
		required_behavior_probes:     row.behavior_probe_affordances
		accepted_evidence_kinds:      row.accepted_evidence_kinds
		rejected_evidence_kinds:      row.rejected_evidence_kinds
		behavior_probe_passed_count:  passed
		behavior_probe_failed_count:  failed
		behavior_probe_missing_count: missing
		evidence_classes:             classes
		evidence_sources:             sources
		matched_signal_ids:           signal_ids
		nonblind_reasoning:           row.nonblind_reasoning
		visual_only_blocked:          visual_only
		functional_certified:         status == 'certified'
		certification_status:         status
		certification_rule:           ui_clone_functional_clone_row_rule(row, status)
	}
}

fn ui_clone_functional_clone_equality_target(row UiCloneNonblindReasoningBriefRow) string {
	return '${row.functional_component} behavior at ${row.visual_component} visual locus'
}

fn ui_clone_functional_clone_visual_locus_rule(row UiCloneNonblindReasoningBriefRow) string {
	if row.visual_component == row.functional_component {
		return '${row.visual_component} is both the visual locus and functional owner'
	}
	return '${row.visual_component} locates the surface; ${row.functional_component} owns the behavior question'
}

fn ui_clone_functional_clone_evidence_status(row UiCloneNonblindReasoningBriefRow, passed int,
	failed int, missing int, visual_only bool) string {
	if !row.nonblind_reasoning {
		return 'blind_row_blocked'
	}
	if visual_only {
		return 'visual_only_rejected'
	}
	if failed > 0 {
		return 'failed'
	}
	if missing > 0 {
		return 'pending_probe'
	}
	if row.behavior_probe_affordances.len > 0 && passed == row.behavior_probe_affordances.len {
		return 'certified'
	}
	return 'structural_only'
}

fn ui_clone_functional_clone_row_rule(row UiCloneNonblindReasoningBriefRow,
	status string) string {
	if status == 'certified' {
		return 'certified: ${row.functional_component} answered "${row.functional_question}" with accepted runtime evidence'
	}
	if status == 'visual_only_rejected' {
		return row.visual_only_blocker
	}
	return 'not certified: ${row.functional_component} still needs accepted behavior evidence for "${row.functional_question}"'
}

fn ui_clone_functional_clone_evidence_blocker(brief UiCloneNonblindReasoningBrief,
	rows []UiCloneFunctionalCloneEvidenceRow) string {
	if !brief.ready {
		return brief.blocker
	}
	if rows.len == 0 {
		return 'functional_clone_evidence_has_no_rows'
	}
	if ui_clone_functional_clone_visual_only_count(rows) > 0 {
		return 'functional_clone_evidence_contains_visual_mimic'
	}
	if ui_clone_functional_clone_failed_count(rows) > 0 {
		return 'functional_clone_evidence_has_failed_probe'
	}
	if ui_clone_functional_clone_missing_count(rows) > 0 {
		return 'functional_clone_evidence_has_missing_probe'
	}
	if ui_clone_functional_clone_certified_count(rows) != rows.len {
		return 'functional_clone_evidence_has_uncertified_rows'
	}
	return ''
}

fn ui_clone_functional_clone_evidence_rule(brief UiCloneNonblindReasoningBrief,
	candidate bool) string {
	if !brief.ready {
		return 'blocked: ${brief.blocker}'
	}
	if candidate {
		return 'functional clone evidence certified: every visual locus answers its functional question with accepted runtime evidence'
	}
	return 'not certified: visual similarity only locates surfaces; every row must answer its functional question'
}

fn ui_clone_functional_clone_probe_count(rows []UiCloneFunctionalCloneEvidenceRow) int {
	mut count := 0
	for row in rows {
		count += row.required_behavior_probes.len
	}
	return count
}

fn ui_clone_functional_clone_passed_count(rows []UiCloneFunctionalCloneEvidenceRow) int {
	mut count := 0
	for row in rows {
		count += row.behavior_probe_passed_count
	}
	return count
}

fn ui_clone_functional_clone_failed_count(rows []UiCloneFunctionalCloneEvidenceRow) int {
	mut count := 0
	for row in rows {
		count += row.behavior_probe_failed_count
	}
	return count
}

fn ui_clone_functional_clone_missing_count(rows []UiCloneFunctionalCloneEvidenceRow) int {
	mut count := 0
	for row in rows {
		count += row.behavior_probe_missing_count
	}
	return count
}

fn ui_clone_functional_clone_visual_only_count(rows []UiCloneFunctionalCloneEvidenceRow) int {
	mut count := 0
	for row in rows {
		if row.visual_only_blocked {
			count++
		}
	}
	return count
}

fn ui_clone_functional_clone_certified_count(rows []UiCloneFunctionalCloneEvidenceRow) int {
	mut count := 0
	for row in rows {
		if row.functional_certified {
			count++
		}
	}
	return count
}
