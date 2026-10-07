module vui_evidence

pub struct UiCloneSemanticProfile {
pub:
	id                      string
	family                  string
	source_product          string
	functional_paradigm     string
	reasoning_model         string
	semantic_scope          string
	text_policy             string
	runtime_evidence_policy string
	literal_clone_policy    string
	behavior_gate           string
	dynamic_content_policy  string
	native_surface_policy   string
}

pub fn ui_clone_semantic_profile(target_profile string, clone_intent string) UiCloneSemanticProfile {
	profile := canonical_clone_profile(target_profile)
	intent := normalized_clone_value(clone_intent)
	mode := if intent in ['functional_ui_clone', 'functional_clone', 'ui_clone'] {
		'semantic_functional_clone'
	} else {
		'pixel_reference_clone'
	}
	return ui_clone_semantic_profile_for(profile, mode)
}

fn canonical_clone_profile(value string) string {
	clean := normalized_clone_value(value)
	return match clean {
		'vs_code', 'visual_studio_code', 'vvscode', 'vvscode_lowram', 'vscode_lowram' {
			'vscode'
		}
		'veloexplorer', 'velo_explorer', 'v_explorer' {
			'vexplorer'
		}
		'anti_gravity', 'google_antigravity', 'google_anti_gravity' {
			'antigravity'
		}
		else {
			clean
		}
	}
}

fn ui_clone_semantic_profile_for(profile string, mode string) UiCloneSemanticProfile {
	if mode != 'semantic_functional_clone' {
		return pixel_reference_profile(profile)
	}
	return match canonical_clone_profile(profile) {
		'vscode' {
			functional_profile('vscode', 'desktop_ide_workbench', 'visual_studio_code',
				'extension_compatible_ide_workbench', 'desktop_ide_workbench_affordances',
				'workspace, editor, task, terminal, and extension output are runtime data')
		}
		'vexplorer' {
			functional_profile('vexplorer', 'desktop_explorer_workbench', 'vexplorer',
				'low_ram_workspace_explorer', 'desktop_explorer_tree_and_file_affordances',
				'paths, filenames, previews, and selections are runtime data')
		}
		'antigravity' {
			functional_profile('antigravity', 'agent_chat_ide_shell', 'antigravity',
				'agent_prompt_shell_with_ide_bridge', 'desktop_agent_workspace_prompt_affordances',
				'conversation titles, project names, model labels, and generated text are runtime data')
		}
		else {
			pixel_reference_profile(profile)
		}
	}
}

fn functional_profile(id string, family string, source_product string, paradigm string, scope string,
	dynamic_policy string) UiCloneSemanticProfile {
	return UiCloneSemanticProfile{
		id:                      id
		family:                  family
		source_product:          source_product
		functional_paradigm:     paradigm
		reasoning_model:         'functional_affordance_contract_over_literal_text'
		semantic_scope:          scope
		text_policy:             'compare_structural_labels_only; treat user content and generated text as data'
		runtime_evidence_policy: 'runtime signals must prove action, command, state delta, or live event semantics'
		literal_clone_policy:    'literal screenshot, OCR, copied labels, and static mockups cannot certify functional parity'
		behavior_gate:           'functional_parity_requires_behavior_probe_evidence'
		dynamic_content_policy:  dynamic_policy
		native_surface_policy:   'desktop-native frame, resize, minimize, restore, close, focus, and tray/transparency behavior need probes'
	}
}

fn pixel_reference_profile(profile string) UiCloneSemanticProfile {
	id := canonical_clone_profile(profile)
	return UiCloneSemanticProfile{
		id:                      id
		family:                  'reference_image_regions'
		source_product:          id
		functional_paradigm:     'visual_reference'
		reasoning_model:         'pixel_regions_over_full_image'
		semantic_scope:          'reference_image_regions'
		text_policy:             'compare_visible_reference_text'
		runtime_evidence_policy: 'runtime signals optional'
		literal_clone_policy:    'literal visual reference is accepted'
		behavior_gate:           'visual_capture_only'
		dynamic_content_policy:  'visible text is compared as reference content'
		native_surface_policy:   'native behavior is outside this visual-only contract'
	}
}

fn ui_clone_dynamic_text_policy_for(profile string, clean_name string,
	original_name string) ?UiCloneTextPolicy {
	canonical := canonical_clone_profile(profile)
	if canonical == 'vscode' {
		if clean_name.contains('codex.task') || clean_name.contains('task1_text') {
			return dynamic_text_policy(original_name, 'dynamic_agent_content')
		}
		if clean_name.contains('editor.line') || clean_name.contains('line1_text') {
			return dynamic_text_policy(original_name, 'dynamic_editor_content')
		}
	}
	if canonical == 'vexplorer' && (clean_name.contains('file') || clean_name.contains('path')
		|| clean_name.contains('preview') || clean_name.contains('selection')) {
		return dynamic_text_policy(original_name, 'dynamic_workspace_file_content')
	}
	if canonical == 'antigravity'
		&& (clean_name.contains('conversation') || clean_name.contains('prompt')
		|| clean_name.contains('project') || clean_name.contains('model')
		|| clean_name.contains('agent')) {
		return dynamic_text_policy(original_name, 'dynamic_agent_workspace_content')
	}
	return none
}

