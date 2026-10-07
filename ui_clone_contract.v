module vui_evidence

pub struct UiCloneTextPolicy {
pub:
	name                      string
	role                      string
	required                  bool = true
	compare_bounds            bool = true
	block_on_bounds           bool = true
	optional_when_absent_both bool
}

pub struct UiCloneTextDecision {
pub:
	ok             bool
	blocking       bool
	severity       string
	code           string
	role           string
	compare_bounds bool
	reason         string
}

pub struct UiCloneRegionPolicy {
pub:
	name                string
	role                string
	pixel_policy        string
	allows_dynamic_text bool
	requires_geometry   bool = true
}

pub struct UiCloneComponentPolicy {
pub:
	name             string
	region           string
	role             string
	required         bool = true
	compare_label    bool
	compare_geometry bool = true
	dynamic_content  bool
	parity_axis      string
	evidence         string
}

pub struct UiCloneContract {
pub:
	target_profile          string
	target_family           string
	source_product          string
	clone_intent            string
	mode                    string
	known_profile           bool
	reasoning_ready         bool
	blind_clone_blocker     string
	functional_paradigm     string
	reasoning_model         string
	semantic_scope          string
	text_comparison_policy  string
	runtime_evidence_policy string
	literal_clone_policy    string
	behavior_gate           string
	dynamic_content_policy  string
	native_surface_policy   string
	component_count         int
	affordance_count        int
	behavior_probe_count    int
}

pub struct UiCloneAffordancePolicy {
pub:
	name                    string
	component               string
	region                  string
	role                    string
	kind                    string
	required                bool = true
	visual_anchor           bool
	behavior_probe_required bool
	dynamic_content         bool
	compare_label           bool
	evidence                string
}

pub struct UiCloneAffordanceDecision {
pub:
	ok                bool
	blocking          bool
	severity          string
	code              string
	name              string
	component         string
	region            string
	role              string
	kind              string
	visual_evidence   bool
	behavior_evidence bool
	reason            string
}

pub fn ui_clone_contract(target_profile string, clone_intent string) UiCloneContract {
	profile := canonical_clone_profile(target_profile)
	intent := normalized_clone_value(clone_intent)
	mode := if intent in ['functional_ui_clone', 'functional_clone', 'ui_clone'] {
		'semantic_functional_clone'
	} else {
		'pixel_reference_clone'
	}
	semantic_profile := ui_clone_semantic_profile_for(profile, mode)
	known_profile := ui_clone_known_profile_for_mode(profile, mode)
	blind_clone_blocker := ui_clone_blind_clone_blocker_for(mode, known_profile)
	return UiCloneContract{
		target_profile:          profile
		target_family:           semantic_profile.family
		source_product:          semantic_profile.source_product
		clone_intent:            intent
		mode:                    mode
		known_profile:           known_profile
		reasoning_ready:         blind_clone_blocker == ''
		blind_clone_blocker:     blind_clone_blocker
		functional_paradigm:     semantic_profile.functional_paradigm
		reasoning_model:         ui_clone_reasoning_model(profile, mode)
		semantic_scope:          ui_clone_semantic_scope(profile, mode)
		text_comparison_policy:  ui_clone_text_comparison_policy(profile, mode)
		runtime_evidence_policy: ui_clone_runtime_evidence_policy(profile, mode)
		literal_clone_policy:    ui_clone_literal_clone_policy(profile, mode)
		behavior_gate:           ui_clone_behavior_gate(profile, mode)
		dynamic_content_policy:  semantic_profile.dynamic_content_policy
		native_surface_policy:   semantic_profile.native_surface_policy
		component_count:         ui_clone_component_policies_for(profile, mode).len
		affordance_count:        ui_clone_affordance_policies_for(profile, mode).len
		behavior_probe_count:    ui_clone_behavior_probe_policies_for(profile, mode).len
	}
}

