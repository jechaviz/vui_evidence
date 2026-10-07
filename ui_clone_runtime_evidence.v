module vui_evidence

pub struct UiCloneRuntimeSignal {
pub:
	id          string
	affordance  string
	component   string
	command_id  string
	action_id   string
	state_delta string
	surface     string
	region      string
	source      string
	status      string
	metadata    map[string]string
	ok          bool = true
}

pub struct UiCloneRuntimeProbeEvidence {
pub:
	found             bool
	ok                bool
	source            string
	matched_signal_id string
	semantic_class    string
	semantic_reason   string
	reason            string
}

pub struct UiCloneRuntimeSignalSemanticDecision {
pub:
	accepted       bool
	class          string
	reason         string
	functional_cue bool
	visual_only    bool
}

pub fn ui_clone_behavior_probe_decisions_from_runtime(target_profile string, clone_intent string,
	signals []UiCloneRuntimeSignal) []UiCloneBehaviorProbeDecision {
	mut out := []UiCloneBehaviorProbeDecision{}
	for policy in ui_clone_behavior_probe_policies(target_profile, clone_intent) {
		evidence := ui_clone_runtime_evidence_for_probe(policy, signals)
		out << decide_ui_clone_behavior_probe(policy, evidence.found, evidence.ok)
	}
	return out
}

pub fn ui_clone_runtime_evidence_for_probe(policy UiCloneBehaviorProbePolicy,
	signals []UiCloneRuntimeSignal) UiCloneRuntimeProbeEvidence {
	mut rejected := UiCloneRuntimeProbeEvidence{}
	for signal in signals {
		if ui_clone_runtime_signal_satisfies_probe_with_component(policy, signal) {
			evidence := ui_clone_runtime_probe_evidence_from_signal(policy, signal)
			if evidence.ok {
				return evidence
			}
			if !rejected.found {
				rejected = evidence
			}
		}
	}
	for signal in signals {
		if ui_clone_runtime_signal_satisfies_probe(policy, signal) {
			evidence := ui_clone_runtime_probe_evidence_from_signal(policy, signal)
			if evidence.ok {
				return evidence
			}
			if !rejected.found {
				rejected = evidence
			}
		}
	}
	if rejected.found {
		return rejected
	}
	return UiCloneRuntimeProbeEvidence{
		reason: 'runtime_signal_missing_${policy.affordance}'
	}
}

pub fn ui_clone_runtime_signal_semantics(policy UiCloneBehaviorProbePolicy,
	signal UiCloneRuntimeSignal) UiCloneRuntimeSignalSemanticDecision {
	functional_cue := ui_clone_runtime_signal_has_functional_cue(policy, signal)
	visual_only := ui_clone_runtime_signal_visual_only(signal)
	if visual_only {
		return UiCloneRuntimeSignalSemanticDecision{
			class:          'visual_mimic'
			reason:         'literal_text_or_visual_evidence_cannot_certify_behavior_even_when_named_like_a_probe'
			functional_cue: functional_cue
			visual_only:    visual_only
		}
	}
	if !functional_cue {
		if ui_clone_runtime_signal_declares_affordance(policy, signal)
			|| ui_clone_runtime_signal_matches_component(policy, signal) {
			return UiCloneRuntimeSignalSemanticDecision{
				class:          'declared_affordance_without_behavior'
				reason:         'runtime_signal_names_the_affordance_but_has_no_action_or_state_delta'
				functional_cue: functional_cue
				visual_only:    visual_only
			}
		}
		return UiCloneRuntimeSignalSemanticDecision{
			class:          'insufficient_runtime_signal'
			reason:         'runtime_signal_has_no_action_command_state_delta_or_live_event'
			functional_cue: functional_cue
			visual_only:    visual_only
		}
	}
	return UiCloneRuntimeSignalSemanticDecision{
		accepted:       true
		class:          'functional_runtime_signal'
		reason:         'runtime_signal_proves_affordance_through_behavior_or_state_delta'
		functional_cue: functional_cue
		visual_only:    visual_only
	}
}

