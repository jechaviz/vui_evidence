module vui_evidence

pub struct UiCloneComparisonSubjectDirectiveRow {
pub:
	visual_region            string
	visual_component         string
	functional_region        string
	functional_component     string
	equality_target          string
	visual_locus_rule        string
	functional_question      string
	expected_state_delta     string
	match_geometry           bool
	match_literal_text       bool
	compare_runtime_labels   bool
	runtime_data_masks       []string
	required_behavior_probes []string
	accepted_evidence_kinds  []string
	rejected_evidence_kinds  []string
	background_safe          bool
	nonblind_reasoning       bool
	certification_gate       string
}

pub struct UiCloneComparisonSubjectDirective {
pub:
	visual_profile              string
	functional_profile          string
	clone_intent                string
	mode                        string
	cross_profile               bool
	ready                       bool
	blocker                     string
	blind_risk                  string
	visual_source               string
	functional_source           string
	functional_subject_explicit bool
	visual_subject              string
	functional_subject          string
	equality_definition         string
	clone_target_policy         string
	visual_authority            string
	functional_authority        string
	text_policy                 string
	runtime_data_policy         string
	evidence_policy             string
	verification_order          []string
	accepted_evidence_kinds     []string
	rejected_evidence_kinds     []string
	row_count                   int
	functional_question_count   int
	behavior_probe_count        int
	background_safe_probe_count int
	runtime_data_mask_count     int
	literal_text_can_certify    bool
	visual_only_can_certify     bool
	rows                        []UiCloneComparisonSubjectDirectiveRow
}

pub fn ui_clone_comparison_subject_directive(input UiCloneSubjectInput) UiCloneComparisonSubjectDirective {
	resolution := ui_clone_subject_resolution(input)
	brief := ui_clone_nonblind_reasoning_brief(input)
	equivalence_rows := ui_clone_functional_equivalence(resolution.visual_profile,
		resolution.functional_profile, resolution.clone_intent)
	rows := ui_clone_comparison_subject_rows(equivalence_rows)
	blocker := ui_clone_comparison_subject_blocker(resolution, brief, rows)
	return UiCloneComparisonSubjectDirective{
		visual_profile:              resolution.visual_profile
		functional_profile:          resolution.functional_profile
		clone_intent:                resolution.clone_intent
		mode:                        resolution.mode
		cross_profile:               resolution.cross_profile
		ready:                       blocker == ''
		blocker:                     blocker
		blind_risk:                  resolution.blind_risk
		visual_source:               resolution.visual_source
		functional_source:           resolution.functional_source
		functional_subject_explicit: resolution.functional_subject_explicit
		visual_subject:              resolution.visual_reference_subject
		functional_subject:          resolution.functional_target_subject
		equality_definition:         ui_clone_comparison_subject_equality_definition(resolution)
		clone_target_policy:         ui_clone_comparison_subject_clone_target_policy(resolution)
		visual_authority:            brief.visual_authority
		functional_authority:        brief.functional_authority
		text_policy:                 'runtime text is data; copied OCR labels never certify functional parity'
		runtime_data_policy:         ui_clone_comparison_subject_runtime_policy(rows)
		evidence_policy:             'accepted evidence must answer functional questions with command, action, state-delta, or live-event receipts'
		verification_order:          ui_clone_comparison_subject_verification_order(resolution)
		accepted_evidence_kinds:     brief.accepted_evidence_kinds
		rejected_evidence_kinds:     brief.rejected_evidence_kinds
		row_count:                   rows.len
		functional_question_count:   ui_clone_comparison_subject_question_count(rows)
		behavior_probe_count:        ui_clone_comparison_subject_probe_count(rows)
		background_safe_probe_count: ui_clone_comparison_subject_background_count(rows)
		runtime_data_mask_count:     ui_clone_comparison_subject_mask_count(rows)
		literal_text_can_certify:    false
		visual_only_can_certify:     false
		rows:                        rows
	}
}

fn ui_clone_comparison_subject_rows(rows []UiCloneFunctionalEquivalenceRow) []UiCloneComparisonSubjectDirectiveRow {
	mut out := []UiCloneComparisonSubjectDirectiveRow{}
	for row in rows {
		out << UiCloneComparisonSubjectDirectiveRow{
			visual_region:            row.visual_region
			visual_component:         row.visual_component
			functional_region:        row.functional_region
			functional_component:     row.functional_component
			equality_target:          ui_clone_comparison_subject_row_target(row)
			visual_locus_rule:        row.equivalence_role
			functional_question:      ui_clone_functional_question(row.functional_component)
			expected_state_delta:     ui_clone_expected_state_delta(row)
			match_geometry:           row.geometry_required
			match_literal_text:       false
			compare_runtime_labels:   false
			runtime_data_masks:       row.functional_runtime_masks
			required_behavior_probes: row.behavior_probe_affordances
			accepted_evidence_kinds:  ui_clone_functional_accepted_evidence(row)
			rejected_evidence_kinds:  ui_clone_functional_rejected_evidence(row)
			background_safe:          row.behavior_probe_count > 0
				&& row.background_safe_probe_count == row.behavior_probe_count
			nonblind_reasoning:       ui_clone_comparison_subject_row_nonblind(row)
			certification_gate:       row.certification_gate
		}
	}
	return out
}