pub fn ui_clone_text_policy(target_profile string, clone_intent string, name string) UiCloneTextPolicy {
	contract := ui_clone_contract(target_profile, clone_intent)
	clean := normalized_clone_value(name)
	if contract.mode == 'semantic_functional_clone' {
		if policy := ui_clone_dynamic_text_policy_for(contract.target_profile, clean, name) {
			return policy
		}
	}
	return UiCloneTextPolicy{
		name: name
		role: 'structural_text_anchor'
	}
}

pub fn decide_ui_clone_text(policy UiCloneTextPolicy, actual_found bool, reference_found bool,
	bounds_match bool) UiCloneTextDecision {
	if !actual_found && !reference_found {
		if policy.optional_when_absent_both {
			return text_decision(true, false, 'info', 'text_bbox.dynamic_absent', policy,
				'dynamic_text_absent_in_both_images')
		}
		return text_decision(false, true, 'critical', 'text_bbox.missing', policy,
			'text_anchor_missing_in_both_images')
	}
	if actual_found != reference_found {
		if policy.required {
			return text_decision(false, true, 'critical', 'text_bbox.missing', policy,
				'text_anchor_missing_in_one_image')
		}
		return text_decision(false, false, 'warning', 'text_bbox.dynamic_presence_mismatch',
			policy, 'dynamic_text_presence_differs')
	}
	if policy.compare_bounds && !bounds_match {
		return text_decision(false, policy.block_on_bounds, if policy.block_on_bounds {
			'critical'
		} else {
			'warning'
		}, 'text_bbox.drift', policy, 'text_anchor_bounds_differ')
	}
	return text_decision(true, false, 'info', '', policy, 'ok')
}

pub fn ui_clone_region_policy(target_profile string, clone_intent string, name string) UiCloneRegionPolicy {
	contract := ui_clone_contract(target_profile, clone_intent)
	clean := normalized_clone_value(name)
	if contract.mode == 'semantic_functional_clone' {
		if policy := ui_clone_region_policy_for_profile(contract.target_profile, clean, name) {
			return policy
		}
	}
	return UiCloneRegionPolicy{name, 'pixel_region', 'pixel_reference', false, true}
}

pub fn ui_clone_component_policies(target_profile string, clone_intent string) []UiCloneComponentPolicy {
	contract := ui_clone_contract(target_profile, clone_intent)
	return ui_clone_component_policies_for(contract.target_profile, contract.mode)
}

pub fn ui_clone_affordance_policies(target_profile string, clone_intent string) []UiCloneAffordancePolicy {
	contract := ui_clone_contract(target_profile, clone_intent)
	return ui_clone_affordance_policies_for(contract.target_profile, contract.mode)
}

pub fn decide_ui_clone_affordance(policy UiCloneAffordancePolicy, region_present bool,
	visual_evidence bool, behavior_evidence bool) UiCloneAffordanceDecision {
	if !region_present {
		return affordance_decision(false, true, 'critical', 'affordance.region_missing', policy,
			visual_evidence, behavior_evidence, 'functional_region_not_present')
	}
	if policy.behavior_probe_required && !behavior_evidence {
		return affordance_decision(true, false, 'warning', 'affordance.behavior_evidence_pending',
			policy, visual_evidence, behavior_evidence,
			'visual_capture_cannot_certify_interaction_behavior')
	}
	if policy.visual_anchor && !visual_evidence {
		return affordance_decision(false, false, 'warning', 'affordance.visual_evidence_low',
			policy, visual_evidence, behavior_evidence, 'functional_anchor_has_low_visual_signal')
	}
	return affordance_decision(true, false, 'info', '', policy, visual_evidence, behavior_evidence,
		'ok')
}

fn ui_clone_component_policies_for(profile string, mode string) []UiCloneComponentPolicy {
	if mode == 'semantic_functional_clone' {
		return ui_clone_profile_component_policies(profile)
	}
	return []UiCloneComponentPolicy{}
}

fn ui_clone_affordance_policies_for(profile string, mode string) []UiCloneAffordancePolicy {
	if mode == 'semantic_functional_clone' {
		return ui_clone_profile_affordance_policies(profile)
	}
	return []UiCloneAffordancePolicy{}
}

