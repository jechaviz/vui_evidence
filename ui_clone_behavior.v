module vui_evidence

pub struct UiCloneBehaviorProbePolicy {
pub:
	name                 string
	affordance           string
	component            string
	region               string
	action               string
	expected_state_delta string
	evidence_key         string
	evidence_channel     string
	background_safe      bool = true
	required             bool = true
}

pub struct UiCloneBehaviorProbeDecision {
pub:
	ok                   bool
	blocking             bool
	severity             string
	code                 string
	name                 string
	affordance           string
	component            string
	region               string
	action               string
	expected_state_delta string
	evidence_found       bool
	evidence_ok          bool
	reason               string
}

pub fn ui_clone_behavior_probe_policies(target_profile string, clone_intent string) []UiCloneBehaviorProbePolicy {
	contract := ui_clone_contract(target_profile, clone_intent)
	return ui_clone_behavior_probe_policies_for(contract.target_profile, contract.mode)
}

pub fn ui_clone_behavior_probe_for_affordance(target_profile string, clone_intent string,
	affordance string) ?UiCloneBehaviorProbePolicy {
	clean := normalized_clone_value(affordance)
	for probe in ui_clone_behavior_probe_policies(target_profile, clone_intent) {
		if normalized_clone_value(probe.affordance) == clean {
			return probe
		}
	}
	return none
}

pub fn decide_ui_clone_behavior_probe(policy UiCloneBehaviorProbePolicy, evidence_found bool,
	evidence_ok bool) UiCloneBehaviorProbeDecision {
	if !evidence_found {
		return behavior_probe_decision(false, false, 'warning', 'behavior_probe.missing', policy,
			evidence_found, evidence_ok,
			'visual_capture_cannot_prove_this_interaction_without_an_atomic_probe')
	}
	if !evidence_ok {
		return behavior_probe_decision(false, true, 'critical', 'behavior_probe.failed', policy,
			evidence_found, evidence_ok,
			'atomic_probe_evidence_reports_the_interaction_did_not_match')
	}
	return behavior_probe_decision(true, false, 'info', '', policy, evidence_found, evidence_ok,
		'ok')
}

fn ui_clone_behavior_probe_policies_for(profile string, mode string) []UiCloneBehaviorProbePolicy {
	if mode == 'semantic_functional_clone' {
		return match canonical_clone_profile(profile) {
			'vscode' { vscode_behavior_probe_policies() }
			'vexplorer' { vexplorer_behavior_probe_policies() }
			'antigravity' { antigravity_behavior_probe_policies() }
			else { []UiCloneBehaviorProbePolicy{} }
		}
	}
	return []UiCloneBehaviorProbePolicy{}
}

fn vscode_behavior_probe_policies() []UiCloneBehaviorProbePolicy {
	return [
		behavior_probe('window.frame.controls', 'window.frame', 'top_chrome',
			'move_resize_minimize_restore_close_probe',
			'window_bounds_and_state_change_with_native_controls'),
		behavior_probe('command.center.invoke', 'command.center', 'top_chrome',
			'invoke_quick_open_and_command_palette',
			'command_list_opens_filters_and_dispatches_selected_command'),
		behavior_probe('activity.rail.switch_views', 'activity.rail', 'side_rail',
			'switch_explorer_search_scm_run_extensions',
			'active_view_id_changes_and_sidebar_content_updates'),
		behavior_probe('explorer.tree.navigate', 'explorer.tree', 'sidebar_panel',
			'open_reveal_context_menu_rename_drag_keyboard',
			'workspace_tree_selection_file_open_and_actions_update_state'),
		behavior_probe('editor.surface.editing', 'editor.surface', 'content_page',
			'open_file_edit_select_undo_dirty_state',
			'text_model_selection_dirty_marker_and_undo_stack_update'),
		behavior_probe('status.indicators.live_state', 'status.indicators', 'status_bar',
			'emit_git_diagnostic_language_notification_events',
			'status_slots_update_from_workspace_events_not_static_labels'),
	]
}

fn behavior_probe(affordance string, component string, region string, action string,
	expected_state_delta string) UiCloneBehaviorProbePolicy {
	return UiCloneBehaviorProbePolicy{
		name:                 '${affordance}.probe'
		affordance:           affordance
		component:            component
		region:               region
		action:               action
		expected_state_delta: expected_state_delta
		evidence_key:         'behavior_evidence.${affordance}'
		evidence_channel:     'waibav_atomic_behavior_probe'
	}
}

fn behavior_probe_decision(ok bool, blocking bool, severity string, code string,
	policy UiCloneBehaviorProbePolicy, evidence_found bool, evidence_ok bool,
	reason string) UiCloneBehaviorProbeDecision {
	return UiCloneBehaviorProbeDecision{
		ok:                   ok
		blocking:             blocking
		severity:             severity
		code:                 code
		name:                 policy.name
		affordance:           policy.affordance
		component:            policy.component
		region:               policy.region
		action:               policy.action
		expected_state_delta: policy.expected_state_delta
		evidence_found:       evidence_found
		evidence_ok:          evidence_ok
		reason:               reason
	}
}