fn ui_clone_runtime_probe_evidence_from_signal(policy UiCloneBehaviorProbePolicy,
	signal UiCloneRuntimeSignal) UiCloneRuntimeProbeEvidence {
	semantics := ui_clone_runtime_signal_semantics(policy, signal)
	return UiCloneRuntimeProbeEvidence{
		found:             true
		ok:                ui_clone_runtime_signal_ok(signal) && semantics.accepted
		source:            ui_clone_runtime_signal_source(signal)
		matched_signal_id: signal.id
		semantic_class:    semantics.class
		semantic_reason:   semantics.reason
		reason:            if semantics.accepted {
			'runtime_signal_matches_${policy.affordance}'
		} else {
			semantics.reason
		}
	}
}

fn ui_clone_runtime_signal_satisfies_probe_with_component(policy UiCloneBehaviorProbePolicy,
	signal UiCloneRuntimeSignal) bool {
	component_match := ui_clone_runtime_signal_declares_affordance(policy, signal)
		|| ui_clone_runtime_signal_matches_component(policy, signal)
	if component_match && ui_clone_runtime_signal_visual_only(signal) {
		return true
	}
	return component_match && ui_clone_runtime_signal_satisfies_probe(policy, signal)
}

fn ui_clone_runtime_signal_satisfies_probe(policy UiCloneBehaviorProbePolicy,
	signal UiCloneRuntimeSignal) bool {
	if ui_clone_runtime_signal_declares_affordance(policy, signal) {
		return true
	}
	return match policy.affordance {
		'window.frame.controls' { ui_clone_runtime_window_frame_signal(signal) }
		'command.center.invoke' { ui_clone_runtime_command_center_signal(signal) }
		'activity.rail.switch_views' { ui_clone_runtime_activity_rail_signal(signal) }
		'explorer.tree.navigate' { ui_clone_runtime_explorer_tree_signal(signal) }
		'editor.surface.editing' { ui_clone_runtime_editor_surface_signal(signal) }
		'status.indicators.live_state' { ui_clone_runtime_status_signal(signal) }
		'path.command.navigate' { ui_clone_runtime_path_command_signal(signal) }
		'file.list.open_select' { ui_clone_runtime_file_open_select_signal(signal) }
		'file.operations.mutate' { ui_clone_runtime_file_mutation_signal(signal) }
		'app.menu.dispatch' { ui_clone_runtime_app_menu_signal(signal) }
		'ide.bridge.open' { ui_clone_runtime_ide_bridge_signal(signal) }
		'conversation.new' { ui_clone_runtime_conversation_new_signal(signal) }
		'conversation.history.navigate' { ui_clone_runtime_conversation_history_signal(signal) }
		'project.sidebar.select' { ui_clone_runtime_project_select_signal(signal) }
		'prompt.composer.compose' { ui_clone_runtime_prompt_compose_signal(signal) }
		'local.runtime.live_state' { ui_clone_runtime_local_runtime_signal(signal) }
		else { ui_clone_runtime_policy_keyword_signal(policy, signal) }
	}
}

fn ui_clone_runtime_policy_keyword_signal(policy UiCloneBehaviorProbePolicy,
	signal UiCloneRuntimeSignal) bool {
	signal_tokens := ui_clone_runtime_signal_tokens(signal)
	mut hits := 0
	for token in ui_clone_runtime_policy_tokens('${policy.affordance} ${policy.action} ${policy.expected_state_delta}') {
		if token in signal_tokens {
			hits++
			if hits >= 2 {
				return true
			}
		}
	}
	return false
}

fn ui_clone_runtime_signal_tokens(signal UiCloneRuntimeSignal) []string {
	normalized :=
		ui_clone_runtime_signal_blob(signal).replace('.', '_').replace('/', '_').replace(':', '_')
	mut out := []string{}
	for token in normalized.split('_') {
		clean := token.trim_space()
		if ui_clone_runtime_policy_token_is_useful(clean) && clean !in out {
			out << clean
		}
	}
	return out
}