fn vscode_functional_components() []UiCloneComponentPolicy {
	return [
		UiCloneComponentPolicy{
			name:             'window.frame'
			region:           'top_chrome'
			role:             'native_window_management'
			compare_geometry: true
			parity_axis:      'move_resize_minimize_maximize_close'
			evidence:         'frame controls must behave like a desktop window'
		},
		UiCloneComponentPolicy{
			name:             'command.center'
			region:           'top_chrome'
			role:             'global_command_entry'
			compare_geometry: true
			dynamic_content:  true
			parity_axis:      'commands_search_navigation'
			evidence:         'label text may vary; command invocation role must exist'
		},
		UiCloneComponentPolicy{
			name:             'activity.rail'
			region:           'side_rail'
			role:             'primary_view_switcher'
			compare_geometry: true
			parity_axis:      'explorer_search_scm_run_extensions'
			evidence:         'icons select workbench views without copying glyph text'
		},
		UiCloneComponentPolicy{
			name:             'explorer.tree'
			region:           'sidebar_panel'
			role:             'workspace_navigation_tree'
			compare_geometry: true
			dynamic_content:  true
			parity_axis:      'workspace_file_discovery_and_actions'
			evidence:         'project names and rows are data, not clone literals'
		},
		UiCloneComponentPolicy{
			name:             'editor.surface'
			region:           'content_page'
			role:             'editable_document_surface'
			compare_geometry: true
			dynamic_content:  true
			parity_axis:      'text_editing_tabs_webviews_notebooks'
			evidence:         'document content is dynamic; editor affordances must align'
		},
		UiCloneComponentPolicy{
			name:             'status.indicators'
			region:           'status_bar'
			role:             'diagnostics_branch_remote_notifications'
			compare_geometry: true
			dynamic_content:  true
			parity_axis:      'workspace_state_feedback'
			evidence:         'status slots must exist even when values differ'
		},
	]
}

fn vscode_functional_affordances() []UiCloneAffordancePolicy {
	return [
		visual_affordance('window.frame.geometry', 'window.frame', 'top_chrome',
			'native_frame_layout', false,
			'titlebar, menu, command entry, and control slots align with the desktop shell'),
		behavior_affordance('window.frame.controls', 'window.frame', 'top_chrome',
			'native_window_control_behavior',
			'move, resize, minimize, maximize, close, and tray transparency must be probed'),
		visual_affordance('command.center.slot', 'command.center', 'top_chrome',
			'global_command_entry_slot', true,
			'command text may vary but the command entry locus must remain discoverable'),
		behavior_affordance('command.center.invoke', 'command.center', 'top_chrome',
			'global_command_invocation',
			'command palette, quick open, search, and navigation calls need behavior evidence'),
		visual_affordance('activity.rail.targets', 'activity.rail', 'side_rail',
			'primary_view_targets', false,
			'explorer, search, scm, run, and extension targets align as icon affordances'),
		visual_affordance('activity.rail.account', 'activity.rail', 'side_rail',
			'account_profile_target', false,
			'account/profile target must exist; absence is not a valid low-pixel shortcut'),
		visual_affordance('activity.rail.manage', 'activity.rail', 'side_rail',
			'manage_settings_target', false,
			'manage/settings target must exist below primary view targets'),
		behavior_affordance('activity.rail.switch_views', 'activity.rail', 'side_rail',
			'workbench_view_switching',
			'icons must switch views and preserve active/hover/keyboard state'),
		visual_affordance('explorer.tree.hierarchy', 'explorer.tree', 'sidebar_panel',
			'workspace_tree_layout', true,
			'workspace names and file rows are data, not literal clone requirements'),
		behavior_affordance('explorer.tree.navigate', 'explorer.tree', 'sidebar_panel',
			'workspace_navigation_behavior',
			'open, reveal, context menu, drag, rename, and keyboard tree flow need probes'),
		visual_affordance('editor.surface.canvas', 'editor.surface', 'content_page',
			'editable_document_canvas', true,
			'document text is dynamic while editor geometry and affordance zones remain stable'),
		behavior_affordance('editor.surface.editing', 'editor.surface', 'content_page',
			'editor_interaction_model',
			'tabs, edits, selections, undo, webviews, notebooks, and diagnostics need probes'),
		visual_affordance('status.indicators.slots', 'status.indicators', 'status_bar',
			'workspace_state_slots', true,
			'branch, diagnostics, remote, language, and notification slots may hold different data'),
		behavior_affordance('status.indicators.live_state', 'status.indicators', 'status_bar',
			'workspace_state_behavior',
			'status values must update from workspace events instead of copied labels'),
	]
}

