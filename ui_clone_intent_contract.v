module vui_evidence

pub struct UiCloneIntentSurfaceContract {
pub:
	region                       string
	component                    string
	role                         string
	parity_axis                  string
	visual_compare_mode          string
	geometry_required            bool
	label_compare_required       bool
	literal_text_is_runtime_data bool
	stable_anchors               []string
	runtime_data_masks           []string
	required_behaviors           []string
	behavior_probe_affordances   []string
	accepted_evidence_kinds      []string
	rejected_evidence_kinds      []string
	certification_gate           string
	background_safe              bool
}

pub struct UiCloneIntentContract {
pub:
	target_profile                string
	source_product                string
	clone_intent                  string
	mode                          string
	ready                         bool
	blind_clone_blocker           string
	functional_clone              bool
	nonblind_reasoning_required   bool
	literal_text_can_certify      bool
	literal_text_is_runtime_data  bool
	dynamic_text_must_be_masked   bool
	visual_match_is_sufficient    bool
	requires_runtime_behavior     bool
	background_safe_probe_count   int
	stable_anchor_count           int
	runtime_data_mask_count       int
	required_behavior_count       int
	required_behavior_probe_count int
	surface_count                 int
	accepted_evidence_kinds       []string
	rejected_evidence_kinds       []string
	certification_gate            string
	surfaces                      []UiCloneIntentSurfaceContract
}

pub fn ui_clone_intent_contract(target_profile string,
	clone_intent string) UiCloneIntentContract {
	contract := ui_clone_contract(target_profile, clone_intent)
	alignments := ui_clone_semantic_alignment(contract.target_profile, contract.clone_intent)
	functional := contract.mode == 'semantic_functional_clone'
	mut surfaces := []UiCloneIntentSurfaceContract{}
	for row in alignments {
		surfaces << ui_clone_intent_surface_contract(row)
	}
	return UiCloneIntentContract{
		target_profile:                contract.target_profile
		source_product:                contract.source_product
		clone_intent:                  contract.clone_intent
		mode:                          contract.mode
		ready:                         contract.reasoning_ready
		blind_clone_blocker:           contract.blind_clone_blocker
		functional_clone:              functional
		nonblind_reasoning_required:   functional
		literal_text_can_certify:      !functional
		literal_text_is_runtime_data:  functional
		dynamic_text_must_be_masked:   functional && ui_clone_intent_mask_count(surfaces) > 0
		visual_match_is_sufficient:    !functional
		requires_runtime_behavior:     functional && ui_clone_intent_probe_count(surfaces) > 0
		background_safe_probe_count:   ui_clone_intent_background_safe_count(surfaces)
		stable_anchor_count:           ui_clone_intent_anchor_count(surfaces)
		runtime_data_mask_count:       ui_clone_intent_mask_count(surfaces)
		required_behavior_count:       ui_clone_intent_behavior_count(surfaces)
		required_behavior_probe_count: ui_clone_intent_probe_count(surfaces)
		surface_count:                 surfaces.len
		accepted_evidence_kinds:       ui_clone_intent_accepted_evidence(functional)
		rejected_evidence_kinds:       ui_clone_intent_rejected_evidence(functional)
		certification_gate:            ui_clone_intent_certification_gate(contract, surfaces)
		surfaces:                      surfaces
	}
}

pub fn ui_clone_intent_contract_for_component(target_profile string, clone_intent string,
	component string) ?UiCloneIntentSurfaceContract {
	clean := normalized_clone_value(component)
	for surface in ui_clone_intent_contract(target_profile, clone_intent).surfaces {
		if normalized_clone_value(surface.component) == clean {
			return surface
		}
	}
	return none
}

fn ui_clone_intent_surface_contract(row UiCloneSemanticAlignmentRow) UiCloneIntentSurfaceContract {
	literal_runtime := row.dynamic_content || row.mask_runtime_data.len > 0
	return UiCloneIntentSurfaceContract{
		region:                       row.region
		component:                    row.component
		role:                         row.role
		parity_axis:                  row.parity_axis
		visual_compare_mode:          ui_clone_intent_visual_mode(row)
		geometry_required:            row.compare_geometry
		label_compare_required:       row.compare_label && !literal_runtime
		literal_text_is_runtime_data: literal_runtime
		stable_anchors:               row.match_invariants
		runtime_data_masks:           row.mask_runtime_data
		required_behaviors:           row.required_behaviors
		behavior_probe_affordances:   row.behavior_probe_affordances
		accepted_evidence_kinds:      ui_clone_intent_surface_accepted_evidence(row)
		rejected_evidence_kinds:      ui_clone_intent_surface_rejected_evidence(row)
		certification_gate:           ui_clone_intent_surface_gate(row)
		background_safe:              row.behavior_probe_count == row.background_safe_probe_count
	}
}

