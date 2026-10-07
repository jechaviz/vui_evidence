module vui_evidence

pub enum QaExecutionMode {
	audit
	repair
}

pub enum QaStepEffect {
	read_only
	writes_files
	launches_window
	activates_window
	uses_network
}

pub struct QaExecutionPolicy {
pub:
	mode                  QaExecutionMode = .audit
	requested_background  bool            = true
	target_was_foreground bool
	no_activate           bool = true
	allow_network         bool = true
}

pub struct QaStep {
pub:
	name    string
	command string
	effects []QaStepEffect
}

pub struct QaStepDecision {
pub:
	name       string
	command    string
	allowed    bool
	background bool
	reason     string
}

pub fn qa_mode_from_text(value string) QaExecutionMode {
	return match value.trim_space().to_lower() {
		'repair', 'fix', 'write', 'mutate' { .repair }
		else { .audit }
	}
}

pub fn decide_qa_step(policy QaExecutionPolicy, step QaStep) QaStepDecision {
	effects := normalized_effects(step.effects)
	if has_effect(effects, .writes_files) && policy.mode != .repair {
		return qa_decision(step, false, true, 'writes_blocked_in_audit_mode')
	}
	if has_effect(effects, .uses_network) && !policy.allow_network {
		return qa_decision(step, false, true, 'network_blocked')
	}
	if has_effect(effects, .launches_window) || has_effect(effects, .activates_window) {
		capture := decide_window_capture(WindowCapturePolicy{
			requested_background_mode: policy.requested_background
			target_was_foreground:     policy.target_was_foreground
			no_activate:               policy.no_activate
		})
		if capture.background_mode {
			return qa_decision(step, false, true, 'foreground_blocked:${capture.reason}')
		}
		return qa_decision(step, true, false, 'foreground_allowed:${capture.reason}')
	}
	return qa_decision(step, true, policy.requested_background, 'allowed')
}

pub fn allowed_qa_steps(policy QaExecutionPolicy, steps []QaStep) []QaStepDecision {
	mut decisions := []QaStepDecision{}
	for step in steps {
		decision := decide_qa_step(policy, step)
		if decision.allowed {
			decisions << decision
		}
	}
	return decisions
}

pub fn qa_effects_label(effects []QaStepEffect) string {
	normalized := normalized_effects(effects)
	mut labels := []string{}
	for effect in normalized {
		labels << match effect {
			.read_only { 'read_only' }
			.writes_files { 'writes_files' }
			.launches_window { 'launches_window' }
			.activates_window { 'activates_window' }
			.uses_network { 'uses_network' }
		}
	}
	return labels.join(',')
}

fn qa_decision(step QaStep, allowed bool, background bool, reason string) QaStepDecision {
	return QaStepDecision{
		name:       step.name
		command:    step.command
		allowed:    allowed
		background: background
		reason:     reason
	}
}

fn normalized_effects(effects []QaStepEffect) []QaStepEffect {
	if effects.len == 0 {
		return [.read_only]
	}
	return effects
}

fn has_effect(effects []QaStepEffect, needle QaStepEffect) bool {
	for effect in effects {
		if effect == needle {
			return true
		}
	}
	return false
}
