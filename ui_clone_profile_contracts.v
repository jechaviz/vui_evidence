module vui_evidence

fn vexplorer_functional_components() []UiCloneComponentPolicy {
	return [
		UiCloneComponentPolicy{
			name:             'window.frame'
			region:           'top_chrome'
			role:             'native_window_management'
			compare_geometry: true
			parity_axis:      'move_resize_minimize_maximize_close'
			evidence:         'native desktop frame behavior must be proven, not painted'
		},
		UiCloneComponentPolicy{
			name:             'path.command'
			region:           'top_chrome'
			role:             'path_and_command_entry'
			compare_geometry: true
			dynamic_content:  true
			parity_axis:      'path_navigation_and_commands'
			evidence:         'current path text is runtime data; path navigation behavior is required'
		},
		UiCloneComponentPolicy{
			name:             'activity.rail'
			region:           'side_rail'
			role:             'workspace_mode_switcher'
			compare_geometry: true
			parity_axis:      'explorer_search_recent_settings'
			evidence:         'view switch targets need selection and keyboard behavior'
		},
		UiCloneComponentPolicy{
			name:             'explorer.tree'
			region:           'sidebar_panel'
			role:             'workspace_folder_tree'
			compare_geometry: true
			dynamic_content:  true
			parity_axis:      'folder_navigation_and_context_actions'
			evidence:         'folder names and depth are data; navigation semantics matter'
		},
		UiCloneComponentPolicy{
			name:             'file.list'
			region:           'content_page'
			role:             'file_list_preview_surface'
			compare_geometry: true
			dynamic_content:  true
			parity_axis:      'open_select_preview_sort_rename_copy_delete'
			evidence:         'file rows must map to workspace operations, not fixed labels'
		},
		UiCloneComponentPolicy{
			name:             'status.indicators'
			region:           'status_bar'
			role:             'file_operation_feedback'
			compare_geometry: true
			dynamic_content:  true
			parity_axis:      'selection_count_path_state_operation_status'
			evidence:         'status slots update from file and workspace events'
		},
	]
}

fn vexplorer_functional_affordances() []UiCloneAffordancePolicy {
	return [
		visual_affordance('window.frame.geometry', 'window.frame', 'top_chrome',
			'native_frame_layout', false, 'titlebar and control slots align with the desktop shell'),
		behavior_affordance('window.frame.controls', 'window.frame', 'top_chrome',
			'native_window_control_behavior',
			'move, resize, minimize, maximize, close, and tray transparency must be probed'),
		visual_affordance('path.command.slot', 'path.command', 'top_chrome',
			'path_command_entry_slot', true,
			'path text may vary while command/path locus remains discoverable'),
		behavior_affordance('path.command.navigate', 'path.command', 'top_chrome',
			'path_navigation_behavior',
			'typing or selecting a path must change workspace root and content state'),
		visual_affordance('activity.rail.targets', 'activity.rail', 'side_rail',
			'workspace_mode_targets', false,
			'explorer, search, recents, and settings targets remain stable icon affordances'),
		behavior_affordance('activity.rail.switch_views', 'activity.rail', 'side_rail',
			'workspace_view_switching',
			'view targets must update active view and sidebar/content state'),
		visual_affordance('explorer.tree.hierarchy', 'explorer.tree', 'sidebar_panel',
			'folder_tree_layout', true,
			'folder rows are data while indentation, disclosure, and selection zones stay stable'),
		behavior_affordance('explorer.tree.navigate', 'explorer.tree', 'sidebar_panel',
			'folder_tree_navigation_behavior',
			'expand, collapse, reveal, context menu, rename, drag, and keyboard flow need probes'),
		visual_affordance('file.list.rows', 'file.list', 'content_page',
			'file_row_and_preview_layout', true,
			'file names are data while row geometry and preview slots remain stable'),
		behavior_affordance('file.list.open_select', 'file.list', 'content_page',
			'file_open_selection_preview_behavior',
			'selecting and opening files must change preview/editor state'),
		behavior_affordance('file.operations.mutate', 'file.list', 'content_page',
			'file_operation_mutation_behavior',
			'rename, copy, move, delete, and create actions must update the filesystem model'),
		behavior_affordance('status.indicators.live_state', 'status.indicators', 'status_bar',
			'file_operation_status_behavior',
			'selection count, path state, and operation progress update from runtime events'),
	]
}