fn ui_clone_comparison_subject_row_target(row UiCloneFunctionalEquivalenceRow) string {
	if row.cross_profile {
		return '${row.functional_component} behavior and state must match ${row.functional_profile}; ${row.visual_component} is only the visible locus'
	}
	return '${row.functional_component} behavior, state, and stable anchors must match ${row.functional_profile}; runtime labels stay dynamic'
}

fn ui_clone_comparison_subject_row_nonblind(row UiCloneFunctionalEquivalenceRow) bool {
	return !row.visual_surface_missing && row.stable_visual_anchors.len > 0
		&& row.behavior_probe_count > 0 && !row.literal_text_can_certify
}

fn ui_clone_comparison_subject_blocker(resolution UiCloneSubjectResolution,
	brief UiCloneNonblindReasoningBrief, rows []UiCloneComparisonSubjectDirectiveRow) string {
	if resolution.mode != 'semantic_functional_clone' {
		return ''
	}
	if brief.blocker != '' {
		return brief.blocker
	}
	if rows.len == 0 {
		return 'comparison_subject_has_no_functional_rows'
	}
	if ui_clone_comparison_subject_nonblind_count(rows) != rows.len {
		return 'comparison_subject_has_blind_rows'
	}
	return ''
}

fn ui_clone_comparison_subject_equality_definition(resolution UiCloneSubjectResolution) string {
	if resolution.mode != 'semantic_functional_clone' {
		return 'pixel equality only; no functional clone claim is certified'
	}
	if resolution.cross_profile {
		return 'functional equality means ${resolution.functional_profile} commands, state deltas, native behavior, and dynamic data policies pass while ${resolution.visual_profile} supplies only geometry and affordance loci'
	}
	return 'functional equality means stable anchors plus behavior probes pass for ${resolution.functional_profile}; literal runtime text is ignored'
}

fn ui_clone_comparison_subject_clone_target_policy(resolution UiCloneSubjectResolution) string {
	if resolution.mode != 'semantic_functional_clone' {
		return 'visual reference clone'
	}
	if resolution.cross_profile {
		return 'clone the visual shell shape, not its runtime subject; certify the declared functional target'
	}
	return 'clone the declared functional UI without freezing user/session/runtime text'
}

fn ui_clone_comparison_subject_runtime_policy(rows []UiCloneComparisonSubjectDirectiveRow) string {
	count := ui_clone_comparison_subject_mask_count(rows)
	if count == 0 {
		return 'no runtime data masks declared; require structural-only text before comparing labels'
	}
	return 'mask ${count} runtime data fields before comparing visual regions'
}

fn ui_clone_comparison_subject_verification_order(resolution UiCloneSubjectResolution) []string {
	if resolution.mode != 'semantic_functional_clone' {
		return ['load_reference_pixels', 'compare_segment_geometry', 'do_not_claim_functional_parity']
	}
	return [
		'resolve_visual_reference_subject',
		'resolve_explicit_functional_target_subject',
		'map_visual_loci_to_functional_components',
		'mask_runtime_text_and_user_generated_content',
		'run_atomic_behavior_probes_in_background_when_possible',
		'accept_segmented_geometry_only_as_surface-location evidence',
	]
}

fn ui_clone_comparison_subject_nonblind_count(rows []UiCloneComparisonSubjectDirectiveRow) int {
	mut count := 0
	for row in rows {
		if row.nonblind_reasoning {
			count++
		}
	}
	return count
}

fn ui_clone_comparison_subject_question_count(rows []UiCloneComparisonSubjectDirectiveRow) int {
	mut count := 0
	for row in rows {
		if row.functional_question != '' {
			count++
		}
	}
	return count
}

fn ui_clone_comparison_subject_probe_count(rows []UiCloneComparisonSubjectDirectiveRow) int {
	mut count := 0
	for row in rows {
		count += row.required_behavior_probes.len
	}
	return count
}

fn ui_clone_comparison_subject_background_count(rows []UiCloneComparisonSubjectDirectiveRow) int {
	mut count := 0
	for row in rows {
		if row.background_safe {
			count += row.required_behavior_probes.len
		}
	}
	return count
}

fn ui_clone_comparison_subject_mask_count(rows []UiCloneComparisonSubjectDirectiveRow) int {
	mut count := 0
	for row in rows {
		count += row.runtime_data_masks.len
	}
	return count
}