fn ui_clone_runtime_policy_tokens(text string) []string {
	normalized := normalized_clone_value(text).replace('.', '_').replace('/', '_').replace(':', '_')
	mut out := []string{}
	for token in normalized.split('_') {
		if ui_clone_runtime_policy_token_is_useful(token) && token !in out {
			out << token
		}
	}
	return out
}

fn ui_clone_runtime_policy_token_is_useful(token string) bool {
	if token.len < 3 {
		return false
	}
	return token !in [
		'and',
		'behavior',
		'changed',
		'command',
		'controls',
		'delta',
		'events',
		'from',
		'not',
		'probe',
		'route',
		'slots',
		'state',
		'static',
		'the',
		'update',
		'updated',
		'with',
	]
}

fn ui_clone_runtime_signal_declares_affordance(policy UiCloneBehaviorProbePolicy,
	signal UiCloneRuntimeSignal) bool {
	for value in [
		signal.affordance,
		signal.metadata['affordance'] or { '' },
		signal.metadata['behavior_affordance'] or { '' },
		signal.metadata['probe'] or { '' },
		signal.metadata['behavior_probe'] or { '' },
	] {
		clean := normalized_clone_value(value).trim_string_right('.probe')
		if clean == normalized_clone_value(policy.affordance) {
			return true
		}
	}
	return false
}

fn ui_clone_runtime_signal_matches_component(policy UiCloneBehaviorProbePolicy,
	signal UiCloneRuntimeSignal) bool {
	for value in [signal.component, signal.metadata['component'] or { '' }] {
		if normalized_clone_value(value) == normalized_clone_value(policy.component) {
			return true
		}
	}
	return false
}

fn ui_clone_runtime_window_frame_signal(signal UiCloneRuntimeSignal) bool {
	blob := ui_clone_runtime_signal_blob(signal)
	return blob.contains('native_window_controls') || blob.contains('window_bounds')
		|| blob.contains('minimize') || blob.contains('maximize') || blob.contains('resize')
}

fn ui_clone_runtime_command_center_signal(signal UiCloneRuntimeSignal) bool {
	command := ui_clone_runtime_command(signal)
	command_match := command in ['workbench.action.quickopen', 'workbench.action.showcommands',
		'workbench.action.quickcommand', 'workbench.action.quickopenpreviouslyusededitoringroup']
	return command_match || ui_clone_runtime_signal_blob(signal).contains('command_palette')
}

fn ui_clone_runtime_activity_rail_signal(signal UiCloneRuntimeSignal) bool {
	command := ui_clone_runtime_command(signal)
	view := normalized_clone_value(signal.metadata['view_container_id'] or { '' })
	active_view := normalized_clone_value(signal.metadata['active_view_id'] or { '' })
	command_match := command in ['workbench.view.explorer', 'workbench.view.search',
		'workbench.view.scm', 'workbench.view.debug', 'workbench.view.extensions']
	view_match := view in ['workbench_view_explorer', 'workbench_view_search', 'workbench_view_scm',
		'workbench_view_debug', 'workbench_view_extensions']
	return command_match || view_match || active_view != ''
}

fn ui_clone_runtime_explorer_tree_signal(signal UiCloneRuntimeSignal) bool {
	command := ui_clone_runtime_command(signal)
	blob := ui_clone_runtime_signal_blob(signal)
	command_match := command in ['workbench.files.action.refreshfilesexplorer',
		'workbench.action.files.openfile', 'renamefile', 'deletefile']
	blob_match := blob.contains('explorer')
		&& (blob.contains('tree_selection') || blob.contains('file_open')
		|| blob.contains('context_menu') || blob.contains('rename'))
	vexplorer_tree_match := blob.contains('folder_tree')
		&& (blob.contains('context_menu') || blob.contains('rename')
		|| blob.contains('tree_selection'))
	return command_match || blob_match || vexplorer_tree_match
}

