module vui_evidence

pub struct UiCloneExplicitBehaviorEvidence {
pub:
	id             string
	affordance     string
	component      string
	source         string
	semantic_class string
	command_id     string
	action_id      string
	state_delta    string
	status         string
	metadata       map[string]string
	ok             bool = true
}

pub fn ui_clone_explicit_behavior_evidence_for_probe(policy UiCloneBehaviorProbePolicy,
	claim UiCloneExplicitBehaviorEvidence) UiCloneRuntimeProbeEvidence {
	signal := ui_clone_explicit_behavior_signal(policy, claim)
	semantics := ui_clone_explicit_behavior_semantics(policy, signal,
		ui_clone_explicit_behavior_class(claim.semantic_class))
	source := ui_clone_explicit_behavior_source(claim)
	return UiCloneRuntimeProbeEvidence{
		found:             true
		ok:                claim.ok && ui_clone_runtime_signal_ok(signal) && semantics.accepted
		source:            source
		matched_signal_id: if claim.id != '' { claim.id } else { source }
		semantic_class:    semantics.class
		semantic_reason:   semantics.reason
		reason:            if semantics.accepted {
			'explicit_behavior_evidence_matches_${policy.affordance}'
		} else {
			semantics.reason
		}
	}
}

fn ui_clone_explicit_behavior_signal(policy UiCloneBehaviorProbePolicy,
	claim UiCloneExplicitBehaviorEvidence) UiCloneRuntimeSignal {
	return UiCloneRuntimeSignal{
		id:          claim.id
		affordance:  if claim.affordance != '' { claim.affordance } else { policy.affordance }
		component:   if claim.component != '' { claim.component } else { policy.component }
		command_id:  claim.command_id
		action_id:   claim.action_id
		state_delta: claim.state_delta
		region:      policy.region
		source:      claim.source
		status:      claim.status
		metadata:    claim.metadata
		ok:          claim.ok
	}
}

fn ui_clone_explicit_behavior_semantics(policy UiCloneBehaviorProbePolicy,
	signal UiCloneRuntimeSignal, semantic_class string) UiCloneRuntimeSignalSemanticDecision {
	if ui_clone_runtime_signal_visual_only(signal) {
		return UiCloneRuntimeSignalSemanticDecision{
			class:          'visual_mimic'
			reason:         'literal_text_or_visual_evidence_cannot_certify_behavior_even_when_named_like_a_probe'
			functional_cue: false
			visual_only:    true
		}
	}
	functional_cue := ui_clone_explicit_behavior_has_proof(policy, signal)
	if !functional_cue {
		return UiCloneRuntimeSignalSemanticDecision{
			class:          'declared_affordance_without_behavior'
			reason:         'explicit_evidence_names_the_affordance_but_has_no_command_action_state_delta_or_event'
			functional_cue: false
		}
	}
	if !ui_clone_runtime_signal_satisfies_probe_with_component(policy, signal) {
		return UiCloneRuntimeSignalSemanticDecision{
			class:          'insufficient_runtime_signal'
			reason:         'explicit_evidence_has_behavior_but_does_not_match_expected_affordance'
			functional_cue: true
		}
	}
	return UiCloneRuntimeSignalSemanticDecision{
		accepted:       true
		class:          semantic_class
		reason:         'explicit_evidence_proves_affordance_through_behavior_or_state_delta'
		functional_cue: true
	}
}

fn ui_clone_explicit_behavior_has_proof(_ UiCloneBehaviorProbePolicy,
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
		'event_kind',
		'file_operation',
		'live_kind',
		'observed_delta',
		'opened_file',
		'probe_receipt',
		'project_id',
		'prompt_text',
		'route_target',
		'runtime_event',
		'runtime_state',
		'selection',
		'state_after',
		'submit_id',
		'text_model',
		'view_container_id',
		'window_bounds',
		'workspace_root',
	] {
		if (signal.metadata[key] or { '' }).trim_space() != '' {
			return true
		}
	}
	return false
}

fn ui_clone_explicit_behavior_class(value string) string {
	clean := normalized_clone_value(value)
	if clean in ['explicit_atomic_probe', 'explicit_behavior_evidence'] {
		return clean
	}
	return 'explicit_behavior_evidence'
}

fn ui_clone_explicit_behavior_source(claim UiCloneExplicitBehaviorEvidence) string {
	if claim.source != '' {
		return claim.source
	}
	if claim.id != '' {
		return claim.id
	}
	return 'explicit_behavior_evidence'
}
