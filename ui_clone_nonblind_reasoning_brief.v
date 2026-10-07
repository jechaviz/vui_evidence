module vui_evidence

pub struct UiCloneNonblindReasoningBriefRow {
pub:
	visual_region              string
	visual_component           string
	functional_region          string
	functional_component       string
	visual_match_kind          string
	functional_question        string
	expected_state_delta       string
	compare_geometry           bool
	compare_literal_text       bool
	runtime_data_policy        string
	accepted_evidence_kinds    []string
	rejected_evidence_kinds    []string
	behavior_probe_affordances []string
	nonblind_reasoning         bool
	visual_only_blocker        string
	certification_requirement  string
}

pub struct UiCloneNonblindReasoningBrief {
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
	nonblind_reasoning          bool
	visual_subject              string
	functional_subject          string
	subject_rule                string
	visual_authority            string
	functional_authority        string
	what_to_match               []string
	what_to_ignore              []string
	accepted_evidence_kinds     []string
	rejected_evidence_kinds     []string
	functional_question_count   int
	behavior_probe_count        int
	runtime_data_mask_count     int
	visual_only_can_certify     bool
	literal_text_can_certify    bool
	certification_gate          string
	rows                        []UiCloneNonblindReasoningBriefRow
}

pub fn ui_clone_nonblind_reasoning_brief(input UiCloneSubjectInput) UiCloneNonblindReasoningBrief {
	resolution := ui_clone_subject_resolution(input)
	plan := ui_clone_functional_clone_plan(resolution.visual_profile,
		resolution.functional_profile, resolution.clone_intent)
	understanding := ui_clone_functional_understanding_summary(resolution.visual_profile,
		resolution.functional_profile, resolution.clone_intent)
	rows := ui_clone_nonblind_reasoning_rows(ui_clone_functional_understanding(resolution.visual_profile,
		resolution.functional_profile, resolution.clone_intent))
	blocker := ui_clone_nonblind_reasoning_blocker(resolution, plan, understanding, rows)
	nonblind := blocker == ''
	return UiCloneNonblindReasoningBrief{
		visual_profile:              resolution.visual_profile
		functional_profile:          resolution.functional_profile
		clone_intent:                resolution.clone_intent
		mode:                        resolution.mode
		cross_profile:               resolution.cross_profile
		ready:                       nonblind
		blocker:                     blocker
		blind_risk:                  resolution.blind_risk
		functional_subject_explicit: resolution.functional_subject_explicit
		nonblind_reasoning:          nonblind
		visual_subject:              resolution.visual_reference_subject
		functional_subject:          resolution.functional_target_subject
		subject_rule:                ui_clone_nonblind_subject_rule(resolution)
		visual_authority:            plan.visual_reference_role
		functional_authority:        plan.functional_target_role
		what_to_match:               ui_clone_nonblind_match_targets(resolution)
		what_to_ignore:              ui_clone_nonblind_ignored_targets(resolution)
		accepted_evidence_kinds:     ui_clone_nonblind_accepted_evidence(plan, rows)
		rejected_evidence_kinds:     ui_clone_nonblind_rejected_evidence(plan, rows)
		functional_question_count:   understanding.functional_question_count
		behavior_probe_count:        plan.behavior_probe_count
		runtime_data_mask_count:     understanding.runtime_data_mask_count
		visual_only_can_certify:     false
		literal_text_can_certify:    false
		certification_gate:          ui_clone_nonblind_certification_gate(blocker)
		rows:                        rows
	}
}

fn ui_clone_nonblind_reasoning_rows(rows []UiCloneFunctionalUnderstandingRow) []UiCloneNonblindReasoningBriefRow {
	mut out := []UiCloneNonblindReasoningBriefRow{}
	for row in rows {
		out << UiCloneNonblindReasoningBriefRow{
			visual_region:              row.visual_region
			visual_component:           row.visual_component
			functional_region:          row.functional_region
			functional_component:       row.functional_component
			visual_match_kind:          ui_clone_nonblind_visual_match_kind(row)
			functional_question:        row.functional_question
			expected_state_delta:       row.expected_state_delta
			compare_geometry:           row.stable_visual_anchors.len > 0
			compare_literal_text:       false
			runtime_data_policy:        ui_clone_nonblind_runtime_policy(row)
			accepted_evidence_kinds:    row.accepted_evidence_kinds
			rejected_evidence_kinds:    ui_clone_nonblind_row_rejected(row)
			behavior_probe_affordances: row.behavior_probe_affordances
			nonblind_reasoning:         row.nonblind_reasoning
			visual_only_blocker:        ui_clone_nonblind_visual_only_blocker(row)
			certification_requirement:  ui_clone_nonblind_row_certification(row)
		}
	}
	return out
}