fn ui_clone_runtime_editor_surface_signal(signal UiCloneRuntimeSignal) bool {
	command := ui_clone_runtime_command(signal)
	blob := ui_clone_runtime_signal_blob(signal)
	command_match := command in ['undo', 'redo', 'default:type', 'editor.action.selectall',
		'workbench.action.files.openfile']
	blob_match := blob.contains('text_model') || blob.contains('dirty')
		|| blob.contains('selection') || blob.contains('undo_stack')
	return command_match || blob_match
}

fn ui_clone_runtime_status_signal(signal UiCloneRuntimeSignal) bool {
	blob := ui_clone_runtime_signal_blob(signal)
	return blob.contains('status') || blob.contains('diagnostic') || blob.contains('git_branch')
		|| blob.contains('remote_authority') || blob.contains('notification')
}

fn ui_clone_runtime_path_command_signal(signal UiCloneRuntimeSignal) bool {
	command := ui_clone_runtime_command(signal)
	blob := ui_clone_runtime_signal_blob(signal)
	command_match := command in ['vexplorer.path.open', 'vexplorer.workspace.open',
		'vexplorer.openworkspaceroot', 'workbench.action.files.openfolder']
	metadata_match := (signal.metadata['current_path'] or { '' }).trim_space() != '' || (signal.metadata['workspace_root'] or {
		''
	}).trim_space() != ''
	return command_match || metadata_match
		|| (blob.contains('path_changed') && blob.contains('file_list'))
}

fn ui_clone_runtime_file_open_select_signal(signal UiCloneRuntimeSignal) bool {
	command := ui_clone_runtime_command(signal)
	blob := ui_clone_runtime_signal_blob(signal)
	command_match := command in ['vexplorer.file.open', 'vexplorer.file.select',
		'workbench.action.files.openfile', 'openfile']
	metadata_match := (signal.metadata['opened_file'] or { '' }).trim_space() != '' || (signal.metadata['preview_path'] or {
		''
	}).trim_space() != ''
	return command_match || metadata_match
		|| (blob.contains('file_selection') && (blob.contains('preview') || blob.contains('open')))
}

fn ui_clone_runtime_file_mutation_signal(signal UiCloneRuntimeSignal) bool {
	command := ui_clone_runtime_command(signal)
	blob := ui_clone_runtime_signal_blob(signal)
	command_match := command in ['vexplorer.file.rename', 'vexplorer.file.copy',
		'vexplorer.file.move', 'vexplorer.file.delete', 'vexplorer.file.create', 'fs.rename',
		'fs.copy', 'fs.move', 'fs.delete', 'fs.create', 'renamefile', 'deletefile']
	metadata_match := (signal.metadata['file_operation'] or { '' }).trim_space() != '' || (signal.metadata['mutation'] or {
		''
	}).trim_space() != ''
	return command_match || metadata_match || blob.contains('filesystem_model_mutation')
}

fn ui_clone_runtime_app_menu_signal(signal UiCloneRuntimeSignal) bool {
	command := ui_clone_runtime_command(signal)
	blob := ui_clone_runtime_signal_blob(signal)
	return command.starts_with('menu.')
		|| (signal.metadata['menu_command'] or { '' }) != ''
		|| (blob.contains('menu_command') && blob.contains('state_delta'))
}

fn ui_clone_runtime_ide_bridge_signal(signal UiCloneRuntimeSignal) bool {
	command := ui_clone_runtime_command(signal)
	blob := ui_clone_runtime_signal_blob(signal)
	return command in ['antigravity.openide', 'antigravity.open_ide', 'vvscode.open', 'workbench.action.openworkspace'] || (signal.metadata['ide_bridge'] or {
		''
	}) != '' || blob.contains('workspace_bridge')
}

fn ui_clone_runtime_conversation_new_signal(signal UiCloneRuntimeSignal) bool {
	blob := ui_clone_runtime_signal_blob(signal)
	return (signal.metadata['conversation_id'] or { '' }) != ''
		|| (blob.contains('conversation_session') && blob.contains('created'))
}

fn ui_clone_runtime_conversation_history_signal(signal UiCloneRuntimeSignal) bool {
	blob := ui_clone_runtime_signal_blob(signal)
	return (signal.metadata['active_conversation_id'] or { '' }) != ''
		|| blob.contains('active_conversation') || blob.contains('scheduled_task')
}

