module vui_evidence

pub struct UiCloneSemanticAlignmentRow {
pub:
	region                      string
	component                   string
	role                        string
	parity_axis                 string
	pixel_policy                string
	compare_geometry            bool
	compare_label               bool
	dynamic_content             bool
	match_invariants            []string
	mask_runtime_data           []string
	required_behaviors          []string
	behavior_probe_affordances  []string
	behavior_probe_count        int
	background_safe_probe_count int
	certification_rule          string
	blind_clone_rejection       string
}

pub struct UiCloneSemanticAlignmentSummary {
pub:
	target_profile              string
	source_product              string
	clone_intent                string
	mode                        string
	ready                       bool
	blind_clone_blocker         string
	row_count                   int
	match_invariant_count       int
	masked_runtime_data_count   int
	required_behavior_count     int
	behavior_probe_count        int
	background_safe_probe_count int
	literal_text_can_certify    bool
	certification_rule          string
}

pub fn ui_clone_semantic_alignment(target_profile string,
	clone_intent string) []UiCloneSemanticAlignmentRow {
	contract := ui_clone_contract(target_profile, clone_intent)
	if contract.mode != 'semantic_functional_clone' || !contract.reasoning_ready {
		return []UiCloneSemanticAlignmentRow{}
	}
	components := ui_clone_component_policies(contract.target_profile, contract.clone_intent)
	probes := ui_clone_behavior_probe_policies(contract.target_profile, contract.clone_intent)
	mut rows := []UiCloneSemanticAlignmentRow{}
	for surface in ui_clone_semantic_surfaces(contract.target_profile, contract.clone_intent) {
		component := ui_clone_alignment_component_policy(components, surface.component) or {
			UiCloneComponentPolicy{
				name:             surface.component
				region:           surface.region
				role:             surface.role
				compare_geometry: true
				dynamic_content:  surface.dynamic_data.len > 0
				parity_axis:      surface.role
				evidence:         'semantic surface contract'
			}
		}
		row_probes := ui_clone_alignment_probes_for_component(probes, surface.component)
		region_policy := ui_clone_region_policy(contract.target_profile, contract.clone_intent,
			surface.region)
		rows << UiCloneSemanticAlignmentRow{
			region:                      surface.region
			component:                   surface.component
			role:                        surface.role
			parity_axis:                 component.parity_axis
			pixel_policy:                region_policy.pixel_policy
			compare_geometry:            component.compare_geometry
			compare_label:               component.compare_label && !component.dynamic_content
			dynamic_content:             component.dynamic_content || surface.dynamic_data.len > 0
			match_invariants:            surface.stable_invariants
			mask_runtime_data:           surface.dynamic_data
			required_behaviors:          surface.required_behaviors
			behavior_probe_affordances:  row_probes.map(it.affordance)
			behavior_probe_count:        row_probes.len
			background_safe_probe_count: row_probes.filter(it.background_safe).len
			certification_rule:          ui_clone_alignment_certification_rule(component,
				row_probes)
			blind_clone_rejection:       ui_clone_alignment_blind_rejection(surface)
		}
	}
	return rows
}

pub fn ui_clone_semantic_alignment_summary(target_profile string,
	clone_intent string) UiCloneSemanticAlignmentSummary {
	contract := ui_clone_contract(target_profile, clone_intent)
	rows := ui_clone_semantic_alignment(contract.target_profile, contract.clone_intent)
	return UiCloneSemanticAlignmentSummary{
		target_profile:              contract.target_profile
		source_product:              contract.source_product
		clone_intent:                contract.clone_intent
		mode:                        contract.mode
		ready:                       contract.reasoning_ready
		blind_clone_blocker:         contract.blind_clone_blocker
		row_count:                   rows.len
		match_invariant_count:       ui_clone_alignment_match_count(rows)
		masked_runtime_data_count:   ui_clone_alignment_mask_count(rows)
		required_behavior_count:     ui_clone_alignment_behavior_count(rows)
		behavior_probe_count:        ui_clone_alignment_probe_count(rows)
		background_safe_probe_count: ui_clone_alignment_background_probe_count(rows)
		literal_text_can_certify:    contract.mode != 'semantic_functional_clone'
		certification_rule:          ui_clone_alignment_summary_rule(contract)
	}
}

pub fn ui_clone_semantic_alignment_for_component(target_profile string, clone_intent string,
	component string) ?UiCloneSemanticAlignmentRow {
	clean := normalized_clone_value(component)
	for row in ui_clone_semantic_alignment(target_profile, clone_intent) {
		if normalized_clone_value(row.component) == clean {
			return row
		}
	}
	return none
}

fn ui_clone_alignment_component_policy(components []UiCloneComponentPolicy,
	component string) ?UiCloneComponentPolicy {
	clean := normalized_clone_value(component)
	for item in components {
		if normalized_clone_value(item.name) == clean {
			return item
		}
	}
	return none
}

fn ui_clone_alignment_probes_for_component(probes []UiCloneBehaviorProbePolicy,
	component string) []UiCloneBehaviorProbePolicy {
	clean := normalized_clone_value(component)
	mut out := []UiCloneBehaviorProbePolicy{}
	for probe in probes {
		if normalized_clone_value(probe.component) == clean {
			out << probe
		}
	}
	return out
}

fn ui_clone_alignment_certification_rule(component UiCloneComponentPolicy,
	probes []UiCloneBehaviorProbePolicy) string {
	if probes.len == 0 {
		return 'certify ${component.name} by stable geometry, role, and non-runtime structural anchors'
	}
	return 'certify ${component.name} by stable geometry, role, and ${probes.len} atomic behavior probe(s) with state deltas or live events'
}

fn ui_clone_alignment_blind_rejection(surface UiCloneSemanticSurface) string {
	if surface.dynamic_data.len == 0 {
		return 'copied screenshots, OCR, or labels cannot replace role and geometry evidence'
	}
	return 'copied screenshots, OCR, labels, or runtime text (${surface.dynamic_data.join(', ')}) cannot certify ${surface.component}'
}

fn ui_clone_alignment_summary_rule(contract UiCloneContract) string {
	if contract.mode != 'semantic_functional_clone' {
		return 'visual-only references can be scored by segmented pixels'
	}
	if contract.blind_clone_blocker != '' {
		return 'blocked until a known functional target profile defines semantic surfaces'
	}
	return 'functional parity requires semantic surface alignment plus behavior probes; literal text is runtime data'
}

fn ui_clone_alignment_match_count(rows []UiCloneSemanticAlignmentRow) int {
	mut count := 0
	for row in rows {
		count += row.match_invariants.len
	}
	return count
}

fn ui_clone_alignment_mask_count(rows []UiCloneSemanticAlignmentRow) int {
	mut count := 0
	for row in rows {
		count += row.mask_runtime_data.len
	}
	return count
}

fn ui_clone_alignment_behavior_count(rows []UiCloneSemanticAlignmentRow) int {
	mut count := 0
	for row in rows {
		count += row.required_behaviors.len
	}
	return count
}

fn ui_clone_alignment_probe_count(rows []UiCloneSemanticAlignmentRow) int {
	mut count := 0
	for row in rows {
		count += row.behavior_probe_count
	}
	return count
}

fn ui_clone_alignment_background_probe_count(rows []UiCloneSemanticAlignmentRow) int {
	mut count := 0
	for row in rows {
		count += row.background_safe_probe_count
	}
	return count
}
