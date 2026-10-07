module vui_evidence

pub struct UiCloneSemanticSurface {
pub:
	region             string
	component          string
	role               string
	stable_invariants  []string
	dynamic_data       []string
	required_behaviors []string
	anti_blind_rules   []string
}

pub struct UiCloneSemanticUnderstanding {
pub:
	target_profile          string
	source_product          string
	clone_intent            string
	mode                    string
	ready                   bool
	blind_clone_blocker     string
	surface_count           int
	stable_invariant_count  int
	dynamic_data_count      int
	required_behavior_count int
	literal_text_is_data    bool
	clone_strategy          string
}

pub fn ui_clone_semantic_understanding(target_profile string,
	clone_intent string) UiCloneSemanticUnderstanding {
	contract := ui_clone_contract(target_profile, clone_intent)
	surfaces := ui_clone_semantic_surfaces(target_profile, clone_intent)
	return UiCloneSemanticUnderstanding{
		target_profile:          contract.target_profile
		source_product:          contract.source_product
		clone_intent:            contract.clone_intent
		mode:                    contract.mode
		ready:                   contract.reasoning_ready
		blind_clone_blocker:     contract.blind_clone_blocker
		surface_count:           surfaces.len
		stable_invariant_count:  ui_clone_count_stable_invariants(surfaces)
		dynamic_data_count:      ui_clone_count_dynamic_data(surfaces)
		required_behavior_count: ui_clone_count_required_behaviors(surfaces)
		literal_text_is_data:    contract.mode == 'semantic_functional_clone'
		clone_strategy:          ui_clone_semantic_clone_strategy(contract)
	}
}

pub fn ui_clone_semantic_surfaces(target_profile string,
	clone_intent string) []UiCloneSemanticSurface {
	contract := ui_clone_contract(target_profile, clone_intent)
	if contract.mode != 'semantic_functional_clone' || !contract.reasoning_ready {
		return []UiCloneSemanticSurface{}
	}
	return match contract.target_profile {
		'vscode' { vscode_semantic_surfaces() }
		'vexplorer' { vexplorer_semantic_surfaces() }
		'antigravity' { antigravity_semantic_surfaces() }
		else { []UiCloneSemanticSurface{} }
	}
}

fn vscode_semantic_surfaces() []UiCloneSemanticSurface {
	return [
		semantic_surface('top_chrome', 'window.frame', 'native_window_management', [
			'native hit-test zones',
			'title/menu/command/control slots',
			'focus and bounds ownership',
		], [
			'window title',
			'active workspace name',
		], [
			'move_resize_minimize_restore_close_probe',
			'tray/transparency compatibility probe',
		]),
		semantic_surface('top_chrome', 'command.center', 'global_command_entry', [
			'command entry locus',
			'quick open affordance',
			'keyboard focus route',
		], [
			'typed query',
			'recent commands',
			'workspace path labels',
		], [
			'quick open filters results',
			'selected command dispatches state delta',
		]),
		semantic_surface('side_rail', 'activity.rail', 'primary_view_switcher', [
			'explorer/search/scm/run/extensions targets',
			'active target indicator',
			'account and manage targets',
		], [
			'badge counts',
			'active view id',
		], [
			'view selection changes active container and sidebar content',
		]),
		semantic_surface('sidebar_panel', 'explorer.tree', 'workspace_navigation_tree', [
			'tree indentation',
			'disclosure targets',
			'selection and context zones',
		], [
			'folder names',
			'file names',
			'workspace root',
			'decorations',
		], [
			'open reveal rename delete drag keyboard tree flow',
		]),
		semantic_surface('content_page', 'editor.surface', 'editable_document_surface', [
			'tab strip slots',
			'editor canvas bounds',
			'cursor/selection affordance zones',
		], [
			'document text',
			'webview content',
			'notebook output',
			'diagnostic decorations',
		], [
			'edit select undo dirty marker diagnostics webview notebook state deltas',
		]),
		semantic_surface('status_bar', 'status.indicators', 'workspace_state_feedback', [
			'status slot order',
			'notification/remote/language loci',
			'click target bounds',
		], [
			'git branch',
			'diagnostic count',
			'language id',
			'remote authority',
		], [
			'workspace events update status slots',
		]),
	]
}

