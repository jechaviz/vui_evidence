module vui_evidence

pub struct UiCloneSemanticComparisonRow {
pub:
	visual_region              string
	visual_component           string
	functional_region          string
	functional_component       string
	functional_role            string
	compare_geometry           bool
	compare_literal_text       bool
	text_policy                string
	visual_locus_rule          string
	functional_cert_rule       string
	stable_visual_anchors      []string
	runtime_data_masks         []string
	required_behaviors         []string
	behavior_probe_affordances []string
	accepted_evidence_kinds    []string
	rejected_evidence_kinds    []string
	certification_gate         string
}

pub struct UiCloneSemanticComparisonBrief {
pub:
	visual_profile              string
	functional_profile          string
	clone_intent                string
	mode                        string
	cross_profile               bool
	ready                       bool
	blocker                     string
	blind_risk                  string
	functional_subject_explicit bool
	visual_subject              string
	functional_subject          string
	visual_source               string
	functional_source           string
	comparison_goal             string
	nonblind_rule               string
	visual_authority            string
	functional_authority        string
	row_count                   int
	stable_visual_anchor_count  int
	runtime_data_mask_count     int
	behavior_probe_count        int
	background_safe_probe_count int
	literal_text_can_certify    bool
	visual_only_can_certify     bool
	accepted_evidence_kinds     []string
	rejected_evidence_kinds     []string
	rows                        []UiCloneSemanticComparisonRow
}

pub fn ui_clone_semantic_comparison_brief(input UiCloneSubjectInput) UiCloneSemanticComparisonBrief {
	resolution := ui_clone_subject_resolution(input)
	plan := ui_clone_functional_clone_plan(resolution.visual_profile,
		resolution.functional_profile, resolution.clone_intent)
	equivalence := ui_clone_functional_equivalence_summary(resolution.visual_profile,
		resolution.functional_profile, resolution.clone_intent)
	rows := ui_clone_semantic_comparison_rows(equivalence.rows)
	return UiCloneSemanticComparisonBrief{
		visual_profile:              resolution.visual_profile
		functional_profile:          resolution.functional_profile
		clone_intent:                resolution.clone_intent
		mode:                        resolution.mode
		cross_profile:               resolution.cross_profile
		ready:                       ui_clone_semantic_comparison_ready(resolution, plan,
			equivalence)
		blocker:                     ui_clone_semantic_comparison_blocker(resolution, plan,
			equivalence)
		blind_risk:                  resolution.blind_risk
		functional_subject_explicit: resolution.functional_subject_explicit
		visual_subject:              resolution.visual_reference_subject
		functional_subject:          resolution.functional_target_subject
		visual_source:               resolution.visual_source
		functional_source:           resolution.functional_source
		comparison_goal:             plan.clone_goal
		nonblind_rule:               ui_clone_semantic_comparison_rule(resolution, plan)
		visual_authority:            plan.visual_reference_role
		functional_authority:        plan.functional_target_role
		row_count:                   rows.len
		stable_visual_anchor_count:  ui_clone_semantic_comparison_anchor_count(rows)
		runtime_data_mask_count:     ui_clone_semantic_comparison_mask_count(rows)
		behavior_probe_count:        plan.behavior_probe_count
		background_safe_probe_count: plan.background_safe_probe_count
		literal_text_can_certify:    false
		visual_only_can_certify:     false
		accepted_evidence_kinds:     plan.accepted_evidence_kinds
		rejected_evidence_kinds:     plan.rejected_evidence_kinds
		rows:                        rows
	}
}

pub fn ui_clone_semantic_comparison_brief_for_subjects(visual_reference_profile string,
	functional_target_profile string, clone_intent string) UiCloneSemanticComparisonBrief {
	return ui_clone_semantic_comparison_brief(UiCloneSubjectInput{
		visual_reference_profile:  visual_reference_profile
		functional_target_profile: functional_target_profile
		clone_intent:              clone_intent
	})
}

fn ui_clone_semantic_comparison_rows(rows []UiCloneFunctionalEquivalenceRow) []UiCloneSemanticComparisonRow {
	mut out := []UiCloneSemanticComparisonRow{}
	for row in rows {
		out << UiCloneSemanticComparisonRow{
			visual_region:              row.visual_region
			visual_component:           row.visual_component
			functional_region:          row.functional_region
			functional_component:       row.functional_component
			functional_role:            row.functional_role
			compare_geometry:           row.geometry_required
			compare_literal_text:       false
			text_policy:                ui_clone_semantic_comparison_text_policy(row)
			visual_locus_rule:          row.equivalence_role
			functional_cert_rule:       'behavior ownership stays with ${row.functional_component}'
			stable_visual_anchors:      row.stable_visual_anchors
			runtime_data_masks:         row.functional_runtime_masks
			required_behaviors:         row.required_behaviors
			behavior_probe_affordances: row.behavior_probe_affordances
			accepted_evidence_kinds:    ui_clone_semantic_comparison_row_accepted(row)
			rejected_evidence_kinds:    row.anti_blind_rules
			certification_gate:         row.certification_gate
		}
	}
	return out
}

fn ui_clone_semantic_comparison_ready(resolution UiCloneSubjectResolution,
	plan UiCloneFunctionalClonePlan, equivalence UiCloneFunctionalEquivalenceSummary) bool {
	return resolution.ready && resolution.blind_risk == '' && plan.ready && equivalence.ready
}

fn ui_clone_semantic_comparison_blocker(resolution UiCloneSubjectResolution,
	plan UiCloneFunctionalClonePlan, equivalence UiCloneFunctionalEquivalenceSummary) string {
	if resolution.blind_risk != '' {
		return resolution.blind_risk
	}
	if !resolution.ready {
		return resolution.blocker
	}
	if !plan.ready {
		return plan.blocker
	}
	if !equivalence.ready {
		return equivalence.blocker
	}
	return ''
}

fn ui_clone_semantic_comparison_rule(resolution UiCloneSubjectResolution,
	plan UiCloneFunctionalClonePlan) string {
	if resolution.mode != 'semantic_functional_clone' {
		return 'visual-only QA can compare pixels but cannot certify functional clone behavior'
	}
	if resolution.blind_risk != '' {
		return 'blocked until the functional subject is explicit; do not infer behavior from the visual reference'
	}
	return '${plan.authority_rule}; literal OCR text is runtime data unless a row marks it structural'
}

fn ui_clone_semantic_comparison_text_policy(row UiCloneFunctionalEquivalenceRow) string {
	if row.functional_runtime_masks.len > 0 {
		return 'mask runtime text: ${row.functional_runtime_masks.join(', ')}'
	}
	return 'compare structural labels only; copied OCR text cannot certify behavior'
}

fn ui_clone_semantic_comparison_row_accepted(row UiCloneFunctionalEquivalenceRow) []string {
	mut out := ['segmented_region_bounds', 'stable_affordance_geometry', 'semantic_role_match']
	if row.behavior_probe_count > 0 {
		ui_clone_append_unique(mut out, 'atomic_behavior_probe')
		ui_clone_append_unique(mut out, 'runtime_state_delta')
		ui_clone_append_unique(mut out, 'live_event_receipt')
	}
	return out
}

fn ui_clone_semantic_comparison_anchor_count(rows []UiCloneSemanticComparisonRow) int {
	mut count := 0
	for row in rows {
		count += row.stable_visual_anchors.len
	}
	return count
}

fn ui_clone_semantic_comparison_mask_count(rows []UiCloneSemanticComparisonRow) int {
	mut count := 0
	for row in rows {
		count += row.runtime_data_masks.len
	}
	return count
}