fn ui_clone_nonblind_reasoning_blocker(resolution UiCloneSubjectResolution,
	plan UiCloneFunctionalClonePlan, understanding UiCloneFunctionalUnderstandingSummary,
	rows []UiCloneNonblindReasoningBriefRow) string {
	if resolution.blind_risk != '' {
		return resolution.blind_risk
	}
	if !resolution.functional_subject_explicit && resolution.mode == 'semantic_functional_clone' {
		return 'functional_subject_not_explicit'
	}
	if !resolution.ready {
		return resolution.blocker
	}
	if !plan.ready {
		return plan.blocker
	}
	if !understanding.ready {
		return understanding.blocker
	}
	if rows.len == 0 {
		return 'nonblind_reasoning_has_no_functional_rows'
	}
	if ui_clone_nonblind_ready_row_count(rows) != rows.len {
		return 'nonblind_reasoning_has_blind_rows'
	}
	return ''
}

fn ui_clone_nonblind_subject_rule(resolution UiCloneSubjectResolution) string {
	if resolution.mode != 'semantic_functional_clone' {
		return 'visual reference is the pixel subject only; no functional clone claim is certified'
	}
	if resolution.cross_profile {
		return 'visual reference is not the functional authority; it only locates the native surface to probe'
	}
	return 'declared functional subject owns both stable anchors and behavior; runtime text remains data'
}

fn ui_clone_nonblind_match_targets(resolution UiCloneSubjectResolution) []string {
	if resolution.mode != 'semantic_functional_clone' {
		return ['reference pixels', 'segment geometry', 'visible text bounds']
	}
	mut out := [
		'stable geometry and region bounds from ${resolution.visual_profile}',
		'affordance loci and structural anchors, not runtime labels',
		'native desktop frame behavior where the surface exposes window controls',
	]
	if resolution.cross_profile {
		out << 'cross-profile component substitutions from ${resolution.visual_profile} to ${resolution.functional_profile}'
	}
	return out
}

fn ui_clone_nonblind_ignored_targets(resolution UiCloneSubjectResolution) []string {
	if resolution.mode != 'semantic_functional_clone' {
		return []string{}
	}
	return [
		'literal OCR text and copied runtime labels',
		'user files, prompt text, generated text, editor content, and session names',
		'screenshot similarity without command, action, state-delta, or live-event receipts',
		'visual reference behavior when a different functional profile is declared',
	]
}

fn ui_clone_nonblind_visual_match_kind(row UiCloneFunctionalUnderstandingRow) string {
	if row.visual_component == row.functional_component {
		return 'direct_functional_surface'
	}
	return 'cross_profile_visual_locus'
}

fn ui_clone_nonblind_runtime_policy(row UiCloneFunctionalUnderstandingRow) string {
	if row.runtime_data_masks.len == 0 {
		return 'compare structural labels only; no runtime text mask declared'
	}
	return 'mask runtime data: ${row.runtime_data_masks.join(', ')}'
}

fn ui_clone_nonblind_row_rejected(row UiCloneFunctionalUnderstandingRow) []string {
	mut out := row.rejected_evidence_kinds.clone()
	ui_clone_append_unique(mut out, 'visual_screenshot_without_functional_answer')
	return out
}

fn ui_clone_nonblind_visual_only_blocker(row UiCloneFunctionalUnderstandingRow) string {
	return 'screenshot/OCR similarity cannot answer ${row.functional_component}: ${row.functional_question}'
}

fn ui_clone_nonblind_row_certification(row UiCloneFunctionalUnderstandingRow) string {
	return 'answer the functional question with ${row.functional_owner_role}; expected delta: ${row.expected_state_delta}'
}

fn ui_clone_nonblind_accepted_evidence(plan UiCloneFunctionalClonePlan,
	rows []UiCloneNonblindReasoningBriefRow) []string {
	mut out := plan.accepted_evidence_kinds.clone()
	for row in rows {
		for item in row.accepted_evidence_kinds {
			ui_clone_append_unique(mut out, item)
		}
	}
	return out
}

fn ui_clone_nonblind_rejected_evidence(plan UiCloneFunctionalClonePlan,
	rows []UiCloneNonblindReasoningBriefRow) []string {
	mut out := plan.rejected_evidence_kinds.clone()
	for row in rows {
		for item in row.rejected_evidence_kinds {
			ui_clone_append_unique(mut out, item)
		}
	}
	return out
}

fn ui_clone_nonblind_certification_gate(blocker string) string {
	if blocker != '' {
		return 'blocked: ${blocker}'
	}
	return 'certify only after every functional question has accepted behavior evidence; pixels only locate the surface'
}

fn ui_clone_nonblind_ready_row_count(rows []UiCloneNonblindReasoningBriefRow) int {
	mut count := 0
	for row in rows {
		if row.nonblind_reasoning {
			count++
		}
	}
	return count
}