fn vexplorer_semantic_surfaces() []UiCloneSemanticSurface {
	return [
		semantic_surface('top_chrome', 'window.frame', 'native_window_management', [
			'native hit-test zones',
			'titlebar/control slots',
			'desktop shell bounds',
		], [
			'window title',
			'active focus state',
		], [
			'move resize minimize maximize close transparency probe',
		]),
		semantic_surface('top_chrome', 'path.command', 'path_and_command_entry', [
			'path entry slot',
			'command dropdown slot',
			'navigation focus route',
		], [
			'current path',
			'workspace root',
			'recent path history',
		], [
			'path change updates workspace root and file list',
		]),
		semantic_surface('side_rail', 'activity.rail', 'workspace_mode_switcher', [
			'mode icons',
			'active mode marker',
			'keyboard target order',
		], [
			'active mode',
			'badge counts',
		], [
			'switch explorer search recents settings state',
		]),
		semantic_surface('sidebar_panel', 'explorer.tree', 'workspace_folder_tree', [
			'folder indentation',
			'disclosure targets',
			'context-menu target zones',
		], [
			'folder names',
			'expanded rows',
			'selection label',
		], [
			'expand collapse reveal context rename drag keyboard flow',
		]),
		semantic_surface('content_page', 'file.list', 'file_list_preview_surface', [
			'row geometry',
			'preview slot',
			'sort and selection zones',
		], [
			'file names',
			'preview text',
			'timestamps',
			'sizes',
		], [
			'select open preview sort rename copy move delete create mutations',
		]),
		semantic_surface('status_bar', 'status.indicators', 'file_operation_feedback', [
			'status slot positions',
			'operation progress locus',
			'path state locus',
		], [
			'selection count',
			'path state',
			'operation progress text',
		], [
			'selection path operation events update status slots',
		]),
	]
}

fn antigravity_semantic_surfaces() []UiCloneSemanticSurface {
	return [
		semantic_surface('top_chrome', 'window.frame', 'native_window_management', [
			'native hit-test zones',
			'menu/control slot alignment',
			'desktop shell bounds',
		], [
			'window title',
			'focus state',
		], [
			'move resize minimize maximize close transparency probe',
		]),
		semantic_surface('top_chrome', 'app.menu', 'desktop_menu_bar', [
			'File/View/Window command anchors',
			'menu target bounds',
			'keyboard menu route',
		], [
			'localized labels only when configured',
		], [
			'menu command dispatches state delta',
		]),
		semantic_surface('top_chrome', 'ide.bridge', 'open_ide_bridge', [
			'Open IDE target bounds',
			'bridge icon slot',
			'command routing target',
		], [
			'current workspace bridge target',
		], [
			'open ide emits command or workspace bridge state',
		]),
		semantic_surface('sidebar_panel', 'conversation.nav',
			'conversation_and_project_navigation', [
			'new/history/scheduled/project zones',
			'selection markers',
			'row hierarchy',
		], [
			'conversation titles',
			'project names',
			'timestamps',
			'task labels',
		], [
			'new session history selection scheduled task project scope changes',
		]),
		semantic_surface('content_page', 'prompt.composer', 'agent_prompt_input_surface', [
			'composer bounds',
			'model/tool/local/mic slots',
			'submit readiness state',
		], [
			'prompt text',
			'model label',
			'tool label',
			'generated responses',
		], [
			'typing toggles model tool local mic submit and history update state',
		]),
		semantic_surface('status_bar', 'local.runtime', 'local_model_runtime_status', [
			'runtime indicator locus',
			'local-mode target',
			'model status slot',
		], [
			'model/runtime label',
			'local availability',
			'latency/status text',
		], [
			'local runtime events update model and mode indicators',
		]),
	]
}

fn semantic_surface(region string, component string, role string, stable []string,
	dynamic []string, behaviors []string) UiCloneSemanticSurface {
	return UiCloneSemanticSurface{
		region:             region
		component:          component
		role:               role
		stable_invariants:  stable
		dynamic_data:       dynamic
		required_behaviors: behaviors
		anti_blind_rules:   ui_clone_default_anti_blind_rules(dynamic)
	}
}

fn ui_clone_default_anti_blind_rules(dynamic []string) []string {
	mut rules := [
		'do not score copied OCR or screenshot text as behavior',
		'require runtime state deltas for behavior claims',
		'compare stable geometry and affordance roles before literal labels',
	]
	if dynamic.len > 0 {
		rules << 'treat ${dynamic.join(', ')} as runtime data, not clone literals'
	}
	return rules
}

fn ui_clone_semantic_clone_strategy(contract UiCloneContract) string {
	if contract.mode != 'semantic_functional_clone' {
		return 'visual reference only'
	}
	return 'understand target roles, mask runtime data, then require atomic behavior evidence'
}

fn ui_clone_count_stable_invariants(surfaces []UiCloneSemanticSurface) int {
	mut count := 0
	for surface in surfaces {
		count += surface.stable_invariants.len
	}
	return count
}

fn ui_clone_count_dynamic_data(surfaces []UiCloneSemanticSurface) int {
	mut count := 0
	for surface in surfaces {
		count += surface.dynamic_data.len
	}
	return count
}

fn ui_clone_count_required_behaviors(surfaces []UiCloneSemanticSurface) int {
	mut count := 0
	for surface in surfaces {
		count += surface.required_behaviors.len
	}
	return count
}
