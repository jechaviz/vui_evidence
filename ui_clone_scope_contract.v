module vui_evidence

pub struct UiCloneScopeContract {
pub:
	visual_profile           string
	functional_profile       string
	clone_intent             string
	mode                     string
	cross_profile            bool
	known_visual_profile     bool
	known_functional_profile bool
	ready                    bool
	blocker                  string
	visual_reference_role    string
	functional_target_role   string
	text_policy              string
	evidence_policy          string
	certification_rule       string
	accepted_evidence_kinds  []string
	rejected_evidence_kinds  []string
}

pub fn ui_clone_scope_contract(visual_reference_profile string, functional_target_profile string,
	clone_intent string) UiCloneScopeContract {
	intent := normalized_clone_value(clone_intent)
	mode := if intent in ['functional_ui_clone', 'functional_clone', 'ui_clone'] {
		'semantic_functional_clone'
	} else {
		'pixel_reference_clone'
	}
	visual := ui_clone_scope_visual_profile(visual_reference_profile, functional_target_profile)
	functional := ui_clone_scope_functional_profile(visual, functional_target_profile)
	known_visual := visual != ''
	known_functional := if mode == 'semantic_functional_clone' {
		ui_clone_known_functional_profile(functional)
	} else {
		functional != ''
	}
	blocker := if mode == 'semantic_functional_clone' && !known_functional {
		'functional_clone_target_profile_unknown'
	} else {
		''
	}
	cross_profile := visual != '' && functional != '' && visual != functional
	return UiCloneScopeContract{
		visual_profile:           visual
		functional_profile:       functional
		clone_intent:             intent
		mode:                     mode
		cross_profile:            cross_profile
		known_visual_profile:     known_visual
		known_functional_profile: known_functional
		ready:                    blocker == ''
		blocker:                  blocker
		visual_reference_role:    ui_clone_scope_visual_role(mode, cross_profile)
		functional_target_role:   ui_clone_scope_functional_role(mode)
		text_policy:              ui_clone_scope_text_policy(mode, cross_profile)
		evidence_policy:          ui_clone_scope_evidence_policy(mode)
		certification_rule:       ui_clone_scope_certification_rule(mode, cross_profile)
		accepted_evidence_kinds:  ui_clone_scope_accepted_evidence(mode)
		rejected_evidence_kinds:  ui_clone_scope_rejected_evidence(mode)
	}
}

pub fn ui_clone_scope_effective_functional_profile(visual_reference_profile string,
	functional_target_profile string) string {
	visual := ui_clone_scope_visual_profile(visual_reference_profile, functional_target_profile)
	return ui_clone_scope_functional_profile(visual, functional_target_profile)
}

fn ui_clone_scope_visual_profile(visual_reference_profile string, functional_target_profile string) string {
	visual := canonical_clone_profile(visual_reference_profile)
	if visual != '' {
		return visual
	}
	return canonical_clone_profile(functional_target_profile)
}

fn ui_clone_scope_functional_profile(visual string, functional_target_profile string) string {
	functional := canonical_clone_profile(functional_target_profile)
	if functional != '' {
		return functional
	}
	return visual
}

fn ui_clone_scope_visual_role(mode string, cross_profile bool) string {
	if mode != 'semantic_functional_clone' {
		return 'pixel_reference_contract'
	}
	if cross_profile {
		return 'visual_reference_supplies_geometry_landmarks_and_affordance_loci_only'
	}
	return 'visual_reference_supplies_stable_geometry_and_affordance_loci'
}

fn ui_clone_scope_functional_role(mode string) string {
	if mode != 'semantic_functional_clone' {
		return 'visual_reference_only'
	}
	return 'functional_target_owns_behavior_probes_runtime_state_and_dynamic_data_masks'
}

fn ui_clone_scope_text_policy(mode string, cross_profile bool) string {
	if mode != 'semantic_functional_clone' {
		return 'visible_text_is_reference_content'
	}
	if cross_profile {
		return 'mask_runtime_text_from_visual_reference_and_apply_functional_profile_dynamic_data_rules'
	}
	return 'mask_runtime_text_and_compare_only_structural_labels'
}

fn ui_clone_scope_evidence_policy(mode string) string {
	if mode != 'semantic_functional_clone' {
		return 'segmented_pixels_and_text_bounds_can_certify_visual_similarity'
	}
	return 'functional_claims_require atomic behavior probes, commands, state deltas, or live runtime events'
}

fn ui_clone_scope_certification_rule(mode string, cross_profile bool) string {
	if mode != 'semantic_functional_clone' {
		return 'certify visual parity from real reference screenshots and segment thresholds'
	}
	if cross_profile {
		return 'certify cross-profile clone only when visual landmarks pass and functional target probes pass'
	}
	return 'certify functional clone only when semantic surfaces and all required behavior probes pass'
}

fn ui_clone_scope_accepted_evidence(mode string) []string {
	if mode != 'semantic_functional_clone' {
		return ['reference_screenshot', 'segmented_region_diff', 'text_bbox']
	}
	return [
		'runtime_behavior_signals',
		'behavior_probe_results',
		'atomic_behavior_probe',
		'command_action_state_delta_receipt',
		'app_navigation_surface_model',
	]
}

fn ui_clone_scope_rejected_evidence(mode string) []string {
	if mode != 'semantic_functional_clone' {
		return []string{}
	}
	return [
		'copied_ocr_text',
		'literal_screenshot_text',
		'static_mockup',
		'pixel_match_without_behavior',
		'label_match_without_state_delta',
	]
}