fn ui_clone_runtime_project_select_signal(signal UiCloneRuntimeSignal) bool {
	blob := ui_clone_runtime_signal_blob(signal)
	return (signal.metadata['project_id'] or { '' }) != '' || (signal.metadata['workspace_project'] or {
		''
	}) != '' || (blob.contains('project') && blob.contains('context'))
}

fn ui_clone_runtime_prompt_compose_signal(signal UiCloneRuntimeSignal) bool {
	blob := ui_clone_runtime_signal_blob(signal)
	return (signal.metadata['prompt_text'] or { '' }) != ''
		|| (signal.metadata['submit_id'] or {
		''
	}) != ''
		|| blob.contains('prompt_submit')
		|| (blob.contains('model') && blob.contains('local') && blob.contains('submit'))
}

fn ui_clone_runtime_local_runtime_signal(signal UiCloneRuntimeSignal) bool {
	blob := ui_clone_runtime_signal_blob(signal)
	return (signal.metadata['runtime_state'] or { '' }) != '' || (signal.metadata['local_mode'] or {
		''
	}) != '' || blob.contains('model_local') || blob.contains('local_runtime')
}

fn ui_clone_runtime_signal_has_functional_cue(_ UiCloneBehaviorProbePolicy,
	signal UiCloneRuntimeSignal) bool {
	if signal.command_id.trim_space() != '' || signal.action_id.trim_space() != ''
		|| signal.state_delta.trim_space() != '' {
		return true
	}
	for key in [
		'active_view_id',
		'command_result',
		'conversation_id',
		'current_path',
		'delta',
		'diagnostics_count',
		'dirty',
		'event_kind',
		'file_list_count',
		'file_operation',
		'git_branch',
		'ide_bridge',
		'language_id',
		'local_mode',
		'menu_command',
		'model',
		'mutation',
		'live_kind',
		'node_host_report_detail_group',
		'node_host_report_detail_id',
		'node_host_report_key',
		'opened_file',
		'preview_path',
		'project_id',
		'prompt_text',
		'remote_authority',
		'route_kind',
		'route_target',
		'selection',
		'submit_id',
		'runtime_state',
		'state_after',
		'state_before',
		'text_model',
		'tool_enabled',
		'view_container_id',
		'window_bounds',
		'window_state',
		'workspace_project',
		'workspace_root',
	] {
		if (signal.metadata[key] or { '' }).trim_space() != '' {
			return true
		}
	}
	return false
}

fn ui_clone_runtime_signal_visual_only(signal UiCloneRuntimeSignal) bool {
	blob := ui_clone_runtime_signal_blob(signal)
	for token in [
		'copy_label',
		'copy_labels',
		'literal_text',
		'mockup',
		'ocr',
		'pixel',
		'reference_text',
		'screenshot',
		'static_image',
		'text_bbox',
		'visual_only',
	] {
		if blob.contains(token) {
			return true
		}
	}
	return false
}

fn ui_clone_runtime_command(signal UiCloneRuntimeSignal) string {
	command := if signal.command_id != '' { signal.command_id } else { signal.action_id }
	return command.trim_space().to_lower()
}

fn ui_clone_runtime_signal_blob(signal UiCloneRuntimeSignal) string {
	mut parts := [
		signal.affordance,
		signal.component,
		signal.command_id,
		signal.action_id,
		signal.state_delta,
		signal.surface,
		signal.region,
		signal.source,
		signal.status,
	]
	for key, value in signal.metadata {
		parts << key
		parts << value
	}
	return normalized_clone_value(parts.join(' '))
}

fn ui_clone_runtime_signal_ok(signal UiCloneRuntimeSignal) bool {
	return signal.ok && normalized_clone_value(signal.status) !in ['failed', 'error', 'blocked']
}

fn ui_clone_runtime_signal_source(signal UiCloneRuntimeSignal) string {
	if signal.source != '' {
		return signal.source
	}
	if signal.id != '' {
		return signal.id
	}
	return 'runtime_behavior_signals'
}