fn vexplorer_behavior_probe_policies() []UiCloneBehaviorProbePolicy {
	return [
		behavior_probe('window.frame.controls', 'window.frame', 'top_chrome',
			'move_resize_minimize_restore_close_probe',
			'window_bounds_and_state_change_with_native_controls'),
		behavior_probe('path.command.navigate', 'path.command', 'top_chrome',
			'navigate_to_path_or_workspace_root',
			'path_changed_workspace_root_and_file_list_updated'),
		behavior_probe('activity.rail.switch_views', 'activity.rail', 'side_rail',
			'switch_explorer_search_recents_settings',
			'active_view_id_changes_and_workspace_panel_updates'),
		behavior_probe('explorer.tree.navigate', 'explorer.tree', 'sidebar_panel',
			'expand_collapse_reveal_context_menu_rename_drag_keyboard',
			'folder_tree_selection_file_list_filter_and_context_actions_update_state'),
		behavior_probe('file.list.open_select', 'file.list', 'content_page',
			'select_open_preview_sort_file_row', 'file_selection_open_preview_state_delta'),
		behavior_probe('file.operations.mutate', 'file.list', 'content_page',
			'rename_copy_move_delete_create_file',
			'filesystem_model_mutation_and_view_refresh_delta'),
		behavior_probe('status.indicators.live_state', 'status.indicators', 'status_bar',
			'emit_selection_path_operation_events',
			'status_slots_update_from_workspace_file_events_not_static_labels'),
	]
}

fn antigravity_functional_components() []UiCloneComponentPolicy {
	return [
		UiCloneComponentPolicy{
			name:             'window.frame'
			region:           'top_chrome'
			role:             'native_window_management'
			compare_geometry: true
			parity_axis:      'move_resize_minimize_maximize_close'
			evidence:         'native desktop frame behavior must be proven, not painted'
		},
		UiCloneComponentPolicy{
			name:             'app.menu'
			region:           'top_chrome'
			role:             'desktop_menu_bar'
			compare_geometry: true
			parity_axis:      'file_view_window_menu_commands'
			evidence:         'menu labels are structural anchors; commands must dispatch'
		},
		UiCloneComponentPolicy{
			name:             'ide.bridge'
			region:           'top_chrome'
			role:             'open_ide_bridge'
			compare_geometry: true
			parity_axis:      'external_ide_open_command'
			evidence:         'Open IDE must route to a command/state delta, not a painted button'
		},
		UiCloneComponentPolicy{
			name:             'conversation.nav'
			region:           'sidebar_panel'
			role:             'conversation_and_project_navigation'
			compare_geometry: true
			dynamic_content:  true
			parity_axis:      'new_history_scheduled_project_selection'
			evidence:         'conversation and project names are runtime data'
		},
		UiCloneComponentPolicy{
			name:             'prompt.composer'
			region:           'content_page'
			role:             'agent_prompt_input_surface'
			compare_geometry: true
			dynamic_content:  true
			parity_axis:      'prompt_edit_model_tool_local_toggle_submit'
			evidence:         'prompt text and model label are data; composer behavior is required'
		},
		UiCloneComponentPolicy{
			name:             'local.runtime'
			region:           'status_bar'
			role:             'local_model_runtime_status'
			compare_geometry: true
			dynamic_content:  true
			parity_axis:      'local_mode_mic_tool_runtime_state'
			evidence:         'local/model/runtime state must update from events'
		},
	]
}

