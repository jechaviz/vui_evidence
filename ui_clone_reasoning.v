module vui_evidence

pub struct UiCloneReasoningStep {
pub:
	id              string
	role            string
	required        bool = true
	evidence        string
	failure_mode    string
	background_safe bool = true
}

pub struct UiCloneReasoningPlan {
pub:
	target_profile              string
	source_product              string
	clone_intent                string
	mode                        string
	known_profile               bool
	reasoning_ready             bool
	reasoning_model             string
	semantic_scope              string
	visual_strategy             string
	text_strategy               string
	behavior_strategy           string
	functional_gate             string
	blind_clone_blocker         string
	component_count             int
	affordance_count            int
	behavior_probe_count        int
	background_safe_probe_count int
	step_count                  int
}

pub fn ui_clone_reasoning_plan(target_profile string, clone_intent string) UiCloneReasoningPlan {
	contract := ui_clone_contract(target_profile, clone_intent)
	probes := ui_clone_behavior_probe_policies(contract.target_profile, contract.clone_intent)
	steps := ui_clone_reasoning_steps(contract.target_profile, contract.clone_intent)
	return UiCloneReasoningPlan{
		target_profile:              contract.target_profile
		source_product:              contract.source_product
		clone_intent:                contract.clone_intent
		mode:                        contract.mode
		known_profile:               contract.known_profile
		reasoning_ready:             contract.reasoning_ready
		reasoning_model:             contract.reasoning_model
		semantic_scope:              contract.semantic_scope
		visual_strategy:             ui_clone_visual_strategy(contract)
		text_strategy:               contract.text_comparison_policy
		behavior_strategy:           contract.runtime_evidence_policy
		functional_gate:             contract.behavior_gate
		blind_clone_blocker:         contract.blind_clone_blocker
		component_count:             contract.component_count
		affordance_count:            contract.affordance_count
		behavior_probe_count:        contract.behavior_probe_count
		background_safe_probe_count: probes.filter(it.background_safe).len
		step_count:                  steps.len
	}
}

pub fn ui_clone_reasoning_steps(target_profile string, clone_intent string) []UiCloneReasoningStep {
	contract := ui_clone_contract(target_profile, clone_intent)
	if contract.mode != 'semantic_functional_clone' {
		return [
			reasoning_step('segment_reference_pixels', 'visual_reference_regions',
				'reference and actual screenshots with matching dimensions',
				'full_screenshot_score_hides_region_drift'),
			reasoning_step('report_visual_drift', 'pixel_region_diff',
				'per-region diff score and hotspots', 'visual_only_contract_has_no_behavior_gate'),
		]
	}
	mut steps := [
		reasoning_step('identify_target_profile', 'known_product_contract',
			'canonical target such as vscode, vexplorer, or antigravity',
			'blind_clone_without_semantic_contract'),
		reasoning_step('separate_runtime_data', 'dynamic_content_mask',
			'text policies that mark paths, files, prompts, and generated text as data',
			'literal_text_copy_masks_missing_functionality'),
		reasoning_step('segment_functional_regions', 'desktop_workbench_regions',
			'top chrome, side rail, sidebar, content surface, and status regions',
			'whole_image_score_hides_missing_affordances'),
		reasoning_step('score_visual_anchors', 'component_geometry_and_icons',
			'stable visual anchors for native frame and navigation affordances',
			'low_pixel_match_without_action_targets'),
		reasoning_step('require_behavior_probes', 'atomic_runtime_semantics',
			'commands, actions, state deltas, or live runtime events per affordance',
			'screenshot_or_ocr_mimic_claims_functionality'),
		reasoning_step('keep_background_safe', 'nonintrusive_desktop_qa',
			'background-safe probes and no focus stealing during parity work',
			'foreground_capture_interrupts_primary_work'),
	]
	if contract.blind_clone_blocker != '' {
		steps << reasoning_step('block_unknown_functional_target', 'blind_clone_gate',
			'explicit known target profile before functional parity scoring',
			contract.blind_clone_blocker)
	}
	return steps
}

fn ui_clone_visual_strategy(contract UiCloneContract) string {
	if contract.mode == 'semantic_functional_clone' {
		return 'score segmented structural anchors while masking dynamic runtime content'
	}
	return 'score segmented pixels against a real visual reference'
}

fn reasoning_step(id string, role string, evidence string, failure_mode string) UiCloneReasoningStep {
	return UiCloneReasoningStep{
		id:           id
		role:         role
		evidence:     evidence
		failure_mode: failure_mode
	}
}