fn visual_affordance(name string, component string, region string, role string, dynamic bool,
	evidence string) UiCloneAffordancePolicy {
	return UiCloneAffordancePolicy{
		name:            name
		component:       component
		region:          region
		role:            role
		kind:            'visual_structure'
		visual_anchor:   true
		dynamic_content: dynamic
		compare_label:   !dynamic
		evidence:        evidence
	}
}

fn behavior_affordance(name string, component string, region string, role string,
	evidence string) UiCloneAffordancePolicy {
	return UiCloneAffordancePolicy{
		name:                    name
		component:               component
		region:                  region
		role:                    role
		kind:                    'behavior_probe'
		behavior_probe_required: true
		compare_label:           false
		evidence:                evidence
	}
}

fn ui_clone_reasoning_model(profile string, mode string) string {
	return ui_clone_semantic_profile_for(profile, mode).reasoning_model
}

fn ui_clone_semantic_scope(profile string, mode string) string {
	return ui_clone_semantic_profile_for(profile, mode).semantic_scope
}

fn ui_clone_text_comparison_policy(profile string, mode string) string {
	return ui_clone_semantic_profile_for(profile, mode).text_policy
}

fn ui_clone_runtime_evidence_policy(profile string, mode string) string {
	return ui_clone_semantic_profile_for(profile, mode).runtime_evidence_policy
}

fn ui_clone_literal_clone_policy(profile string, mode string) string {
	return ui_clone_semantic_profile_for(profile, mode).literal_clone_policy
}

fn ui_clone_behavior_gate(profile string, mode string) string {
	return ui_clone_semantic_profile_for(profile, mode).behavior_gate
}

pub fn ui_clone_known_functional_profile(target_profile string) bool {
	return canonical_clone_profile(target_profile) in ['vscode', 'vexplorer', 'antigravity']
}

pub fn ui_clone_functional_contract_ready(target_profile string, clone_intent string) bool {
	return ui_clone_contract(target_profile, clone_intent).reasoning_ready
}

fn ui_clone_known_profile_for_mode(profile string, mode string) bool {
	if mode == 'semantic_functional_clone' {
		return ui_clone_known_functional_profile(profile)
	}
	return canonical_clone_profile(profile) != ''
}

fn ui_clone_blind_clone_blocker_for(mode string, known_profile bool) string {
	if mode == 'semantic_functional_clone' && !known_profile {
		return 'functional_clone_target_profile_unknown'
	}
	return ''
}

fn text_decision(ok bool, blocking bool, severity string, code string, policy UiCloneTextPolicy,
	reason string) UiCloneTextDecision {
	return UiCloneTextDecision{
		ok:             ok
		blocking:       blocking
		severity:       severity
		code:           code
		role:           policy.role
		compare_bounds: policy.compare_bounds
		reason:         reason
	}
}

fn affordance_decision(ok bool, blocking bool, severity string, code string,
	policy UiCloneAffordancePolicy, visual_evidence bool, behavior_evidence bool,
	reason string) UiCloneAffordanceDecision {
	return UiCloneAffordanceDecision{
		ok:                ok
		blocking:          blocking
		severity:          severity
		code:              code
		name:              policy.name
		component:         policy.component
		region:            policy.region
		role:              policy.role
		kind:              policy.kind
		visual_evidence:   visual_evidence
		behavior_evidence: behavior_evidence
		reason:            reason
	}
}

fn normalized_clone_value(value string) string {
	return value.trim_space().to_lower().replace('-', '_').replace(' ', '_')
}