fn antigravity_functional_affordances() []UiCloneAffordancePolicy {
	return [
		visual_affordance('window.frame.geometry', 'window.frame', 'top_chrome',
			'native_frame_layout', false, 'menu and control slots align with the desktop shell'),
		behavior_affordance('window.frame.controls', 'window.frame', 'top_chrome',
			'native_window_control_behavior',
			'move, resize, minimize, maximize, close, and tray transparency must be probed'),
		visual_affordance('app.menu.items', 'app.menu', 'top_chrome', 'desktop_menu_items', false,
			'File, View, and Window anchors are structural command entry points'),
		behavior_affordance('app.menu.dispatch', 'app.menu', 'top_chrome',
			'desktop_menu_command_dispatch',
			'menu selections must dispatch commands or state deltas'),
		visual_affordance('ide.bridge.button', 'ide.bridge', 'top_chrome', 'open_ide_bridge_slot',
			false, 'Open IDE affordance must exist as a bridge target'),
		behavior_affordance('ide.bridge.open', 'ide.bridge', 'top_chrome',
			'open_ide_bridge_behavior', 'Open IDE must emit command or route evidence'),
		visual_affordance('conversation.nav.structure', 'conversation.nav', 'sidebar_panel',
			'conversation_project_navigation_layout', true,
			'conversation titles, projects, and timestamps are data'),
		behavior_affordance('conversation.new', 'conversation.nav', 'sidebar_panel',
			'new_conversation_behavior', 'New Conversation must create a new agent session state'),
		behavior_affordance('conversation.history.navigate', 'conversation.nav', 'sidebar_panel',
			'conversation_history_navigation_behavior',
			'history and scheduled task rows must change active conversation/task state'),
		behavior_affordance('project.sidebar.select', 'conversation.nav', 'sidebar_panel',
			'project_selection_behavior',
			'project rows must change workspace context and prompt scope'),
		visual_affordance('prompt.composer.surface', 'prompt.composer', 'content_page',
			'agent_prompt_composer_layout', true,
			'placeholder, model, tool, mic, and local slots remain stable while text varies'),
		behavior_affordance('prompt.composer.compose', 'prompt.composer', 'content_page',
			'agent_prompt_composition_behavior',
			'typing, model/tool/local toggles, mic, submit, and history need probes'),
		behavior_affordance('local.runtime.live_state', 'local.runtime', 'status_bar',
			'local_runtime_state_behavior',
			'local/model/runtime indicators must update from runtime events'),
	]
}

fn antigravity_behavior_probe_policies() []UiCloneBehaviorProbePolicy {
	return [
		behavior_probe('window.frame.controls', 'window.frame', 'top_chrome',
			'move_resize_minimize_restore_close_probe',
			'window_bounds_and_state_change_with_native_controls'),
		behavior_probe('app.menu.dispatch', 'app.menu', 'top_chrome',
			'dispatch_file_view_window_menu_command', 'menu_command_route_and_state_delta'),
		behavior_probe('ide.bridge.open', 'ide.bridge', 'top_chrome', 'open_ide_bridge',
			'open_ide_command_route_or_workspace_bridge_state_delta'),
		behavior_probe('conversation.new', 'conversation.nav', 'sidebar_panel',
			'create_new_conversation_session',
			'conversation_session_created_and_active_conversation_changed'),
		behavior_probe('conversation.history.navigate', 'conversation.nav', 'sidebar_panel',
			'open_history_or_scheduled_task_row', 'active_conversation_or_task_state_changed'),
		behavior_probe('project.sidebar.select', 'conversation.nav', 'sidebar_panel',
			'select_project_workspace_scope',
			'workspace_project_context_changed_and_prompt_scope_updated'),
		behavior_probe('prompt.composer.compose', 'prompt.composer', 'content_page',
			'type_toggle_model_tool_local_mic_submit_prompt',
			'prompt_text_model_tool_local_submit_state_delta'),
		behavior_probe('local.runtime.live_state', 'local.runtime', 'status_bar',
			'emit_model_local_runtime_events',
			'model_local_runtime_slots_update_from_events_not_static_labels'),
	]
}