fn dynamic_text_policy(name string, role string) UiCloneTextPolicy {
	return UiCloneTextPolicy{
		name:                      name
		role:                      role
		required:                  false
		compare_bounds:            false
		block_on_bounds:           false
		optional_when_absent_both: true
	}
}

fn ui_clone_region_policy_for_profile(profile string, clean_name string,
	original_name string) ?UiCloneRegionPolicy {
	canonical := canonical_clone_profile(profile)
	if canonical == 'vscode' {
		return vscode_region_policy(clean_name, original_name)
	}
	if canonical == 'vexplorer' {
		return vexplorer_region_policy(clean_name, original_name)
	}
	if canonical == 'antigravity' {
		return antigravity_region_policy(clean_name, original_name)
	}
	return none
}

fn vscode_region_policy(clean_name string, original_name string) UiCloneRegionPolicy {
	return match clean_name {
		'top_chrome' {
			UiCloneRegionPolicy{original_name, 'window_chrome_and_command_surface', 'strict_geometry_color', false, true}
		}
		'side_rail' {
			UiCloneRegionPolicy{original_name, 'primary_navigation_rail', 'strict_icon_geometry', false, true}
		}
		'sidebar_panel' {
			UiCloneRegionPolicy{original_name, 'workspace_navigation_tree', 'functional_layout', true, true}
		}
		'content_page' {
			UiCloneRegionPolicy{original_name, 'editor_or_welcome_surface', 'functional_layout', true, true}
		}
		'status_bar' {
			UiCloneRegionPolicy{original_name, 'status_and_notifications', 'strict_geometry_color', true, true}
		}
		else {
			UiCloneRegionPolicy{original_name, 'unknown_region', 'pixel_reference', false, true}
		}
	}
}

fn vexplorer_region_policy(clean_name string, original_name string) UiCloneRegionPolicy {
	return match clean_name {
		'top_chrome' {
			UiCloneRegionPolicy{original_name, 'window_chrome_path_and_command_surface', 'strict_geometry_color', false, true}
		}
		'side_rail' {
			UiCloneRegionPolicy{original_name, 'workspace_mode_switcher', 'strict_icon_geometry', false, true}
		}
		'sidebar_panel' {
			UiCloneRegionPolicy{original_name, 'workspace_folder_tree', 'functional_layout', true, true}
		}
		'content_page' {
			UiCloneRegionPolicy{original_name, 'file_list_preview_surface', 'functional_layout', true, true}
		}
		'status_bar' {
			UiCloneRegionPolicy{original_name, 'file_operation_status', 'strict_geometry_color', true, true}
		}
		else {
			UiCloneRegionPolicy{original_name, 'unknown_region', 'pixel_reference', false, true}
		}
	}
}

fn antigravity_region_policy(clean_name string, original_name string) UiCloneRegionPolicy {
	return match clean_name {
		'top_chrome' {
			UiCloneRegionPolicy{original_name, 'window_chrome_menu_and_ide_bridge', 'strict_geometry_color', false, true}
		}
		'sidebar_panel' {
			UiCloneRegionPolicy{original_name, 'conversation_project_navigation', 'functional_layout', true, true}
		}
		'content_page' {
			UiCloneRegionPolicy{original_name, 'agent_prompt_workspace_surface', 'functional_layout', true, true}
		}
		'status_bar' {
			UiCloneRegionPolicy{original_name, 'local_model_and_runtime_status', 'functional_layout', true, true}
		}
		else {
			UiCloneRegionPolicy{original_name, 'supporting_shell_region', 'functional_layout', true, true}
		}
	}
}

fn ui_clone_profile_component_policies(profile string) []UiCloneComponentPolicy {
	return match canonical_clone_profile(profile) {
		'vscode' { vscode_functional_components() }
		'vexplorer' { vexplorer_functional_components() }
		'antigravity' { antigravity_functional_components() }
		else { []UiCloneComponentPolicy{} }
	}
}

fn ui_clone_profile_affordance_policies(profile string) []UiCloneAffordancePolicy {
	return match canonical_clone_profile(profile) {
		'vscode' { vscode_functional_affordances() }
		'vexplorer' { vexplorer_functional_affordances() }
		'antigravity' { antigravity_functional_affordances() }
		else { []UiCloneAffordancePolicy{} }
	}
}