fn ui_clone_intent_visual_mode(row UiCloneSemanticAlignmentRow) string {
	if row.pixel_policy == 'functional_layout' {
		return 'stable_geometry_with_runtime_text_masks'
	}
	if row.dynamic_content {
		return 'stable_geometry_dynamic_content_masked'
	}
	return 'stable_geometry_and_structural_anchors'
}

fn ui_clone_intent_surface_accepted_evidence(row UiCloneSemanticAlignmentRow) []string {
	mut kinds := [
		'segmented_region_bounds',
		'stable_affordance_geometry',
		'semantic_role_match',
	]
	if row.behavior_probe_count > 0 {
		kinds << 'atomic_behavior_probe'
		kinds << 'runtime_state_delta'
		kinds << 'live_event_receipt'
	}
	return kinds
}

fn ui_clone_intent_surface_rejected_evidence(row UiCloneSemanticAlignmentRow) []string {
	mut kinds := [
		'whole_screenshot_similarity_only',
		'copied_static_mockup',
	]
	if row.dynamic_content {
		kinds << 'literal_runtime_text_match'
		kinds << 'ocr_label_match_as_behavior'
	}
	if row.behavior_probe_count > 0 {
		kinds << 'visual_affordance_without_state_delta'
	}
	return kinds
}

fn ui_clone_intent_surface_gate(row UiCloneSemanticAlignmentRow) string {
	if row.behavior_probe_count > 0 {
		return 'require geometry, role, masked runtime data, and ${row.behavior_probe_count} behavior probe(s)'
	}
	return 'require geometry and semantic role; literal runtime data cannot certify this surface'
}

fn ui_clone_intent_accepted_evidence(functional bool) []string {
	if !functional {
		return ['reference_screenshot', 'segmented_pixel_match']
	}
	return [
		'segmented_region_bounds',
		'stable_affordance_geometry',
		'semantic_role_match',
		'atomic_behavior_probe',
		'runtime_state_delta',
		'live_event_receipt',
	]
}

fn ui_clone_intent_rejected_evidence(functional bool) []string {
	if !functional {
		return ['missing_reference_for_pixel_claim']
	}
	return [
		'whole_screenshot_similarity_only',
		'copied_static_mockup',
		'copied_ocr_text',
		'literal_runtime_text_match',
		'visual_affordance_without_state_delta',
	]
}

fn ui_clone_intent_certification_gate(contract UiCloneContract,
	surfaces []UiCloneIntentSurfaceContract) string {
	if contract.mode != 'semantic_functional_clone' {
		return 'visual clone: segmented pixel evidence can certify only against a reference'
	}
	if contract.blind_clone_blocker != '' {
		return 'blocked: ${contract.blind_clone_blocker}'
	}
	if ui_clone_intent_probe_count(surfaces) == 0 {
		return 'blocked: no atomic behavior probes are defined for this functional clone profile'
	}
	return 'functional clone: certify by semantic intent, stable visual anchors, runtime data masks, and atomic behavior receipts'
}

fn ui_clone_intent_anchor_count(surfaces []UiCloneIntentSurfaceContract) int {
	mut count := 0
	for surface in surfaces {
		count += surface.stable_anchors.len
	}
	return count
}

fn ui_clone_intent_mask_count(surfaces []UiCloneIntentSurfaceContract) int {
	mut count := 0
	for surface in surfaces {
		count += surface.runtime_data_masks.len
	}
	return count
}

fn ui_clone_intent_behavior_count(surfaces []UiCloneIntentSurfaceContract) int {
	mut count := 0
	for surface in surfaces {
		count += surface.required_behaviors.len
	}
	return count
}

fn ui_clone_intent_probe_count(surfaces []UiCloneIntentSurfaceContract) int {
	mut count := 0
	for surface in surfaces {
		count += surface.behavior_probe_affordances.len
	}
	return count
}

fn ui_clone_intent_background_safe_count(surfaces []UiCloneIntentSurfaceContract) int {
	mut count := 0
	for surface in surfaces {
		if surface.background_safe {
			count += surface.behavior_probe_affordances.len
		}
	}
	return count
}
